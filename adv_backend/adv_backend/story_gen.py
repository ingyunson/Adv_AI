from pydantic import BaseModel, Field
from dotenv import load_dotenv
import json
import openai
import os
from image_gen import generate_image
from story_manager import SelectedStory  # Add this import

load_dotenv()

client = openai.OpenAI(
    api_key=os.getenv('OPENAI_API_KEY')
)

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

def get_system_prompt(selected_story: SelectedStory, max_turns: int) -> str:
    """Generate system prompt with selected story background"""
    return f'''You're a storyteller creating an Interactive Adventure. For each turn, you must provide exactly two choices unless it's the final turn.

[BackgroundConditions]
- title: {selected_story.title}
- description: {selected_story.description}
- goal: {selected_story.goal}

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
        
    return json.loads(completion.choices[0].message.content)

def display_turn_info(turn, story, choices, max_turns):
    print(f'##################\nTurn #{turn + 1}')
    print(f"Description\n{story}")
    if turn < max_turns - 1 and choices:
        for idx, choice in enumerate(choices, start=1):
            print(f"Select #{idx}. {choice['description']}")
    print('##################')

def process_user_input(choices):
    if not choices or len(choices) < 2:
        raise ValueError("Invalid choices provided by the story generator")
    
    while True:
        try:
            selection = int(input("What is your choice? 1 or 2: "))
            if selection in [1, 2] and selection <= len(choices):
                return choices[selection - 1]
            print("Invalid input. Please select 1 or 2.")
        except ValueError:
            print("Invalid input. Please select 1 or 2.")

def main_story_loop(message, max_turns):
    last_choice = None
    try:
        for turn in range(max_turns):
            is_final_turn = turn == max_turns - 1
            response = generate_story(message, is_final_turn, last_choice)
            
            if not isinstance(response, dict) or 'story' not in response or 'img' not in response:
                raise ValueError(f"Invalid response format in turn {turn + 1}")
            
            story = response['story']
            img_prompt = response['img']
            choices = response.get('choices', [])
            
            '''
            try:
                filenames = generate_image(prompt=img_prompt, turn=turn)
                print(f"Images generated: {filenames}")
            except RuntimeError as e:
                print(f"Image generation failed: {e}")
            '''

            display_turn_info(turn, story, choices, max_turns)
            
            if not is_final_turn:
                if not choices or len(choices) < 2:
                    raise ValueError(f"Invalid number of choices provided in turn {turn + 1}")
                
                user_choice = process_user_input(choices)
                last_choice = user_choice  # Store the last choice for the final turn
                
                gpt_respond = {
                    "role": "assistant",
                    "content": json.dumps({
                        "story": story,
                        "choices": choices,
                        "img": img_prompt
                    }, indent=4)
                }
                user_message = {
                    "role": "user",
                    "content": json.dumps({
                        "turn": turn + 1,
                        "choice": user_choice['description'],
                        "outcome": user_choice['outcome']
                    }, indent=4)
                }
                message.append(gpt_respond)
                message.append(user_message)
                print(f'\nYou selected "{user_choice["description"]}"\n')
            else:
                gpt_respond = {
                    "role": "assistant",
                    "content": json.dumps({
                        "story": story,
                        "img": img_prompt,
                        "choices": []
                    }, indent=4)
                }
                message.append(gpt_respond)
                print("\nThe story has reached its conclusion.")

        print("Thank you for experiencing this adventure!")
        
    except Exception as e:
        print(f"\nAn error occurred: {str(e)}")
        print("The story generator encountered an issue. Please try again.")