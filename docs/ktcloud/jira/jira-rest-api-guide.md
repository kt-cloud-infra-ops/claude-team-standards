# Jira REST API 자동화 가이드

MCP Atlassian 도구의 한계로 인해 curl을 통한 직접 API 호출이 필요한 경우가 있습니다.

---

## 인증 정보

```bash
# Base64 인코딩된 인증 헤더 생성
AUTH=$(echo -n 'email@kt.com:API_TOKEN' | base64)

# 인증 정보 위치
# ~/.claude.json > mcpServers > atlassian > env
```

---

## MCP vs REST API 비교

| 기능 | MCP 도구 | REST API |
|------|----------|----------|
| 이슈 조회 | `read_jira_issue` | GET /rest/api/3/issue/{key} |
| **이슈 검색** | ❌ 에러 (deprecated) | GET /rest/api/3/search/jql |
| 이슈 생성 | `create_jira_issue` | POST /rest/api/3/issue |
| **이슈 수정** | ❌ 없음 | PUT /rest/api/3/issue/{key} |
| **상태 변경** | ❌ 없음 | POST /rest/api/3/issue/{key}/transitions |
| 코멘트 추가 | `add_jira_comment` | POST /rest/api/3/issue/{key}/comment |
| **코멘트 삭제** | ❌ 없음 | DELETE /rest/api/3/issue/{key}/comment/{id} |

> **Note**: MCP `search_jira_issues`는 deprecated API(`/rest/api/3/search`) 사용으로 에러 발생.
> 2025년 8월부터 Atlassian이 `/rest/api/3/search/jql`로 마이그레이션 강제.

---

## 자주 사용하는 API

### 0. 이슈 검색 (JQL)

```bash
# 담당자 미완료 이슈 조회
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  "https://ktcloud.atlassian.net/rest/api/3/search/jql?jql=assignee=currentUser()%20AND%20status%20not%20in%20(Done,Cancel)%20ORDER%20BY%20updated%20DESC&maxResults=30&fields=summary,status,priority,issuetype,updated,project" \
  | jq -r '.issues[] | "\(.key)\t\(.fields.status.name)\t\(.fields.summary)"'

# 프로젝트별 조회
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  "https://ktcloud.atlassian.net/rest/api/3/search/jql?jql=project=TECHIOPS26%20AND%20assignee=currentUser()&maxResults=20&fields=summary,status"
```

### 1. 이슈 수정

```bash
curl -s -X PUT \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "summary": "새 제목",
      "customfield_14516": "A.C. 내용",
      "customfield_10015": "2026-01-12",
      "duedate": "2026-02-28"
    }
  }' \
  "https://ktcloud.atlassian.net/rest/api/3/issue/TECHIOPS26-252"
```

### 2. 상태 변경 (Transition)

```bash
# 가능한 상태 조회
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  "https://ktcloud.atlassian.net/rest/api/3/issue/{issueKey}/transitions" | jq '.transitions[] | {id, name}'

# 상태 변경 실행
curl -s -X POST \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d '{"transition": {"id": "4"}}' \
  "https://ktcloud.atlassian.net/rest/api/3/issue/{issueKey}/transitions"
```

### 3. 수정 가능한 필드 확인

```bash
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  "https://ktcloud.atlassian.net/rest/api/3/issue/{issueKey}/editmeta" | jq '.fields | keys'
```

### 4. 필드 ID 조회

```bash
# 전체 필드 목록
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  "https://ktcloud.atlassian.net/rest/api/3/field" | jq '.[] | {id, name}'

# 특정 이름으로 필터
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  "https://ktcloud.atlassian.net/rest/api/3/field" | jq '.[] | select(.name | test("A.C.|시작|종료"; "i")) | {id, name}'
```

---

## 주요 필드 ID (TECHIOPS26 기준)

| 필드명 | 필드 ID |
|--------|---------|
| A.C.(Acceptance Criteria) | `customfield_14516` |
| Start date | `customfield_10015` |
| 기한 (Due date) | `duedate` |
| Epic Link | `customfield_10014` |

---

## 상태 Transition ID (TECHIOPS26 기준)

| 상태 | ID | 설명 |
|------|-----|------|
| Backlog(백로그) | 2 | 초기 상태 |
| To Do(할일) | 3 | 작업 예정 |
| In Progress(진행 중) | 4 | 작업 중 |
| In Review(검토 중) | 5 | **태스크 완료 후 보고자 검토 단계** |
| Done(완료) | 6 | 완료 |
| Cancel(취소) | 7 | 취소 |
| Issue Detected(문제 발생) | 8 | 이슈 발생 |

---

## A.C. 필드 업데이트 (마크다운 체크박스)

**중요**: A.C. 필드는 반드시 마크다운 체크박스 형식 사용.

```bash
curl -s -X PUT \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "customfield_14516": "### 요구사항\n- [ ] 항목 1\n- [ ] 항목 2\n- [x] 완료된 항목\n\n### 개발 단계\n- [x] 요구사항 분석\n- [x] 설계\n- [ ] 구현 (진행 중)\n- [ ] 단위 테스트\n- [ ] 통합 테스트\n- [ ] 코드 리뷰"
    }
  }' \
  "https://ktcloud.atlassian.net/rest/api/3/issue/{issueKey}"
```

### 마크다운 체크박스 형식
- `- [ ]`: 미완료
- `- [x]`: 완료
- `###`: 섹션 제목

### 개발 단계 표준 순서

개발 관련 태스크 A.C.에 반드시 포함:

```
### 개발 단계
- [ ] 요구사항 분석
- [ ] 설계
- [ ] 구현
- [ ] 단위 테스트
- [ ] 코드 리뷰
- [ ] 통합 테스트
```

**순서 중요**: 구현 완료 → 단위 테스트 → 코드 리뷰 → 통합 테스트

---

## 배치 업데이트 예시

```bash
AUTH=$(echo -n 'email@kt.com:API_TOKEN' | base64)

for i in 253 254 255 256 257 258 259; do
  # 상태 변경
  curl -s -X POST \
    -H "Authorization: Basic $AUTH" \
    -H "Content-Type: application/json" \
    -d '{"transition": {"id": "4"}}' \
    "https://ktcloud.atlassian.net/rest/api/3/issue/TECHIOPS26-$i/transitions" -o /dev/null

  # 날짜 업데이트
  curl -s -X PUT \
    -H "Authorization: Basic $AUTH" \
    -H "Content-Type: application/json" \
    -d '{"fields": {"customfield_10015": "2026-01-12", "duedate": "2026-02-28"}}' \
    "https://ktcloud.atlassian.net/rest/api/3/issue/TECHIOPS26-$i" -o /dev/null

  echo "TECHIOPS26-$i done"
done
```

---

## 이슈 단위 기준

| 이슈 유형 | 기간 | 설명 |
|----------|------|------|
| **Epic** | 1개월 | 월 단위 큰 목표 |
| **Task** | 1주 | 주 단위 실행 가능한 작업 |

---

## 상태별 엄격도

| 상태 | 엄격도 | 설명 |
|------|--------|------|
| **Backlog** | 🟢 러프 | 아이디어 단계, 대략적 내용만 |
| **To Do** | 🟡 상세 | 실행 준비, 상세 내용 필수 |
| **In Progress** | 🔴 엄격 | 실행 중, 모든 조건 충족 |

---

## ⚠️ 이슈 조회 시 점검 (필수)

**Jira 티켓 조회할 때 항상 아래 항목 점검:**

| 항목 | 점검 내용 | 조치 |
|------|----------|------|
| A.C. 형식 | 체크박스(taskList) 형식인가? | 아니면 체크박스로 변환 |
| A.C. 내용 | 구체적인 완료 기준이 있는가? | 부족하면 보완 제안 |
| Description | 배경/목적/설계가 있는가? | 없으면 추가 |
| Start date | 시작일이 설정되어 있는가? | 없으면 설정 |
| Due date | 기한이 설정되어 있는가? | 없으면 설정 |
| Epic Link | Epic에 연결되어 있는가? | 없으면 연결 |

### A.C. 체크박스 변환 예시

```json
// Before (단순 텍스트)
"content": [{"type": "paragraph", "content": [{"type": "text", "text": "분석 완료"}]}]

// After (체크박스)
"content": [
  {"type": "taskList", "attrs": {"localId": "ac-1"}, "content": [
    {"type": "taskItem", "attrs": {"localId": "t-1", "state": "TODO"}, "content": [{"type": "text", "text": "분석 완료"}]}
  ]}
]
```

---

## ⚠️ 이슈 생성 (필수)

> **핵심: 부족하면 물어보고, 설계 없으면 캐물어서 작성**

### Backlog 생성

- 🟢 러프하게 생성 가능
- 대략적인 Summary, Description만으로 OK
- A.C. 간단하게 또는 생략 가능

### To Do/In Progress 생성 또는 전환

- 🔴 엄격하게 확인
- 모든 필수 항목 충족 필요

### 질문 프로세스 (부족하면 반드시 물어본다)

```
1. "어떤 작업인가요?" → Summary
2. "왜 필요한가요?" → 배경/목적
3. "어떻게 구현하나요?" → 설계 내용
4. "완료 기준이 뭔가요?" → A.C.
5. "언제까지인가요?" → 기간
6. "어떤 Epic에 속하나요?" → Epic 연결
```

### 설계 내용 없으면 캐물어서 작성

```
- "구체적인 구현 방식이 어떻게 되나요?"
- "어떤 API/화면이 필요한가요?"
- "예상되는 산출물이 뭔가요?"
- "테스트는 어떻게 진행하나요?"
```

### A.C. 제안 규칙

```
# Bad
- [ ] 개발 완료

# Good (제안)
- [ ] API 엔드포인트 구현
- [ ] 단위 테스트 작성
- [ ] 코드 리뷰 완료
```

---

## ⚠️ 태스크 완료 처리 (필수)

**태스크 완료 요청 시 반드시 아래 4가지를 모두 처리:**

| 순서 | 항목 | 필드 | 비고 |
|------|------|------|------|
| 1 | **A.C. 내용 검토** | `customfield_14516` | 부족하면 보완 제안 |
| 2 | A.C. 체크박스 완료 | `customfield_14516` | 모두 DONE |
| 3 | Description 체크박스 완료 | `description` | 모두 DONE |
| 4 | 상태 변경 | transitions API | In Review/Done |

### A.C. 보완 제안 (상태 변경 전)

- A.C. 내용이 부족하거나 누락된 항목이 있으면 **사용자에게 보완 제안**
- 사용자 승인 후 A.C. 업데이트 → 체크박스 완료 → 상태 변경

### ADF 체크박스 완료 처리

```bash
# 체크박스 상태 확인
curl -s -X GET ... | jq '.. | select(.localId?) | {localId, state}'

# taskItem의 state를 "TODO" → "DONE"으로 변경
{
  "type": "taskItem",
  "attrs": {
    "localId": "task-1",
    "state": "DONE"  // ← TODO에서 DONE으로
  }
}
```

### 완료 처리 순서

```
1. 이슈 조회 (A.C., description 확인)
2. A.C. 내용 검토 → 부족하면 보완 제안
3. (사용자 승인 후) A.C. 업데이트
4. A.C. 체크박스 모두 DONE 처리
5. Description 체크박스 모두 DONE 처리
6. 상태 변경 (In Review 또는 Done)
7. 보고자 멘션 댓글 (필요시)
```

> **주의**: sandbox 제한으로 파일 쓰기 실패 가능 → 직접 JSON으로 API 요청

---

## 에러 처리

| HTTP 코드 | 의미 |
|-----------|------|
| 200 | 성공 (조회) |
| 204 | 성공 (수정/삭제) |
| 400 | 잘못된 요청 (필드 ID 오류 등) |
| 401 | 인증 실패 |
| 404 | 이슈 없음 |

### 필드 설정 불가 에러

```json
{"errors":{"customfield_XXXXX":"Field cannot be set. It is not on the appropriate screen"}}
```

→ 해당 이슈 유형/화면에서 사용 불가능한 필드. `editmeta` API로 사용 가능한 필드 확인 필요.

---

## Confluence REST API

### 페이지 생성 시 주의사항

**⚠️ 경로(부모 페이지)는 반드시 사용자에게 확인 후 진행**

```
1. 적절한 부모 페이지 후보 검색
2. 사용자에게 경로 추천 및 확인 요청
3. 승인 후 페이지 생성
```

### 페이지 업데이트

```bash
# 현재 버전 확인
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  "https://ktcloud.atlassian.net/wiki/rest/api/content/{pageId}?expand=version" | jq '.version.number'

# 페이지 업데이트 (버전 +1 필수)
curl -s -X PUT \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d @content.json \
  "https://ktcloud.atlassian.net/wiki/rest/api/content/{pageId}"
```

### JSON 형식

```json
{
  "version": {"number": 현재버전+1},
  "title": "페이지 제목",
  "type": "page",
  "body": {
    "storage": {
      "value": "<p>HTML/Storage Format 내용</p>",
      "representation": "storage"
    }
  }
}
```

### 문서 관리 규칙

| 규칙 | 설명 |
|------|------|
| Confluence 문서 | 로컬에 **링크만** 유지 |
| 로컬 전용 문서 | `claude_` prefix 사용 |
| MCP 사용 안함 | REST API 직접 호출 (1000자 제한 없음) |

---

**최종 업데이트**: 2026-02-05
