# /setup-workspace - 워크스페이스 프로젝트 동기화

workspace/ 폴더에 프로젝트를 심볼릭 링크로 연결합니다.
로컬에 프로젝트가 있으면 연결, 없으면 GitHub에서 clone 후 연결합니다.

## 실행 절차

### 1. 현재 상태 확인

```bash
ls -la workspace/
cat workspace.json 2>/dev/null || echo "workspace.json 없음"
```

### 2. 모드 선택

AskUserQuestion으로 질문:

**질문**: "워크스페이스 설정 모드를 선택해주세요"
- **로컬 연결**: 이미 clone된 프로젝트를 심볼릭 링크로 연결
- **GitHub 클론**: GitHub에서 프로젝트를 clone 후 연결

---

### 모드 A: 로컬 연결

#### A-1. 경로 수집

AskUserQuestion:

**질문 1**: "프로젝트들이 있는 기본 경로를 입력해주세요"
- 예: `/Users/username/Documents/develop/workspace`

**질문 2**: "연결할 프로젝트 폴더명을 입력해주세요 (콤마로 구분)"
- 예: `luppiter_web, luppiter_scheduler`

#### A-2. 심볼릭 링크 생성

```bash
# 경로 존재 확인 후 링크
ls -d <BASE_PATH>/<PROJECT_NAME>
ln -sf <BASE_PATH>/<PROJECT_NAME> workspace/<PROJECT_NAME>
```

---

### 모드 B: GitHub 클론

#### B-1. GitHub 인증 확인

```bash
gh auth status
```

인증 안 되어 있으면 안내:
```
gh auth login 으로 먼저 인증해주세요.
```

#### B-2. 저장소 목록 조회

```bash
gh repo list kt-cloud-infra-ops --limit 50 --json name,description \
  --template '{{range .}}{{.name}}\t{{.description}}{{"\n"}}{{end}}'
```

#### B-3. 프로젝트 선택

AskUserQuestion:

**질문 1**: "프로젝트를 저장할 기본 경로를 입력해주세요"
- 예: `/Users/username/Documents/develop/workspace`

**질문 2**: "clone할 프로젝트를 선택해주세요 (콤마로 구분)"
- 위 목록에서 선택

#### B-4. Clone + 심볼릭 링크

각 프로젝트에 대해:

```bash
# basePath에 clone
gh repo clone kt-cloud-infra-ops/<PROJECT_NAME> <BASE_PATH>/<PROJECT_NAME>

# 심볼릭 링크 생성
ln -sf <BASE_PATH>/<PROJECT_NAME> workspace/<PROJECT_NAME>
```

---

### 3. workspace.json 업데이트

```json
{
  "org": "kt-cloud-infra-ops",
  "basePath": "<사용자 입력 경로>",
  "projects": [
    {"name": "luppiter_web", "path": "<full_path>", "remote": "kt-cloud-infra-ops/luppiter_web"}
  ],
  "lastSync": "<현재 날짜>",
  "user": "<사용자명>"
}
```

### 4. 결과 출력

| 프로젝트 | 경로 | 모드 | 상태 |
|---------|------|------|------|
| luppiter_web | /path/to/project | clone | ✅ 연결됨 |
| luppiter_scheduler | /path/to/project | 로컬 | ✅ 연결됨 |

---

## 주의사항

- workspace.json은 .gitignore에 포함되어 개인 설정이 공유되지 않음
- 기존 링크가 있으면 덮어씀 (-f 옵션)
- GitHub org: `kt-cloud-infra-ops` 고정

## 관련 파일

- `workspace.json` - 개인별 프로젝트 설정 (git 제외)
- `workspace/` - 심볼릭 링크 폴더 (git 제외)
- `workspace.example.json` - 설정 예시 (git 포함)
