---
description: 서비스별 해야할 일 목록을 조회합니다.
model: haiku
---

서비스별 해야할 일 목록을 조회합니다.

> **실행 모델**: `haiku` — 이 스킬을 Task 도구로 위임 시 `model: "haiku"`를 사용하세요.

## 사용법
- `/tasks` - Jira + 로컬 TASKS.md 조회
- `/tasks {서비스}` - 특정 서비스만 (예: `/tasks luppiter`)
- `/tasks jira` - Jira만 조회
- `/tasks local` - 로컬 TASKS.md만 조회

## 인자
$ARGUMENTS

## 실행

### 0. Jira 인증 정보 확인 (우선순위)

1. **환경변수** (최우선): `JIRA_EMAIL`, `JIRA_API_TOKEN`
2. **로컬 파일**: `~/.jira-credentials.json`
3. **둘 다 없으면**: `/setup-jira` 안내

```bash
# 환경변수 우선 체크
if [ -n "$JIRA_EMAIL" ] && [ -n "$JIRA_API_TOKEN" ]; then
  # 환경변수 사용
elif [ -f ~/.jira-credentials.json ]; then
  # 로컬 파일 사용
  JIRA_EMAIL=$(jq -r '.email' ~/.jira-credentials.json)
  JIRA_API_TOKEN=$(jq -r '.apiToken' ~/.jira-credentials.json)
else
  # 설정 필요
  echo "⚠️ Jira 인증 정보가 없습니다."
  echo "/setup-jira 를 실행하거나 환경변수를 설정해주세요."
fi
```

**둘 다 없으면** → 로컬 TASKS.md만 표시

### 1. Jira 이슈 조회 (인증 있을 때)

```bash
AUTH=$(echo -n "$JIRA_EMAIL:$JIRA_API_TOKEN" | base64)

# 담당 이슈 조회 (미완료) — 시작일·기한 필드 포함
# POST /rest/api/3/search/jql 사용, fields에 customfield_10015(Start date), duedate 필수
curl -s -X POST \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d '{"jql":"project = TECHIOPS26 AND assignee = currentUser() AND status not in (Done, \"Cancel(취소)\") ORDER BY status ASC, updated DESC","maxResults":50,"fields":["summary","status","priority","issuetype","updated","labels","parent","customfield_10015","duedate"]}' \
  "https://ktcloud.atlassian.net/rest/api/3/search/jql"
```

### 2. 로컬 TASKS.md 조회

`docs/service/` 폴더 아래 모든 서비스의 TASKS.md 파일 확인

### 3. 기간 내 미진행 경고

- 각 이슈의 **시작일(customfield_10015)** 과 **기한(duedate)** 을 사용한다.
- **이니셔티브(issuetype)** 는 경고 대상에서 **제외**한다 (에픽/작업 등만 경고 대상).
- **오늘이 시작일~기한 사이**(시작일 ≤ 오늘 ≤ 기한)인데, 상태가 **진행 중(In Progress)** 도 **완료(Done)** 도 아니면 → 해당 행에 **⚠️** 경고를 붙여 표시한다.
- 표시 예: `| TECHIOPS26-xxx | ⚠️ 제목 |` 또는 제목 뒤에 `⚠️ 기간 내 미진행` 등으로 구분 가능하게 표시.
- 참고: TECHIOPS26-264처럼 기한이 2/24~2/28이면, 오늘이 2/5일 때는 **기간 밖**이라 경고가 안 걸린다. 2/24 이후에 Backlog/To Do로 남아 있으면 그때 ⚠️ 표시됨.

### 4. 출력 형식

```
## Jira - TECHIOPS26 (@사용자명)

### 🔴 In Progress (진행 중)
| 이슈 | 제목 |
|------|------|
| TECHIOPS26-xxx | 제목 |

### 🟡 To Do (할일)
| 이슈 | 제목 |
|------|------|
| TECHIOPS26-xxx | 제목 (기간 내면 ⚠️ 표시) |

### ⚪ Backlog (백로그)
...

---

## 로컬 TASKS.md

### luppiter
(TASKS.md 내용)

### gaia
...
```

### 5. 인자별 처리

| 인자 | 동작 |
|------|------|
| 없음 | Jira + 모든 서비스 TASKS.md |
| `jira` | Jira만 |
| `local` | 로컬 TASKS.md만 |
| 서비스명 | 해당 서비스 TASKS.md + 관련 Jira 이슈 |

### 6. 서비스-Jira 매핑

이슈 제목에서 서비스 추출:
- `유피테르` → luppiter
- `가이아` → gaia
- `헤라` → hera
- `헤르메스` → hermes
- `내재화` → 공통 (모든 서비스에 표시)

결과를 한국어로 정리해서 보여주세요.
