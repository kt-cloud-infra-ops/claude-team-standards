---
tags:
  - type/guide
  - domain/jira
  - audience/claude
---

> 상위: [common](README.md) · [claude_lessons_learned](../README.md)

# Jira MCP 도구 한계와 해결책

## 문제

MCP Atlassian 패키지에서 Jira 관련 도구가 불완전함:
- Confluence: `update_confluence_page` ✅ 있음
- Jira: `update_jira_issue` ❌ 없음

## 누락/에러 기능

| 기능 | MCP | 해결책 |
|------|-----|--------|
| **이슈 검색** | ❌ 에러 | curl GET /rest/api/3/search/jql |
| 이슈 수정 | ❌ | curl PUT /rest/api/3/issue/{key} |
| 상태 변경 | ❌ | curl POST /rest/api/3/issue/{key}/transitions |
| 이슈 삭제 | ❌ | curl DELETE /rest/api/3/issue/{key} |
| 코멘트 삭제 | ❌ | curl DELETE |

> **검색 API 에러 원인**: MCP가 deprecated `/rest/api/3/search` 사용.
> Atlassian이 2025년 8월부터 `/rest/api/3/search/jql`로 강제 마이그레이션.

## 해결책

MCP 도구에 없는 기능은 curl로 직접 REST API 호출.

### 인증 정보 위치

```
~/.claude.json > mcpServers > atlassian > env
- ATLASSIAN_EMAIL
- ATLASSIAN_API_TOKEN
```

### 사용 예시

```bash
AUTH=$(echo -n 'email:token' | base64)

curl -s -X PUT \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d '{"fields": {"summary": "새 제목"}}' \
  "https://ktcloud.atlassian.net/rest/api/3/issue/KEY-123"
```

## 교훈

1. MCP 도구가 안 된다고 포기하지 말 것
2. REST API 직접 호출로 해결 가능
3. 인증 정보는 MCP 설정에서 재사용

## 관련 문서

- `docs/ktcloud/jira/jira-rest-api-guide.md`
- `docs/claude_automations/jira-api-automation.md`

---

**작성일**: 2026-02-04
