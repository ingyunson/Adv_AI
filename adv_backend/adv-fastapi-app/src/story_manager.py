import json
import os
from typing import Optional
from pydantic import BaseModel, Field
from dotenv import load_dotenv
import openai
import logging
from firebase_init import db  # Import the initialized Firestore client

class Story(BaseModel):
    title: str = Field(description="The title of the backstory.")
    description: str = Field(description="A detailed description of the backstory.")
    goal: str = Field(description="What this story is about.")

class BackStories(BaseModel):
    stories: list[Story]

def get_backstory() -> Optional[BackStories]:
    """Generate backstories and let user select one"""
    try:
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
        stories_data = json.loads(completion.choices[0].message.content)['stories']
        
        return stories_data
    except Exception as e:
        logger.error(f"Error generating backstories: {e}")
        return None