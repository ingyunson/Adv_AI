import json
import os
from typing import Optional
from pydantic import BaseModel, Field
from dotenv import load_dotenv
import openai

class Story(BaseModel):
    title: str = Field(description="The title of the backstory.")
    description: str = Field(description="A detailed description of the backstory.")
    goal: str = Field(description="What this story is about.")

class BackStories(BaseModel):
    stories: List[Story]

class StoryManager:
    def get_backstories(self) -> Optional[BackStories]:
        """Generate four backstories"""
        try:
            load_dotenv()
            api_key = os.getenv('OPENAI_API_KEY')
            if not api_key:
                raise ValueError("OPENAI_API_KEY environment variable not set")
            
            openai.api_key = api_key
            
            system_message = {
                "role": "system",
                "content": "Imagine you're entering a world of thrilling adventures! Create four backstories to start your journey."
            }
            
            # Generate backstories
            completion = openai.ChatCompletion.create(
                model="gpt-4",
                messages=[system_message]
            )
            stories_data = json.loads(completion.choices[0].message['content'])
            
            return BackStories(stories=stories_data["stories"])
                
        except Exception as e:
            print(f"Error generating backstories: {e}")
            return None

    def get_selected_backstory(self) -> Optional[SelectedStory]:
        """Generate backstories and let user select one"""
        backstories = self.get_backstories()
        if not backstories:
            return None
        
        # For simplicity, return the first story
        selected = backstories.stories[0]
        return SelectedStory(
            title=selected.title,
            description=selected.description,
            goal=selected.goal
        )

def get_selected_backstory() -> Optional[BackStories]:
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
        stories_data = json.loads(completion.choices[0].message.content)['stories']
        
        return stories_data
    except Exception as e:
        print(f"Error generating backstories: {e}")
        return None
