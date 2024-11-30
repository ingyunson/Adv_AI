from pydantic import BaseModel, Field
from dotenv import load_dotenv
import openai
import os
import json
from dataclasses import dataclass
from typing import Dict, Any, Optional

@dataclass
class SelectedStory:
    title: str
    description: str
    goal: str

class Story(BaseModel):
    title: str = Field(description="The title of the backstory.")
    description: str = Field(description="A detailed description of the backstory.")
    goal: str = Field(description="What this story is about.")

class BackStories(BaseModel):
    stories: list[Story]

def get_selected_backstory() -> Optional[SelectedStory]:
    """Generate backstories and let user select one"""
    try:
        load_dotenv()
        client = openai.OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        
        system_message = {
            "role": "system",
            "content": "Imagine you're entering a world of thrilling adventures! Create four backstories to start your journey."
        }
        
        # Generate backstories
        completion = client.beta.chat.completions.parse(
            model="gpt-4o-mini",
            messages=[system_message],
            response_format=BackStories,
        )
        stories_data = json.loads(completion.choices[0].message.content)
        
        # Display stories
        for i, story in enumerate(stories_data["stories"], 1):
            print(f"\nStory {i}:")
            print(f"Title: {story['title']}")
            print(f"Description: {story['description']}")
            print(f"Goal: {story['goal']}")
            print("-" * 50)
        
        # Get user selection
        while True:
            try:
                choice = int(input("Select a story (1-4): "))
                if 1 <= choice <= 4:
                    selected = stories_data["stories"][choice - 1]
                    return SelectedStory(
                        title=selected["title"],
                        description=selected["description"],
                        goal=selected["goal"]
                    )
                print("Please select a number between 1 and 4.")
            except ValueError:
                print("Invalid input. Please enter a number between 1 and 4.")
                
    except Exception as e:
        print(f"Error generating backstories: {e}")
        return None