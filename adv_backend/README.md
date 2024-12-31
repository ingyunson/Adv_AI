# Advanced FastAPI Story Generation Application

This project is a [FastAPI](https://fastapi.tiangolo.com/) application that facilitates story generation through a structured backstory and main story loop.

## Project Structure

```
adv-fastapi-app/
├── adv-fastapi-app/
│   ├── __init__.py
│   ├── [README.md](adv-fastapi-app/README.md)
│   ├── [requirements.txt](adv-fastapi-app/requirements.txt)
│   └── src/
│       ├── __init__.py
│       ├── credentials/
│       │   └── [firebase_credentials.json](adv-fastapi-app/src/credentials/firebase_credentials.json)
│       ├── custom_types/
│       │   ├── __init__.py
│       │   ├── __pycache__/
│       │   └── [index.py](adv-fastapi-app/src/custom_types/index.py)
│       ├── [firebase_init.py](adv-fastapi-app/src/firebase_init.py)
│       ├── [main.py](adv-fastapi-app/src/main.py)
│       ├── [story_gen.py](adv-fastapi-app/src/story_gen.py)
│       └── [story_manager.py](adv-fastapi-app/src/story_manager.py)
```

## Installation

1. Clone the repository:

    ```sh
    git clone <repository-url>
    cd adv-fastapi-app
    ```

2. Install the required dependencies:

    ```sh
    pip install -r [requirements.txt](adv-fastapi-app/requirements.txt)
    ```

## Usage

To run the FastAPI application, execute the following command:

```sh
uvicorn [src.main:app](adv-fastapi-app/src/main.py:app) --reload
```

This will start the server at `http://127.0.0.1:8000`.

## API Endpoints

- **POST /get-backstory**: Generates and retrieves a backstory.
  
  Defined in 

story_manager.py

.

- **POST /start-story**: Starts the story generation process.
  
  Defined in 

main.py

.

- **POST /main-story-loop**: Continues the story based on user choices.
  
  Defined in 

main.py

.

## Contributing

Feel free to submit issues or pull requests for improvements or bug fixes.

## License

This project is licensed under the MIT License.