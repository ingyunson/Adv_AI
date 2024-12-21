from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from ..story_manager import StoryManager, SelectedStory, BackStories

router = APIRouter()

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