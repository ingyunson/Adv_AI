from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from story_manager import get_backstory  # Use relative import
from story_gen import get_system_prompt, generate_story  # Use relative import
import logging
import uuid
import json  # Add this import statement
from firebase_init import db  # Import the initialized Firestore client

app = FastAPI()

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class StoryInput(BaseModel):
    title: str
    description: str
    goal: str

class UserChoice(BaseModel):
    session_id: str
    choice: str
    outcome: str  # Add outcome field

# In-memory session storage
sessions = {}

@app.post("/get-backstory/")
def get_backstory_endpoint():
    selected_story = get_backstory()
    if not selected_story:
        raise HTTPException(status_code=404, detail="No backstory found")
    return {"selected_story": selected_story}

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
    
    return {
        "session_id": session_id,
        "story": response['story'],
        "choices": response['choices']
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
    
    return {
        "story": response['story'],
        "choices": response['choices'],
        "is_final": is_final_turn
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