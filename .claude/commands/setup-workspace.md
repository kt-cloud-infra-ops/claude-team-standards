---
description: 워크스페이스 프로젝트 동기화
model: haiku
---

> **실행 모델**: `haiku` — 이 스킬을 Task 도구로 위임 시 `model: "haiku"`를 사용하세요.

# /setup-workspace - 워크스페이스 프로젝트 동기화

팀원의 로컬 프로젝트들을 workspace/ 폴더에 심볼릭 링크로 연결합니다.

## 실행 절차

### 1. 현재 workspace 상태 확인

```bash
ls -la workspace/
```

### 2. 프로젝트 설정 파일 확인

`workspace.json` 파일이 있는지 확인:

```bash
cat workspace.json 2>/dev/null || echo "workspace.json 없음 - 새로 생성 필요"
```

### 3. 사용자에게 프로젝트 경로 수집

AskUserQuestion 도구를 사용하여 질문:

**질문 1**: "프로젝트들이 있는 기본 경로를 입력해주세요"
- 예: `/Users/username/Documents/develop/workspace`
- 예: `~/projects`

**질문 2**: "연결할 프로젝트 폴더명을 입력해주세요 (콤마로 구분)"
- 예: `luppiter_web, luppiter_scheduler, test_luppiter_inv_api`

### 4. 심볼릭 링크 생성

각 프로젝트에 대해:

```bash
# 경로 확인
ls -d <BASE_PATH>/<PROJECT_NAME>

# 심볼릭 링크 생성
ln -sf <BASE_PATH>/<PROJECT_NAME> workspace/<PROJECT_NAME>
```

### 5. workspace.json 업데이트

```json
{
  "basePath": "<사용자 입력 경로>",
  "projects": [
    {"name": "luppiter_web", "path": "<full_path>"},
    {"name": "luppiter_scheduler", "path": "<full_path>"}
  ],
  "lastSync": "<현재 날짜>",
  "user": "<사용자명>"
}
```

### 6. 결과 출력

연결된 프로젝트 목록과 상태를 테이블로 출력:

| 프로젝트 | 경로 | 상태 |
|---------|------|------|
| luppiter_web | /path/to/project | ✅ 연결됨 |

---

## 주의사항

- workspace.json은 .gitignore에 포함되어 개인 설정이 공유되지 않음
- 심볼릭 링크 대상 폴더가 존재해야 함
- 기존 링크가 있으면 덮어씀 (-f 옵션)

## 관련 파일

- `workspace.json` - 개인별 프로젝트 설정 (git 제외)
- `workspace/` - 심볼릭 링크 폴더 (git 제외)
- `workspace.example.json` - 설정 예시 (git 포함)
