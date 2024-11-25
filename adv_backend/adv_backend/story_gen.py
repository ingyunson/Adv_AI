from pydantic import BaseModel, Field
from dotenv import load_dotenv
import json
import openai
import os

import image_gen

load_dotenv()

client = openai.OpenAI(
    api_key = os.getenv('OPENAI_API_KEY')
)

turn = 0

message = [
    {"role": "system",
     "content": '''You're a storyteller. 
     Create Interactive Adventure content based on the information you provide. 
     Use background information and conditions
     
    [BackgroundConditions]
    - title: The Lost City of Eldoria
    - description: In the dense jungles of Eldoria, a once-great civilization lies hidden beneath the vines and undergrowth. Legends speak of a powerful artifact, the Heart of Eldoria, said to grant immense power to those who possess it. The last known explorer to seek it was never heard from again. Motivated by the thrill of discovery and the promise of wealth, a skilled archaeologist teams up with a rogue thief to uncover the secrets of the lost city, battling nature and rival treasure hunters along the way. Can they survive the dangers that guard the Heart?
    - goal:To discover the Heart of Eldoria and unlock its ancient secrets.

    [Conditions]
    - Turns must not exceed 10 turns.
    - Description is no more than 500 characters
    - Create the next story according to the user's choice.
    - Create a Dall-E 3 prompt to describe the story.
    - Refer to the background and previous story.
    - At the end of each turn, offer two choices
    - At the end of the last turn, don't offer a choice, end the story'''}
]


class GenStory(BaseModel):
    story: str = Field(description="The narrative describing the events of this turn.")

    class Choice(BaseModel):
        description: str = Field(description="Description of the choice.")
        outcome: str = Field(description="The result of choosing this option.")
    
    choices: list[Choice]

    img : str = Field(description="Dall-E 3 prompt of describe the story")


def generate_story(message):
    completion = client.beta.chat.completions.parse(
        model = "gpt-4o-mini",
        messages = message,
        response_format = GenStory,
        )
    
    return completion.choices[0].message.content


def main_story(message, turn):
    response_pydantic = json.loads(generate_story(message))

    story = response_pydantic['story']
    choice_1_desc = response_pydantic['choices'][0]['description']
    choice_1_outcome = response_pydantic['choices'][0]['outcome']
    choice_2_desc = response_pydantic['choices'][1]['description']
    choice_2_outcome = response_pydantic['choices'][1]['outcome']
    # img_prompt = response_pydantic['img']

    # img_url = image_gen.generate_image(img_prompt)

    gpt_respond = {
        "role": "assistant",
        "content": '''story: {story},
            first choice: {choice_1_desc},
            first choice outcome: {choice_1_outcome},
            second choice: {choice_2_desc},
            second choice outcome: {choice_2_outcome}'''
                .format(
                story = story,
                choice_1_desc = choice_1_desc,
                choice_1_outcome = choice_1_outcome,
                choice_2_desc = choice_2_desc,
                choice_2_outcome = choice_2_outcome)
    }

    print('##################')
    # print(img_url)
    print("Turn #{turn}".format(turn = turn + 1))
    print("Description\n{story}".format(story = story))
    print("Select #1. {choice_1}".format(choice_1 = choice_1_desc))
    print("Select #2. {choice_2}".format(choice_2 = choice_2_desc))
    print('##################')

    message.append(gpt_respond)

    select = input("What is your select? 1 or 2?")
    result = []

    if select == '1' :
        result.append(turn + 1)
        result.append(choice_1_desc)
        result.append(choice_1_outcome)
    elif select == '2':
        result.append(turn + 1)
        result.append(choice_2_desc)
        result.append(choice_2_outcome)
    else:
        print("Select Agian. select 1 or 2")


    user_choice = {
        "role": "user",
        "content": '''turn: {turn},
        choice: {desc},
        outcome: {outcome}'''.format(
            turn = result[0],
            desc = result[1],
            outcome = result[2])
    }
    message.append(user_choice)
    
    print('##################')
    print('You select "{choice}"'.format(choice = result[1]))


for i in range(11):
    main_story(message, i)
    print("i is {i}".format(i = i))
    


# print(json.loads(generate_story(message)))