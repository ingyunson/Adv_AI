from story_manager import get_selected_backstory
from story_gen import main_story_loop, get_system_prompt

def main():
    # Get selected backstory
    selected_story = get_selected_backstory()
    if not selected_story:
        print("Failed to generate or select backstory. Exiting...")
        return
    
    # Set up the game parameters
    max_turns = 10
    
    # Generate the system prompt with the selected story
    system_prompt = get_system_prompt(selected_story, max_turns)
    
    # Initialize the message list with the system prompt
    message = [
        {"role": "system", "content": system_prompt}
    ]
    
    # Start the main story loop
    main_story_loop(message, max_turns)

if __name__ == "__main__":
    main()