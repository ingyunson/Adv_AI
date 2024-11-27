import requests
import base64
from dotenv import load_dotenv
import os

load_dotenv()

# Load configuration from environment variables
ENGINE_ID = os.getenv("ENGINE_ID", "stable-diffusion-v1-6")
API_HOST = os.getenv("API_HOST", "https://api.stability.ai")
API_KEY = os.getenv("STABILITY_KEY")

# Ensure the API key is present
if not API_KEY:
    raise EnvironmentError("Missing Stability API key. Please set STABILITY_KEY in your environment variables.")

def generate_image(prompt, turn, engine_id=ENGINE_ID, cfg_scale=7, height=1024, width=1024, samples=1, steps=30):
    """
    Generate an image using Stability AI's text-to-image API.
    
    Args:
        prompt (str): The text prompt for generating the image.
        turn (int): The turn or iteration number for naming the output file.
        engine_id (str): The engine used for generation.
        cfg_scale (int): Controls the image fidelity to the prompt.
        height (int): Height of the generated image.
        width (int): Width of the generated image.
        samples (int): Number of image samples to generate.
        steps (int): Number of inference steps for image generation.
    
    Returns:
        list[str]: A list of filenames of the generated images.
    """
    url = f"{API_HOST}/v1/generation/{engine_id}/text-to-image"
    headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Authorization": f"Bearer {API_KEY}",
    }
    payload = {
        "text_prompts": [{"text": prompt}],
        "cfg_scale": cfg_scale,
        "height": height,
        "width": width,
        "samples": samples,
        "steps": steps,
    }

    try:
        response = requests.post(url, headers=headers, json=payload)
        response.raise_for_status()  # Raise HTTPError for bad responses (4xx, 5xx)
        data = response.json()
        return save_images(data, turn)
    except requests.exceptions.RequestException as e:
        raise RuntimeError(f"Request to Stability API failed: {e}")
    except KeyError as e:
        raise RuntimeError(f"Unexpected API response structure: missing key {e}")
    except Exception as e:
        raise RuntimeError(f"An error occurred: {e}")

def save_images(data, turn):
    """
    Save the generated images from the Stability AI API response.

    Args:
        data (dict): The JSON response from the API containing image artifacts.
        turn (int): The turn or iteration number for naming the output file.

    Returns:
        list[str]: A list of filenames of the saved images.
    """
    filenames = []
    for i, artifact in enumerate(data.get("artifacts", [])):
        try:
            filename = f"v1_txt2img_turn{turn}_sample{i}.png"
            with open(filename, "wb") as f:
                f.write(base64.b64decode(artifact["base64"]))
            filenames.append(filename)
        except KeyError:
            raise RuntimeError(f"Missing base64 image data in artifact {i}.")
        except Exception as e:
            raise RuntimeError(f"Failed to save image {i}: {e}")
    return filenames
