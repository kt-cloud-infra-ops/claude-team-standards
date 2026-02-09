# Windows에서 Jira 연동하기

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
