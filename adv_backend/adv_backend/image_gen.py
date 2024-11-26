import requests
import base64
from dotenv import load_dotenv
import os

load_dotenv()

engine_id = "stable-diffusion-v1-6"
api_host = os.getenv('API_HOST', 'https://api.stability.ai')
api_key = os.getenv('STABILITY_KEY')


if api_key is None:
    raise Exception("Missing Stability API key.")

def img_gen(prompt, turn):
    response = requests.post(
        f"{api_host}/v1/generation/{engine_id}/text-to-image",
        headers={
            "Content-Type": "application/json",
            "Accept": "application/json",
            "Authorization": f"Bearer {api_key}"
        },
        json={
            "text_prompts": [
                {
                    "text": prompt
                }
            ],
            "cfg_scale": 7,
            "height": 1024,
            "width": 1024,
            "samples": 1,
            "steps": 30,
        },
    )

    
    if response.status_code != 200:
        raise Exception("Non-200 response: " + str(response.text))

    data = response.json()
    
    for i, image in enumerate(data["artifacts"]):
        with open(f"./v1_txt2img_{turn}_{i}.png".format(turn = turn), "wb") as f:
            f.write(base64.b64decode(image["base64"]))
