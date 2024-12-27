from fastapi import FastAPI, HTTPException, APIRouter
from pydantic import BaseModel
from my_fastapi_app.src.story_manager import get_backstory, StoryManager, SelectedStory, BackStories
from my_fastapi_app.src.story_gen import get_system_prompt, generate_story
import uuid
import logging
import json

app = FastAPI()
router = APIRouter()

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

class StoryResponse(BaseModel):
    title: str
    description: str
    goal: str

@router.get("/story/selected", response_model=StoryResponse)
async def get_selected_story():
    story_manager = StoryManager()
    selected_story = story_manager.get_selected_backstory()
    
    if not selected_story:
        raise HTTPException(status_code=404, detail="Failed to get story selection")
        
    return StoryResponse(
        title=selected_story.title,
        description=selected_story.description,
        goal=selected_story.goal
    )

@router.get("/story/backstories", response_model=BackStories)
async def get_backstories():
    story_manager = StoryManager()
    backstories = story_manager.get_backstories()
    
    if not backstories:
        raise HTTPException(status_code=404, detail="Failed to generate backstories")
        
    return backstories

# In-memory session storage
sessions = {}