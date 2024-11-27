from pydantic import BaseModel, Field
from dotenv import load_dotenv
import json
import openai
import os
from image_gen import generate_image  # Importing the function

load_dotenv()

client = openai.OpenAI(
    api_key=os.getenv('OPENAI_API_KEY')
)

class GenStory(BaseModel):
    story: str = Field(description="The narrative describing the events of this turn.")

    class Choice(BaseModel):
        description: str = Field(description="Description of the choice.")
        outcome: str = Field(description="The result of choosing this option.")

    choices: list[Choice]
    img: str = Field(description="Dall-E 3 prompt to describe the story")

def generate_story(message):
    completion = client.beta.chat.completions.parse(
        model="gpt-4o-mini",
        messages=message,
        response_format=GenStory,
    )
    return json.loads(completion.choices[0].message.content)

def display_turn_info(turn, story, choices):
    print(f'##################\nTurn #{turn + 1}')
    print(f"Description\n{story}")
    for idx, choice in enumerate(choices, start=1):
        print(f"Select #{idx}. {choice['description']}")
    print('##################')

def process_user_input(choices):
    while True:
        try:
            selection = int(input("What is your choice? 1 or 2: "))
            if selection in [1, 2]:
                return choices[selection - 1]
        except ValueError:
            pass
        print("Invalid input. Please select 1 or 2.")

def main_story_loop(message, max_turns):
    for turn in range(max_turns):
        response = generate_story(message)
        story = response['story']
        choices = response['choices']
        img_prompt = response['img']
        
        # Generate and save the image
        try:
            filenames = generate_image(prompt=img_prompt, turn=turn)
            print(f"Images generated: {filenames}")
        except RuntimeError as e:
            print(f"Image generation failed: {e}")

        # Display the turn information
        display_turn_info(turn, story, choices)
        
        # Get the user's choice
        user_choice = process_user_input(choices)
        
        # Prepare assistant and user messages
        gpt_respond = {
            "role": "assistant",
            "content": json.dumps({
                "story": story,
                "choices": choices
            }, indent=4)
        }
        message.append(gpt_respond)
        
        user_message = {
            "role": "user",
            "content": json.dumps({
                "turn": turn + 1,
                "choice": user_choice['description'],
                "outcome": user_choice['outcome']
            }, indent=4)
        }
        message.append(user_message)
        
        print(f'\nYou selected "{user_choice["description"]}"\n')
        
        # End the story if it is the last turn
        if turn == max_turns - 1:
            print("The story ends here. Thank you for playing!")

    # Print the final message after all turns are over
    print("All stories are over.")

if __name__ == "__main__":
    max_turns = 10  # Set the maximum number of turns
    message = [
        {"role": "system",
         "content": '''You're a storyteller. 
         Create Interactive Adventure content based on the information you provide. 
         Use background information and conditions

        [BackgroundConditions]
        - title: The Lost City of Eldoria
        - description: In the dense jungles of Eldoria, a once-great civilization lies hidden beneath the vines and undergrowth. Legends speak of a powerful artifact, the Heart of Eldoria, said to grant immense power to those who possess it. The last known explorer to seek it was never heard from again. Motivated by the thrill of discovery and the promise of wealth, a skilled archaeologist teams up with a rogue thief to uncover the secrets of the lost city, battling nature and rival treasure hunters along the way. Can they survive the dangers that guard the Heart?
        - goal: To discover the Heart of Eldoria and unlock its ancient secrets.

        [Conditions]
        - Turns must not exceed {max_turns} turns.
        - The story must end after {max_turns} turns.
        - No choices or descriptions are provided for turn {max_turns}. The game ends directly.
        - Description is no more than 500 characters
        - Create the next story according to the user's choice.
        - Create a Dall-E 3 prompt to describe the story.
        - Refer to the background and previous story.
        - At the end of each turn, offer two choices
        - At the end of the last turn, don't offer a choice, end the story'''
        }
    ]
    main_story_loop(message, max_turns)
