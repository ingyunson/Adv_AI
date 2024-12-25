from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from story_manager import get_backstory
from story_gen import get_system_prompt, generate_story  # Correct imports
import uuid
import logging

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
        return {"error": "Failed to generate or select backstory."}
    return {"selected_story": selected_story}

@app.post("/start-story/")
def start_story_endpoint(story_input: StoryInput, max_turns: int = 10):
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
    
    if session["current_turn"] >= session["max_turns"]:
        raise HTTPException(status_code=400, detail="Story has already concluded")
    
    session["last_choice"] = {
        "description": user_choice.choice,
        "outcome": user_choice.outcome
    }
    user_message = {
        "role": "user",
        "content": user_choice.choice
    }
    session["message"].append(user_message)
    
    is_final_turn = session["current_turn"] == session["max_turns"] - 1
    response = generate_story(session["message"], is_final_turn, session["last_choice"])
    
    session["current_turn"] += 1
    
    session["story"] += "\n" + response['story']
    session["choices"] = response.get('choices', [])
    
    return {
        "current_turn": session["current_turn"],
        "story": session["story"],
        "choices": session["choices"]
    }