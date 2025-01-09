import requests
import base64
from dotenv import load_dotenv
import os
import logging
from firebase_admin import storage

load_dotenv()

# Load configuration from environment variables
ENGINE_ID = os.getenv("ENGINE_ID", "stable-diffusion-v1-6")
API_HOST = os.getenv("API_HOST", "https://api.stability.ai")
API_KEY = os.getenv("STABILITY_KEY")

logger = logging.getLogger(__name__)

# Ensure the API key is present
if not API_KEY:
    raise EnvironmentError("Missing Stability API key. Please set STABILITY_KEY in your environment variables.")

def generate_image(prompt, turn, session_id, engine_id=ENGINE_ID, cfg_scale=7, height=512, width=512, samples=1, steps=30):
    """
    Generate an image using Stability AI's text-to-image API.
    
    Args:
        prompt (str): The text prompt for generating the image.
        turn (int): The turn or iteration number for naming the output file.
        session_id (str): The user's session ID, used as the storage folder name.
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
        return save_images(data, turn, session_id)
    except requests.exceptions.RequestException as e:
        raise RuntimeError(f"Request to Stability API failed: {e}")
    except KeyError as e:
        raise RuntimeError(f"Unexpected API response structure: missing key {e}")
    except Exception as e:
        raise RuntimeError(f"An error occurred: {e}")

def save_images(data, turn, session_id):
    filenames = []
    bucket = storage.bucket('prj-adv-ai.firebasestorage.app')  # Get default bucket from initialized app

    for i, artifact in enumerate(data.get("artifacts", [])):
        try:
            storage_path = f"images/{session_id}/turn_{turn}"
            if len(data["artifacts"]) > 1:
                storage_path += f"_sample{i}"
            storage_path += ".png"

            blob = bucket.blob(storage_path)
            img_data = base64.b64decode(artifact["base64"])
            blob.upload_from_string(img_data, content_type="image/png")
            
            # Make the blob public and get the public URL
            blob.make_public()
            # Construct the download URL with the token
            download_url = f"{blob.public_url}?alt=media"
            filenames.append(download_url)
            logger.info(f"Image saved at: {download_url}")

        except Exception as e:
            logger.error(f"Error saving image: {e}")
            continue

    return filenames
