# My FastAPI Story Generation Application

This project is a FastAPI application that facilitates story generation through a structured backstory and main story loop. 

## Project Structure

```
my-fastapi-app
├── src
│   ├── main.py            # Entry point of the FastAPI application
│   ├── story_manager.py   # Contains logic for retrieving or generating backstories
│   ├── story_gen.py       # Handles main story logic and system prompt generation
│   └── types
│       └── index.py       # Custom types and interfaces (currently empty)
├── requirements.txt       # Lists project dependencies
└── README.md              # Documentation for the project
```

## Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   cd my-fastapi-app
   ```

2. Install the required dependencies:
   ```
   pip install -r requirements.txt
   ```

## Usage

To run the FastAPI application, execute the following command:

```
uvicorn src.main:app --reload
```

This will start the server at `http://127.0.0.1:8000`.

## API Endpoint

- **POST /generate-story**: Calls the `main()` function to initiate the story generation process.

## Contributing

Feel free to submit issues or pull requests for improvements or bug fixes. 

## License

This project is licensed under the MIT License.