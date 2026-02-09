# Jira REST API 자동화 가이드

MCP Atlassian 도구의 한계로 인해 curl을 통한 직접 API 호출이 필요한 경우가 있습니다.

> **워크플로우 규칙(이슈 생성/수정/완료 처리)은 `.claude/rules/jira-workflow.md` 참조**

---

## 인증 정보

```bash
# Base64 인코딩된 인증 헤더 생성
AUTH=$(echo -n 'email@kt.com:API_TOKEN' | base64)

# 인증 정보 위치
# ~/.jira-credentials.json (email + apiToken + baseUrl)
```

> **Windows 사용자**: 아래 본문은 Mac/Linux 기준입니다. Windows 연동은 문서 맨 아래 **[부록] Windows에서 Jira 연동하기** 참조.

---

## MCP vs REST API 비교

| 기능 | MCP 도구 | REST API |
|------|----------|----------|
| 이슈 조회 | `read_jira_issue` | GET /rest/api/3/issue/{key} |
| **이슈 검색** | X (deprecated) | GET /rest/api/3/search/jql |
| 이슈 생성 | `create_jira_issue` | POST /rest/api/3/issue |
| **이슈 수정** | X | PUT /rest/api/3/issue/{key} |
| **상태 변경** | X | POST /rest/api/3/issue/{key}/transitions |
| 코멘트 추가 | `add_jira_comment` | POST /rest/api/3/issue/{key}/comment |
| **코멘트 삭제** | X | DELETE /rest/api/3/issue/{key}/comment/{id} |

> **Note**: MCP `search_jira_issues`는 deprecated API(`/rest/api/3/search`) 사용으로 에러 발생.

---

## 자주 사용하는 API

### 이슈 검색 (JQL)

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

### 이슈 수정

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
  "https://ktcloud.atlassian.net/rest/api/3/issue/{issueKey}"
```

### 상태 변경 (Transition)

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

### 수정 가능한 필드 확인

```bash
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  "https://ktcloud.atlassian.net/rest/api/3/issue/{issueKey}/editmeta" | jq '.fields | keys'
```

### 필드 ID 조회

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
| In Review(검토 중) | 5 | 태스크 완료 후 보고자 검토 단계 |
| Done(완료) | 6 | 완료 |
| Cancel(취소) | 7 | 취소 |
| Issue Detected(문제 발생) | 8 | 이슈 발생 |

---

## ADF 체크박스 처리

### 체크박스 상태 확인

```bash
curl -s -X GET ... | jq '.. | select(.localId?) | {localId, state}'
```

### taskItem state 변경 (TODO → DONE)

```json
{
  "type": "taskItem",
  "attrs": {
    "localId": "task-1",
    "state": "DONE"
  }
}
```

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

### 페이지 생성 시 주의사항

경로(부모 페이지)는 반드시 사용자에게 확인 후 진행.

### JSON 형식

```json
{
  "version": {"number": "현재버전+1"},
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

## [부록] Windows에서 Jira 연동하기

팀은 대부분 Mac/Linux를 사용하며, Windows 사용자만 아래 내용을 참고하면 됩니다.

### Windows 초기 설정 순서

1. **API 토큰 미리 발급**  
   https://id.atlassian.com/manage-profile/security/api-tokens 에서 Create API token 후 복사해 둡니다.
2. **저장소 루트로 이동**  
   `cd c:\git_dev\claude-team-standards` (또는 클론한 경로).
3. **설정 스크립트 실행**  
   `.\docs\ktcloud\jira\setup-jira-windows.ps1`  
   - 인증 파일이 없으면 **Jira 이메일(KT 이메일)** 과 **API 토큰** 입력을 묻습니다.  
   - 입력한 값은 `%USERPROFILE%\.jira-credentials.json` 에 저장됩니다.
4. **연동 성공** 시 "연동 성공: 이름 (이메일)" 및 담당 이슈 일부가 출력됩니다.  
   이후 담당 이슈 조회는 `.\docs\ktcloud\jira\tasks-jira.ps1` 로 실행하면 됩니다.

**검증**: 저장소 루트에서 `.\docs\ktcloud\jira\setup-jira-windows.ps1`(최초 설정·연동 테스트) 또는 `.\docs\ktcloud\jira\tasks-jira.ps1`(담당 이슈 조회) 실행 시 정상 동작하면 설정 완료입니다.

### 1. 인증 파일 위치

| 환경 | 경로 |
|------|------|
| Linux/macOS | `~/.jira-credentials.json` |
| Windows | `%USERPROFILE%\.jira-credentials.json` (예: `C:\Users\내이름\.jira-credentials.json`) |

PowerShell에서 경로 확인:

```powershell
Join-Path $env:USERPROFILE ".jira-credentials.json"
```

### 2. 인증 방법 (둘 중 하나)

**방법 A: 환경변수** (PowerShell 세션 또는 시스템 환경변수)

```powershell
$env:JIRA_EMAIL = "your.email@kt.com"
$env:JIRA_API_TOKEN = "발급받은_API_토큰"
```

**방법 B: credentials 파일** (프로젝트/스크립트에서 공통 사용 시 권장)

1. API 토큰 발급: https://id.atlassian.com/manage-profile/security/api-tokens  
2. 아래 내용으로 JSON 파일을 **사용자 폴더**에 저장  
   - 파일명: `.jira-credentials.json`  
   - 경로: `$env:USERPROFILE\.jira-credentials.json`

```json
{
  "email": "your.email@kt.com",
  "apiToken": "발급받은_API_토큰",
  "baseUrl": "https://ktcloud.atlassian.net"
}
```

PowerShell로 한 번에 생성 (실행 후 이메일·토큰 입력):

```powershell
$credPath = Join-Path $env:USERPROFILE ".jira-credentials.json"
$email = Read-Host "Jira 이메일 (KT 이메일)"
$token = Read-Host "API 토큰" -AsSecureString
$tokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))
@{
  email    = $email
  apiToken = $tokenPlain
  baseUrl  = "https://ktcloud.atlassian.net"
} | ConvertTo-Json | Set-Content $credPath -Encoding UTF8
Write-Host "저장됨: $credPath"
```

### 3. 연동 테스트 (PowerShell)

```powershell
# credentials 파일에서 읽기
$credPath = Join-Path $env:USERPROFILE ".jira-credentials.json"
if (-not (Test-Path $credPath)) {
  Write-Host "인증 파일이 없습니다: $credPath"
  exit 1
}
$cred = Get-Content $credPath -Raw -Encoding UTF8 | ConvertFrom-Json
$email = $cred.email
$token = $cred.apiToken

# Basic 인증 헤더
$bytes = [System.Text.Encoding]::ASCII.GetBytes("${email}:${token}")
$auth = [Convert]::ToBase64String($bytes)
$headers = @{
  Authorization = "Basic $auth"
  "Content-Type" = "application/json"
}

# 현재 사용자 조회 (연동 확인)
Invoke-RestMethod -Uri "https://ktcloud.atlassian.net/rest/api/3/myself" -Headers $headers -Method Get
```

성공 시 `displayName`, `emailAddress` 등이 나오면 연동된 것입니다. `/tasks jira` 또는 아래 Windows용 API 예시도 사용할 수 있습니다.

### 4. 담당 이슈 조회 (Windows)

```powershell
$jql = [uri]::EscapeDataString('project = TECHIOPS26 AND assignee = currentUser() AND status not in (Done, "Cancel(취소)") ORDER BY status ASC, updated DESC')
$uri = "https://ktcloud.atlassian.net/rest/api/3/search/jql?jql=$jql&maxResults=50&fields=summary,status,priority,issuetype,updated"
$res = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
$res.issues | ForEach-Object { "$($_.key)`t$($_.fields.status.name)`t$($_.fields.summary)" }
```

자동 설정 스크립트는 `docs/ktcloud/jira/setup-jira-windows.ps1` 를 실행하세요. (저장소 루트에서 `.\docs\ktcloud\jira\setup-jira-windows.ps1`)

---

**최종 업데이트**: 2026-02-09
