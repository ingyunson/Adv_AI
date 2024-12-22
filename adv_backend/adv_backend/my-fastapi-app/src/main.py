from fastapi import FastAPI
from pydantic import BaseModel
from story_manager import get_backstory
from story_gen import main_story_loop, get_system_prompt

app = FastAPI()

class StoryInput(BaseModel):
    title: str
    description: str
    goal: str

@app.post("/get-backstory/")
def get_backstory_endpoint():
    selected_story = get_backstory()
    if not selected_story:
        return {"error": "Failed to generate or select backstory."}
    return {"selected_story": selected_story}

@app.post("/main-story-loop/")
def main_story_loop_endpoint(story_input: StoryInput, max_turns: int = 10):
    selected_story = {
        "title": story_input.title,
        "description": story_input.description,
        "goal": story_input.goal
    }
    system_prompt = get_system_prompt(selected_story, max_turns)
    
    message = [
        {"role": "system", "content": system_prompt}
    ]
    
    main_story_loop(message, max_turns)
    return {"message": "Story generation completed."}