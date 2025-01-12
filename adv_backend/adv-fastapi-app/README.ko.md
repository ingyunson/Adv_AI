# 고급 FastAPI 스토리 생성 애플리케이션

[English](README.md)

이 프로젝트는 구조화된 배경 이야기와 메인 스토리 루프를 통해 스토리 생성을 지원하는 FastAPI 애플리케이션입니다.

## 프로젝트 구조

```
adv-fastapi-app
├── src
│   ├── main.py            # FastAPI 애플리케이션의 진입점
│   ├── story_manager.py   # 배경 이야기를 검색하거나 생성하는 로직 포함
│   ├── story_gen.py       # 메인 스토리 로직과 시스템 프롬프트 생성을 처리
│   └── custom_types
│       └── index.py       # 사용자 정의 타입 및 인터페이스
├── requirements.txt       # 프로젝트 의존성 목록
└── README.md              # 프로젝트 문서
```

## 설치

1. 레포지토리 클론:
   ```sh
   git clone <repository-url>
   cd adv-fastapi-app
   ```

2. 필요한 의존성 설치:
   ```sh
   pip install -r requirements.txt
   ```

## 사용법

FastAPI 애플리케이션을 실행하려면 다음 명령어를 사용하세요:

```sh
uvicorn src.main:app --reload
```

이 명령은 서버를 `http://127.0.0.1:8000`에서 시작합니다.

## API 엔드포인트

- **POST /get-backstory**: 배경 이야기를 생성하고 반환합니다.
- **POST /start-story**: 스토리 생성 프로세스를 시작합니다.
- **POST /main-story-loop**: 사용자의 선택에 따라 스토리를 계속 진행합니다.

## 기여하기

개선 사항이나 버그 수정을 위해 자유롭게 이슈 또는 풀 리퀘스트를 제출해주세요.

## 라이선스

이 프로젝트는 MIT 라이선스에 따라 배포됩니다.
