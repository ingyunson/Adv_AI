from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from typing import Dict
from .story_manager import get_selected_backstory
from .story_gen import main_story_loop, get_system_prompt
from .api.story_routes import router as story_router

app = FastAPI()
app.include_router(story_router, prefix="/api")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {"message": "Adventure Game API"}

@app.get("/story")
async def get_story() -> Dict:
    selected_story = get_selected_backstory()
    if not selected_story:
        return {"error": "Failed to generate or select backstory"}
    
    # Set up game parameters
    max_turns = 10
    system_prompt = get_system_prompt(selected_story, max_turns)
    
    return {
        "story": selected_story,
        "system_prompt": system_prompt,
        "max_turns": max_turns
    }

def main():
    # Get selected backstory
    selected_story = get_selected_backstory()
    if not selected_story:
        print("Failed to generate or select backstory. Exiting...")
        return
    
    # Set up the game parameters
    max_turns = 10
    
    # Generate the system prompt with the selected story
    system_prompt = get_system_prompt(selected_story, max_turns)
    
    # Initialize the message list with the system prompt
    message = [
        {"role": "system", "content": system_prompt}
    ]
    
    # Start the main story loop
    main_story_loop(message, max_turns)

if __name__ == "__main__":
    main()