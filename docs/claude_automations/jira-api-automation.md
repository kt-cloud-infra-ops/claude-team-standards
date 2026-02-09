# Jira API 자동화 패턴

MCP Atlassian 도구 한계 시 curl 직접 호출 패턴.

---

## 언제 사용하나?

MCP 도구에 없는 기능:
- 이슈 수정 (필드 업데이트)
- 상태 변경 (transition)
- 코멘트 삭제
- 이슈 삭제

---

## 인증 헤더

```bash
AUTH=$(echo -n 'jiwoong.kim@kt.com:API_TOKEN' | base64)
```

인증 정보 위치: `~/.claude.json` > `mcpServers` > `atlassian` > `env`

---

## 핵심 패턴

### 1. 이슈 수정

```bash
curl -s -X PUT \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d '{"fields": {"필드ID": "값"}}' \
  "https://ktcloud.atlassian.net/rest/api/3/issue/{issueKey}"
```

### 2. 상태 변경

```bash
# 1단계: 가능한 transition 조회
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  "https://ktcloud.atlassian.net/rest/api/3/issue/{issueKey}/transitions"

# 2단계: transition 실행
curl -s -X POST \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d '{"transition": {"id": "4"}}' \
  "https://ktcloud.atlassian.net/rest/api/3/issue/{issueKey}/transitions"
```

### 3. 필드 ID 찾기

```bash
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  "https://ktcloud.atlassian.net/rest/api/3/field" | jq '.[] | select(.name | test("검색어"; "i")) | {id, name}'
```

### 4. 수정 가능 필드 확인

```bash
curl -s -X GET \
  -H "Authorization: Basic $AUTH" \
  "https://ktcloud.atlassian.net/rest/api/3/issue/{issueKey}/editmeta" | jq '.fields | keys'
```

---

## TECHIOPS26 프로젝트 필드 ID

| 필드 | ID |
|------|-----|
| A.C. | `customfield_14516` |
| Start date | `customfield_10015` |
| Due date | `duedate` |

---

## 배치 업데이트

```bash
for key in 253 254 255; do
  curl -s -X PUT \
    -H "Authorization: Basic $AUTH" \
    -H "Content-Type: application/json" \
    -d '{"fields": {"duedate": "2026-02-28"}}' \
    "https://ktcloud.atlassian.net/rest/api/3/issue/TECHIOPS26-$key" -o /dev/null
  echo "TECHIOPS26-$key done"
done
```

---

## 주의사항

1. **API 버전**: `/rest/api/3/` 사용 (v2 deprecated)
2. **search API 변경**: `/rest/api/3/search` → `/rest/api/3/search/jql` (POST)
3. **A.C. 형식**: 반드시 마크다운 체크박스 사용 (ADF 사용 금지)

### A.C. 형식 (ADF - taskList 사용)

API는 Atlassian Document Format 사용. UI에서는 체크박스로 렌더링됨.

### 개발 단계 표준 순서 (필수)

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

**순서 중요**: 구현 → 단위 테스트 → 코드 리뷰 → 통합 테스트

---

**최종 업데이트**: 2026-02-04
