# /tasks jira - fetch assignee issues (TECHIOPS26)
# 사용법: 저장소 루트에서 .\docs\ktcloud\jira\tasks-jira.ps1
$credPath = Join-Path $env:USERPROFILE ".jira-credentials.json"
if ($env:JIRA_EMAIL -and $env:JIRA_API_TOKEN) {
  $email = $env:JIRA_EMAIL
  $token = $env:JIRA_API_TOKEN
} elseif (Test-Path $credPath) {
  $cred = Get-Content $credPath -Raw -Encoding UTF8 | ConvertFrom-Json
  $email = $cred.email
  $token = $cred.apiToken
} else {
  Write-Host "No Jira auth. Set JIRA_EMAIL, JIRA_API_TOKEN or create: $credPath"
  exit 1
}

$bytes = [System.Text.Encoding]::ASCII.GetBytes("${email}:${token}")
$auth = [Convert]::ToBase64String($bytes)
$headers = @{
  Authorization = "Basic $auth"
  "Content-Type" = "application/json"
}

$body = @{
  jql        = 'project = TECHIOPS26 AND assignee = currentUser() AND status not in (Done, "Cancel(취소)") ORDER BY status ASC, updated DESC'
  maxResults = 50
  fields     = @("summary", "status", "priority", "issuetype", "updated", "labels", "parent", "customfield_10015", "duedate")
} | ConvertTo-Json

try {
  $res = Invoke-RestMethod -Uri "https://ktcloud.atlassian.net/rest/api/3/search/jql" -Method Post -Headers $headers -Body $body
  $me = Invoke-RestMethod -Uri "https://ktcloud.atlassian.net/rest/api/3/myself" -Headers $headers -Method Get
  Write-Host "## Jira - TECHIOPS26 (@$($me.displayName))"
  Write-Host ""

  $byStatus = $res.issues | Group-Object { $_.fields.status.name }
  $sorted = $byStatus | Sort-Object {
    if ($_.Name -match "Progress") { 1 } elseif ($_.Name -match "To Do") { 2 } elseif ($_.Name -match "Backlog") { 3 } else { 9 }
  }

  foreach ($g in $sorted) {
    $label = $g.Name
    if ($g.Name -match "In Progress") { $label = "[In Progress] " + $g.Name }
    elseif ($g.Name -match "To Do") { $label = "[To Do] " + $g.Name }
    elseif ($g.Name -match "Backlog") { $label = "[Backlog] " + $g.Name }
    Write-Host "### $label"
    Write-Host "Issue | Summary"
    Write-Host "------|--------"
    foreach ($i in $g.Group) {
      Write-Host "$($i.key) | $($i.fields.summary)"
    }
    Write-Host ""
  }
} catch {
  Write-Host "Jira API error: $($_.Exception.Message)"
  if ($_.ErrorDetails.Message) { Write-Host $_.ErrorDetails.Message }
  exit 1
}
