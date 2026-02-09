---
description: 서비스에 새로운 프로젝트 문서 구조를 추가합니다.
model: haiku
---

> **실행 모델**: `haiku` — 이 스킬을 Task 도구로 위임 시 `model: "haiku"`를 사용하세요.

# Add Project to Service

서비스에 새로운 프로젝트 문서 구조를 추가합니다.

## 사용법

```
/add-project {서비스명} {프로젝트명}
```

## 실행 내용

1. `docs/service/{서비스명}/projects/{프로젝트명}/` 폴더 생성
2. 기본 구조 생성:
   ```
   {프로젝트명}/
   ├── README.md           # 프로젝트 개요
   └── decisions/          # 프로젝트 레벨 ADR
   ```

3. README.md 템플릿 생성:
   - 프로젝트 설명
   - 기술 스택
   - 주요 기능
   - 관련 문서 링크

4. 서비스 README.md 업데이트:
   - 프로젝트 구성 테이블에 추가

## 예시

```
/add-project luppiter inventory_api
```

→ `docs/service/luppiter/projects/inventory_api/` 생성

## 프로젝트 폴더 확장

필요에 따라 하위 폴더 추가:

```
{프로젝트명}/
├── README.md
├── decisions/          # ADR
├── api/                # API 문서 (웹 프로젝트)
├── screens/            # 화면 명세 (웹 프로젝트)
├── batch/              # 배치 작업 (스케줄러)
└── claude_temp/        # Claude 임시 파일 (Confluence X)
```

## 참고

- 서비스가 없으면 `/create-service` 먼저 실행
- 프로젝트명은 git 저장소명에서 서비스 접두사 제거 권장
  - `luppiter_scheduler` → `scheduler`
