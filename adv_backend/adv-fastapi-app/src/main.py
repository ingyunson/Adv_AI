from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from story_manager import get_backstory  # Use relative import
from story_gen import get_system_prompt, generate_story  # Use relative import
import logging
import uuid
import json  # Add this import statement
from firebase_init import db  # Import the initialized Firestore client
from google.cloud import firestore

app = FastAPI()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class BackstoryRequest(BaseModel):
    user_id: str

class StoryInput(BaseModel):
    title: str
    description: str
    goal: str
    user_id: str  # Added user_id

class UserChoice(BaseModel):
    session_id: str
    choice: str
    outcome: str
    user_id: str  # Added user_id

# In-memory session storage
sessions = {}

@app.post("/get-backstory/")
def get_backstory_endpoint(request: BackstoryRequest):
    selected_story = get_backstory()
    if not selected_story:
        raise HTTPException(status_code=500, detail="Error generating backstories")
    # Store in 'StorySessions'
    doc_ref = db.collection("StorySessions").add({
        # Directly store the list of dicts instead of calling s.dict()
        "stories": selected_story,
        "created_at": firestore.SERVER_TIMESTAMP,
        "created_by": request.user_id if request.user_id else "test"
    })
    doc_id = doc_ref[1].id
    return {"firestore_key": doc_id, 
            "user_id": request.user_id}

@app.post("/start-story/")
def start_story_endpoint(story_input: StoryInput, max_turns: int = 5):
    logger.info("Received start-story request")
    session_id = str(uuid.uuid4())
    selected_story = {
        "title": story_input.title,
        "description": story_input.description,
        "goal": story_input.goal
    }
    system_prompt = get_system_prompt(selected_story, max_turns)
    
    message = [
        {"role": "system", "content": system_prompt}
    ]
    
    logger.info("Generating story")
    response = generate_story(message)
    logger.info("Story generated")
    
    sessions[session_id] = {
        "message": message,
        "max_turns": max_turns,
        "current_turn": 1,
        "last_choice": None,
        "story": response['story'],
        "choices": response['choices']
    }
    
    # Store first turn in 'GeneratedStory.turn_1'
    doc_ref = db.collection("GeneratedStory").document(session_id)
    doc_ref.set({
        "turn_1": response,
        "created_at": firestore.SERVER_TIMESTAMP,
        "created_by": story_input.user_id if story_input.user_id else "test"
    })
    
    return {
        "session_id": session_id,
        "firestore_key": doc_ref.id,
        "current_turn": 1  # Same as session_id
    }

@app.post("/main-story-loop/")
def main_story_loop_endpoint(user_choice: UserChoice):
    session = sessions.get(user_choice.session_id)
    if not session:
        raise HTTPException(status_code=404, detail="Session not found")
    
    update_session_with_choice(session, user_choice)
    
    # Update final turn logic - should trigger on turn 4
    is_final_turn = session["current_turn"] == (session["max_turns"] - 1)
    
    logger.info(f"Current turn: {session['current_turn']}, Is final turn: {is_final_turn}")
    
    response = generate_story(
        session["message"],
        is_final_turn=is_final_turn,
        last_choice=session["last_choice"] if is_final_turn else None
    )
    
    update_session_with_response(session, response, user_choice)
    
    # Example turn increment
    turn_num = session["current_turn"] + 1
    
    # After generating 'response'
    doc_ref = db.collection("GeneratedStory").document(user_choice.session_id)
    doc_ref.update({
        f"turn_{turn_num}": response,
        "updated_at": firestore.SERVER_TIMESTAMP,
        "created_by": user_choice.user_id if user_choice.user_id else "test"
    })
    
    return {
        "session_id": user_choice.session_id,
        "firestore_key": doc_ref.id
    }

def update_session_with_choice(session, user_choice):
    # Always update last_choice
    session["last_choice"] = {
        "description": user_choice.choice,
        "outcome": user_choice.outcome
    }
    
    user_message = {
        "role": "user",
        "content": json.dumps({
            "choice": user_choice.choice,
            "outcome": user_choice.outcome
        })
    }
    session["message"].append(user_message)

def update_session_with_response(session, response, user_choice):
    new_story_message = {
        "role": "assistant",
        "content": response['story']
    }
    session["message"].append(new_story_message)
    
    session["story"] = response['story']
    session["choices"] = response.get('choices', [])
    session["last_choice"] = {
        "description": user_choice.choice,
        "outcome": user_choice.outcome
    }
    
    # Increment turn AFTER processing
    session["current_turn"] += 1

# Example: Adding a new user
def add_user(user_id, name, email):
    user_ref = db.collection('Users').document(user_id)
    user_ref.set({
        'name': name,
        'email': email,
        'created_at': firestore.SERVER_TIMESTAMP
    })