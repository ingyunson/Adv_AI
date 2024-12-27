# Advanced FastAPI Story Generation Application

This project is a FastAPI application that facilitates story generation through a structured backstory and main story loop.

## Project Structure

```
adv-fastapi-app
├── src
│   ├── main.py            # Entry point of the FastAPI application
│   ├── story_manager.py   # Contains logic for retrieving or generating backstories
│   ├── story_gen.py       # Handles main story logic and system prompt generation
│   └── custom_types
│       └── index.py       # Custom types and interfaces
├── requirements.txt       # Lists project dependencies
└── README.md              # Documentation for the project
```

## Installation

1. Clone the repository:
   ```sh
   git clone <repository-url>
   cd adv-fastapi-app
   ```

2. Install the required dependencies:
   ```sh
   pip install -r requirements.txt
   ```

## Usage

To run the FastAPI application, execute the following command:

```sh
uvicorn src.main:app --reload
```

This will start the server at `http://127.0.0.1:8000`.

## API Endpoints

- **POST /get-backstory**: Generates and retrieves a backstory.
- **POST /start-story**: Starts the story generation process.
- **POST /main-story-loop**: Continues the story based on user choices.

## Contributing

Feel free to submit issues or pull requests for improvements or bug fixes.

## License

This project is licensed under the MIT License.