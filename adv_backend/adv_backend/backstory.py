
from pydantic import BaseModel, Field
from dotenv import load_dotenv
import json
import openai
import os

load_dotenv()

client = openai.OpenAI(
    api_key = os.getenv('OPENAI_API_KEY')
)


message = [
    {"role": "system",
     "content": "Imagine you're entering a world of thrilling adventures! Create four backstories to start your journey."}
]


class BackStories(BaseModel):
    class Story(BaseModel):
        title: str = Field(description="The title of the backstory.")
        description: str = Field(description="A detailed description of the backstory.")
        goal: str = Field(description="What this story is about.")
    
    stories: list[Story]


def get_backstory(message):
    completion = client.beta.chat.completions.parse(
        model = "gpt-4o-mini",
        messages = message,
        response_format = BackStories,
        )
    
    return completion.choices[0].message.content
    

response_pydantic = json.loads(get_backstory(message))


first_title = response_pydantic["stories"][0]["title"]
first_desc = response_pydantic["stories"][0]["description"]
first_goal = response_pydantic["stories"][0]["goal"]

second_title = response_pydantic["stories"][1]["title"]
second_desc = response_pydantic["stories"][1]["description"]
second_goal = response_pydantic["stories"][1]["goal"]

third_title = response_pydantic["stories"][2]["title"]
third_desc = response_pydantic["stories"][2]["description"]
third_goal = response_pydantic["stories"][2]["goal"]

fourth_title = response_pydantic["stories"][3]["title"]
fourth_desc = response_pydantic["stories"][3]["description"]
fourth_goal = response_pydantic["stories"][3]["goal"]

print("first")
print(first_title)
print(first_desc)
print(first_goal)

print("second")
print(second_title)
print(second_desc)
print(second_goal)

print("third")
print(third_title)
print(third_desc)
print(third_goal)

print("fourth")
print(fourth_title)
print(fourth_desc)
print(fourth_goal)
