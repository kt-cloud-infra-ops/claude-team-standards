#!/usr/bin/env bash
# infraops개발관리(TECHIOPS26) 프로젝트 - 진행 중(develop/doing) 이슈 조회
# 사용: ./check-doing-develop.sh
# 인증: JIRA_EMAIL + JIRA_API_TOKEN 환경변수 또는 ~/.jira-credentials.json

set -e

if [ -n "$JIRA_EMAIL" ] && [ -n "$JIRA_API_TOKEN" ]; then
  AUTH=$(echo -n "$JIRA_EMAIL:$JIRA_API_TOKEN" | base64)
elif [ -f ~/.jira-credentials.json ]; then
  JIRA_EMAIL=$(jq -r '.email' ~/.jira-credentials.json)
  JIRA_API_TOKEN=$(jq -r '.apiToken' ~/.jira-credentials.json)
  AUTH=$(echo -n "$JIRA_EMAIL:$JIRA_API_TOKEN" | base64)
else
  echo "⚠️ Jira 인증이 없습니다. JIRA_EMAIL, JIRA_API_TOKEN 또는 ~/.jira-credentials.json 을 설정하세요."
  exit 1
fi

# 프로젝트 키 (infraops개발관리 = TECHIOPS26)
PROJECT_KEY="${JIRA_PROJECT_KEY:-TECHIOPS26}"

# 진행 중(In Progress) 이슈 조회
RESULT=$(curl -s -X POST \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d "{
    \"jql\": \"project = $PROJECT_KEY AND status = \\\"In Progress\\\" ORDER BY updated DESC\",
    \"maxResults\": 50,
    \"fields\": [\"summary\", \"status\", \"assignee\", \"issuetype\", \"updated\", \"priority\", \"customfield_10015\", \"duedate\"]
  }" \
  "https://ktcloud.atlassian.net/rest/api/3/search/jql")

if echo "$RESULT" | jq -e '.errorMessages' >/dev/null 2>&1; then
  echo "Jira API 오류:"
  echo "$RESULT" | jq -r '.errorMessages[]? // .errors | to_entries[]? | "\(.key): \(.value)"'
  exit 1
fi

TOTAL=$(echo "$RESULT" | jq -r '.total')
echo "## InfraOps개발관리 ($PROJECT_KEY) - 진행 중 (In Progress) 이슈 (총 $TOTAL건)"
echo ""

if [ "$TOTAL" -eq 0 ]; then
  echo "진행 중인 이슈가 없습니다."
  exit 0
fi

echo "| 이슈 | 유형 | 제목 | 담당자 | 우선순위 | 시작일 | 기한 | 수정일 |"
echo "|------|------|------|--------|----------|--------|------|--------|"

echo "$RESULT" | jq -r '.issues[] | [
  .key,
  .fields.issuetype.name,
  (.fields.summary | gsub("\n"; " ") | .[0:50] + (if length > 50 then "..." else "" end)),
  (.fields.assignee.displayName // "-"),
  (.fields.priority.name // "-"),
  (.fields.customfield_10015 // "-"),
  (.fields.duedate // "-"),
  (.fields.updated | split("T")[0])
] | @tsv' | while IFS=$'\t' read -r key type summary assignee priority start due updated; do
  echo "| $key | $type | $summary | $assignee | $priority | $start | $due | $updated |"
done

echo ""
echo "상세: https://ktcloud.atlassian.net/browse/$PROJECT_KEY"
