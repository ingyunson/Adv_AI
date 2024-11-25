from fastapi import FastAPI
from pydantic import BaseModel

app = FastAPI()

class AdventureRequest(BaseModel):
    user_id: int
    prompt: str

@app.post("/generate_adventure")
async def generate_adventure(request: AdventureRequest):
    # Placeholder function for GPT-4 integration
    response = "GPT-4 generated response"  # Call GPT-4 API here
    return {"response": response}
