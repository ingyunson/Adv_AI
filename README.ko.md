# ADV_AI 프로젝트

[English](README.md)

ADV_AI는 Python 기반의 FastAPI 백엔드와 Flutter 프론트엔드를 통합하여 고급 스토리 생성을 지원하는 종합 애플리케이션입니다. 이 프로젝트는 Firestore를 데이터베이스로 사용하여 확장 가능하고 실시간 데이터 관리를 보장합니다. 또한 GPT-4o-mini 모델을 활용하여 스토리텔링 경험을 향상시킵니다.

## 목차

- 프로젝트 구조
- 백엔드
  - 설치
  - 사용법
  - API 엔드포인트
- 프론트엔드
  - 설치
  - 앱 실행
- 기여하기
- 라이선스

## 프로젝트 구조

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

## 백엔드

백엔드는 **Python**과 **FastAPI**로 구축되었으며, 스토리 생성, 사용자 데이터 관리, Firestore와의 인터페이스를 처리합니다. **GPT-4o-mini** 모델을 활용하여 역동적이고 매력적인 스토리텔링을 가능하게 합니다.

### 백엔드 설치

1. **레포지토리 클론:**

    ```sh
    git clone <repository-url>
    cd adv_backend/adv-fastapi-app
    ```

2. **가상 환경 생성:**

    ```sh
    python -m venv adv_env
    ```

3. **필요한 종속성 설치:**

    ```sh
    pip install -r requirements.txt
    ```

4. **환경 변수 설정:**

    `src/` 디렉토리에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

    ```env
    OPENAI_API_KEY=your_openai_api_key
    STABILITY_KEY=your_stability_api_key
    FIREBASE_SERVICE_ACCOUNT=credentials/firebase_credentials.json
    ```

    `firebase_credentials.json` 파일이 `credentials/` 디렉토리에 위치하도록 하세요.

### 백엔드 사용법

FastAPI 애플리케이션을 실행하려면 다음 명령을 입력하세요:

```sh
uvicorn src.main:app --reload
```

서버는 `http://127.0.0.1:8000`에서 시작됩니다.

### API 엔드포인트

- **POST `/get-backstory`**: 배경 이야기를 생성하고 반환합니다.
  
  `story_manager.py`에 정의됨

- **POST `/start-story`**: 스토리 생성 프로세스를 시작합니다.
  
  `main.py`에 정의됨

- **POST `/main-story-loop`**: 사용자의 선택에 따라 스토리를 계속 진행합니다.
  
  `main.py`에 정의됨

자세한 내용은 백엔드 README를 참조하세요.

## 프론트엔드

프론트엔드는 **Flutter**로 개발되어 스토리 생성에 대한 매끄럽고 인터랙티브한 사용자 인터페이스를 제공합니다.

### 프론트엔드 설치

1. **레포지토리 클론:**

    ```sh
    git clone https://github.com/your-repo/adv_frontend.git
    ```

2. **프로젝트 디렉토리로 이동:**

    ```sh
    cd adv_frontend
    ```

3. **종속성 가져오기:**

    ```sh
    flutter pub get
    ```

4. **Firebase 구성:**

    `firebase_options.dart` 파일이 `lib/` 디렉토리에 생성되어야 합니다. 생성되지 않았다면 아래 단계를 따라 생성하세요.

5. **Firebase 설정 실행:**

    - **FlutterFire CLI 설치:**

      ```bash
      dart pub global activate flutterfire_cli
      ```

    - **FlutterFire CLI를 PATH에 추가:**

      - **Windows:**  
        `%USERPROFILE%\AppData\Local\Pub\Cache\bin`을 PATH에 추가
      - **macOS/Linux:**  
        `$HOME/.pub-cache/bin`을 PATH에 추가

    - **인증 및 구성:**

      ```bash
      flutterfire configure
      ```

      Firebase 프로젝트와 플랫폼을 선택하는 프롬프트를 따르세요.

### 앱 실행

에뮬레이터 또는 연결된 디바이스에서 앱을 실행하려면:

```sh
flutter run
```

자세한 내용은 프론트엔드 README를 참조하세요.

## 기여하기

백엔드 및 프론트엔드 프로젝트의 개선 사항이나 버그 수정을 위해 이슈 또는 풀 리퀘스트를 자유롭게 제출하세요.

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 LICENSE 파일을 참조하세요.
