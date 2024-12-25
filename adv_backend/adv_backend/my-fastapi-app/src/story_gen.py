from pydantic import BaseModel, Field
from dotenv import load_dotenv
import json
import openai
import os
import logging

load_dotenv()

client = openai.OpenAI(
    api_key=os.getenv('OPENAI_API_KEY')
)

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class StoryChoice(BaseModel):
    description: str = Field(description="Description of the choice.")
    outcome: str = Field(description="The result of choosing this option.")

class GenStory(BaseModel):
    story: str = Field(description="The narrative describing the events of this turn.")
    img: str = Field(description="Stable-Diffusion 1.5 prompt to describe the story")
    choices: list[StoryChoice] = Field(description="List of choices for this turn")

class FinalStory(BaseModel):
    story: str = Field(description="The final narrative concluding the story.")
    img: str = Field(description="Stable-Diffusion 1.5 prompt to describe the final scene")
    choices: list[StoryChoice] = Field(description="Empty list for the final turn")

def get_system_prompt(selected_story: dict, max_turns: int) -> str:
    """Generate system prompt with selected story background"""
    return f'''You're a storyteller creating an Interactive Adventure. For each turn, you must provide exactly two choices unless it's the final turn.

[BackgroundConditions]
- title: {selected_story['title']}
- description: {selected_story['description']}
- goal: {selected_story['goal']}

[Conditions]
- For turns 1 through {max_turns - 2}:
  * MUST provide exactly two choices every time
  * Each choice must have both description and outcome
  * Story segments limited to 500 characters
  * Choices should meaningfully impact the story

- For turn {max_turns - 1} (Penultimate turn):
  * Must set up the finale with two dramatically different choices
  * Each choice should lead to a distinct ending scenario
  * Make clear how each choice will impact the final outcome
  * Choices should represent meaningful story branches

- For turn {max_turns} (Final turn):
  * MUST directly continue from the choice made in turn {max_turns - 1}
  * Begin by showing the immediate result of the last choice
  * Provide a complete resolution (up to 1000 characters) that:
    - Shows the consequences of the final choice
    - Wraps up all major plot threads
    - Reveals the ultimate fate of all main characters
    - Concludes the quest
  * The ending must feel like a natural continuation of the last choice

[Storytelling Guidelines]
- Turn {max_turns - 1} choices should create clear story branches
- Turn {max_turns} must directly follow from turn {max_turns - 1}'s selected choice
- The conclusion should acknowledge key decisions from earlier turns
- Each possible ending should feel distinct and earned
- Maintain narrative continuity throughout all turns'''

def generate_story(message, is_final_turn=False, last_choice=None):
    logger.info("Generating story with message: %s", message)
    # Add the last choice context for the final turn
    if is_final_turn and last_choice:
        context_message = {
            "role": "system",
            "content": (
                f"Continue and conclude the story based on the player's last choice: {last_choice['description']}. "
                f"The outcome of this choice was: {last_choice['outcome']}. This is the final turn. "
                "As per the storytelling guidelines, you should provide a complete resolution (up to 1000 characters) that "
                "shows the consequences of the final choice, wraps up all major plot threads, reveals the ultimate fate of all main characters, "
                "and concludes the quest for the Heart of Eldoria. The ending must feel like a natural continuation of the last choice."
            )
        }
        message.append(context_message)

    model_class = FinalStory if is_final_turn else GenStory
    completion = client.beta.chat.completions.parse(
        model="gpt-4o-mini",
        messages=message,
        response_format=model_class,
    )
    
    logger.info("Story generated: %s", completion.choices[0].message.content)
    return json.loads(completion.choices[0].message.content)