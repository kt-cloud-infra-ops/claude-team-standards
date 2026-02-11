# Jira 연동 설정 및 테스트 (Windows PowerShell)
# 사용법: 저장소 루트에서 .\docs\ktcloud\jira\setup-jira-windows.ps1
# 사전 준비: API 토큰 발급 https://id.atlassian.com/manage-profile/security/api-tokens

$ErrorActionPreference = "Stop"
if ($PSVersionTable.PSVersion.Major -ge 5) {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
}
$baseUrl = "https://ktcloud.atlassian.net"
$credPath = Join-Path $env:USERPROFILE ".jira-credentials.json"

function Get-AuthHeaders {
    if ($env:JIRA_EMAIL -and $env:JIRA_API_TOKEN) {
        $email = $env:JIRA_EMAIL
        $token = $env:JIRA_API_TOKEN
    } elseif (Test-Path $credPath) {
        $cred = Get-Content $credPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $email = $cred.email
        $token = $cred.apiToken
    } else {
        return $null
    }
    $bytes = [System.Text.Encoding]::ASCII.GetBytes("${email}:${token}")
    $auth = [Convert]::ToBase64String($bytes)
    return @{
        Authorization = "Basic $auth"
        "Content-Type" = "application/json"
    }
}

Write-Host "=== Jira 연동 (Windows) ===" -ForegroundColor Cyan
Write-Host "인증 파일 경로: $credPath"
Write-Host ""

$headers = Get-AuthHeaders

if (-not $headers) {
    Write-Host "인증이 없습니다. credentials 파일을 생성합니다." -ForegroundColor Yellow
    Write-Host "API 토큰 미리 발급: https://id.atlassian.com/manage-profile/security/api-tokens" -ForegroundColor Gray
    $email = Read-Host "Jira 이메일 (KT 이메일)"
    $token = Read-Host "API 토큰 (비밀번호처럼 입력됨)" -AsSecureString
    $tokenPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($token))
    $obj = @{
        email    = $email
        apiToken = $tokenPlain
        baseUrl  = $baseUrl
    }
    $obj | ConvertTo-Json | Set-Content $credPath -Encoding UTF8
    Write-Host "저장됨: $credPath"
    $headers = Get-AuthHeaders
}

try {
    $me = Invoke-RestMethod -Uri "$baseUrl/rest/api/3/myself" -Headers $headers -Method Get
    Write-Host "연동 성공: $($me.displayName) ($($me.emailAddress))" -ForegroundColor Green
    Write-Host ""
    Write-Host "담당 이슈 조회 예시:"
    $jql = [uri]::EscapeDataString('project = TECHIOPS26 AND assignee = currentUser() AND status not in (Done, "Cancel(취소)") ORDER BY updated DESC')
    $uri = "$baseUrl/rest/api/3/search/jql?jql=$jql&maxResults=10&fields=summary,status"
    $res = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
    $res.issues | ForEach-Object { Write-Host "  $($_.key)  $($_.fields.status.name)  $($_.fields.summary)" }
} catch {
    Write-Host "연동 실패: $_" -ForegroundColor Red
    Write-Host "API 토큰 재발급: https://id.atlassian.com/manage-profile/security/api-tokens"
    exit 1
}
