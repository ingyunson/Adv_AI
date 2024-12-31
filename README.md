# ADV_AI Project

ADV_AI is a comprehensive application that integrates a Python-based FastAPI backend with a Flutter frontend to facilitate advanced story generation. The project leverages Firestore for its database, ensuring scalable and real-time data management. Additionally, it utilizes the GPT-4o-mini model for generative AI, enhancing the storytelling experience.

## Table of Contents

- Project Structure
- Backend
  - Installation
  - Usage
  - API Endpoints
- Frontend
  - Installation
  - Running the App
- Contributing
- License

## Project Structure

```
.
├── adv_backend/
│   ├── adv-fastapi-app/
│   │   ├── __init__.py
│   │   ├── README.md
│   │   ├── requirements.txt
│   │   └── src/
│   │       ├── main.py
│   │       ├── story_manager.py
│   │       ├── story_gen.py
│   │       ├── custom_types/
│   │       │   └── index.py
│   │       └── credentials/
│   │           └── firebase_credentials.json
│   └── README.md
├── adv_frontend/
│   ├── adv_frontend.iml
│   ├── analysis_options.yaml
│   ├── android/
│   ├── assets/
│   ├── build/
│   ├── firebase.json
│   ├── fonts/
│   ├── ios/
│   ├── lib/
│   ├── linux/
│   ├── macos/
│   ├── pubspec.lock
│   ├── pubspec.yaml
│   ├── README.md
│   ├── test/
│   └── web/
├── README.md
```

## Backend

The backend is built using **Python** and **FastAPI**, responsible for handling story generation, managing user data, and interfacing with Firestore. It utilizes the **GPT-4o-mini** model for generative AI, enabling dynamic and engaging storytelling.

### Backend Installation

1. **Clone the Repository:**

    ```sh
    git clone <repository-url>
    cd adv_backend/adv-fastapi-app
    ```

2. **Create a Virtual Environment:**

    ```sh
    python -m venv adv_env
    ```

3. **Install the Required Dependencies:**

    ```sh
    pip install -r requirements.txt
    ```

4. **Set Up Environment Variables:**

    Create a `.env` file in the `src/` directory and add the following:

    ```env
    OPENAI_API_KEY=your_openai_api_key
    STABILITY_KEY=your_stability_api_key
    FIREBASE_SERVICE_ACCOUNT=credentials/firebase_credentials.json
    ```

    Ensure that the `firebase_credentials.json` file is placed in the `credentials/` directory.

### Backend Usage

To run the FastAPI application, execute the following command:

```sh
uvicorn src.main:app --reload
```

This will start the server at `http://127.0.0.1:8000`.

### API Endpoints

- **POST `/get-backstory`**: Generates and retrieves a backstory.
  
  Defined in 

story_manager.py

.

- **POST `/start-story`**: Starts the story generation process.
  
  Defined in 

main.py

.

- **POST `/main-story-loop`**: Continues the story based on user choices.
  
  Defined in 

main.py

.

For more details, refer to the Backend README.

## Frontend

The frontend is developed using **Flutter**, providing a seamless and interactive user interface for story generation.

### Frontend Installation

1. **Clone the Repository:**

    ```sh
    git clone https://github.com/your-repo/adv_frontend.git
    ```

2. **Navigate to the Project Directory:**

    ```sh
    cd adv_frontend
    ```

3. **Get the Dependencies:**

    ```sh
    flutter pub get
    ```

4. **Configure Firebase:**

    Ensure that the `firebase_options.dart` file is generated and placed in the `lib/` directory. If not, follow the steps below to generate it.

5. **Run Firebase Configuration:**

    - **Install FlutterFire CLI:**

      ```bash
      dart pub global activate flutterfire_cli
      ```

    - **Add FlutterFire CLI to PATH:**

      - **Windows:**
        Add `%USERPROFILE%\AppData\Local\Pub\Cache\bin` to your PATH.
      - **macOS/Linux:**
        Add `$HOME/.pub-cache/bin` to your PATH.

    - **Authenticate and Configure:**

      ```bash
      flutterfire configure
      ```

      Follow the prompts to select your Firebase project and platforms.

### Running the App

To run the app on an emulator or connected device:

```sh
flutter run
```

For more information, visit the Frontend README.

## Contributing

Feel free to submit issues or pull requests for improvements or bug fixes in both the Backend and Frontend projects.

## License

This project is licensed under the MIT License. See the LICENSE file for details.