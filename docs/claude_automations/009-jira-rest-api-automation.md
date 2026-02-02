# 009: Jira REST API 자동화 패턴

## 개요

Jira MCP 도구의 한계를 REST API 직접 호출로 우회하는 자동화 패턴입니다.

**발견일**: 2026-02-02
**우선순위**: HIGH
**상태**: Active

---

## 문제 상황

Jira MCP는 다음 기능을 지원하지 않음:
- 이슈 필드 업데이트 (duedate, description, 커스텀 필드)
- 상태 전환 (transitions)
- 에픽 링크 설정
- 이슈 삭제

---

## 해결 패턴

### 1. 인증 정보 로드

`~/.claude.json`에서 Atlassian 인증 정보 추출:

```python
import json
from pathlib import Path
import base64

def load_jira_auth():
    config_path = Path.home() / '.claude.json'
    config = json.loads(config_path.read_text())

    env = config['mcpServers']['atlassian']['env']
    return {
        'base_url': env['ATLASSIAN_BASE_URL'],
        'email': env['ATLASSIAN_EMAIL'],
        'token': env['ATLASSIAN_API_TOKEN']
    }
```

### 2. REST API 호출

```python
import requests

class JiraRestAPI:
    def __init__(self):
        auth = load_jira_auth()
        self.base_url = auth['base_url']
        self.auth = (auth['email'], auth['token'])
        self.headers = {'Content-Type': 'application/json'}

    def update_issue(self, issue_key: str, fields: dict):
        """이슈 필드 업데이트"""
        url = f"{self.base_url}/rest/api/3/issue/{issue_key}"
        response = requests.put(
            url,
            auth=self.auth,
            headers=self.headers,
            json={'fields': fields}
        )
        response.raise_for_status()
        return response

    def transition_issue(self, issue_key: str, transition_id: str):
        """이슈 상태 전환"""
        url = f"{self.base_url}/rest/api/3/issue/{issue_key}/transitions"
        response = requests.post(
            url,
            auth=self.auth,
            headers=self.headers,
            json={'transition': {'id': transition_id}}
        )
        response.raise_for_status()
        return response

    def get_transitions(self, issue_key: str):
        """가능한 상태 전환 목록 조회"""
        url = f"{self.base_url}/rest/api/3/issue/{issue_key}/transitions"
        response = requests.get(url, auth=self.auth)
        response.raise_for_status()
        return response.json()['transitions']
```

---

## 사용 예시

### 기한 설정

```python
jira = JiraRestAPI()
jira.update_issue('TECHIOPS26-213', {
    'duedate': '2026-02-09'
})
```

### 에픽 링크 설정

```python
jira.update_issue('TECHIOPS26-213', {
    'customfield_10014': 'TECHIOPS26-35'  # Epic Link 필드
})
```

### 상태 전환 (In Progress)

```python
# 1. 가능한 전환 확인
transitions = jira.get_transitions('TECHIOPS26-213')
for t in transitions:
    print(f"{t['id']}: {t['name']}")

# 2. 전환 실행
jira.transition_issue('TECHIOPS26-213', '4')  # In Progress
```

### ADF 형식 체크박스로 description 업데이트

```python
description_adf = {
    "type": "doc",
    "version": 1,
    "content": [
        {
            "type": "taskList",
            "attrs": {"localId": "tasks"},
            "content": [
                {
                    "type": "taskItem",
                    "attrs": {"localId": "t1", "state": "TODO"},
                    "content": [{"type": "text", "text": "첫 번째 할 일"}]
                },
                {
                    "type": "taskItem",
                    "attrs": {"localId": "t2", "state": "TODO"},
                    "content": [{"type": "text", "text": "두 번째 할 일"}]
                }
            ]
        }
    ]
}

jira.update_issue('TECHIOPS26-213', {
    'description': description_adf
})
```

---

## 월별 이슈 복사 패턴

매월 반복되는 기성 이슈 등을 자동 복사:

```python
def copy_monthly_issue(source_key: str, new_month: str):
    """월별 반복 이슈 복사"""
    from mcp_atlassian import read_jira_issue, create_jira_issue

    # 1. 원본 이슈 조회 (MCP 사용)
    source = read_jira_issue(source_key)

    # 2. 새 이슈 생성 (MCP 사용)
    new_issue = create_jira_issue(
        projectKey=source['fields']['project']['key'],
        issueType=source['fields']['issuetype']['name'],
        summary=source['fields']['summary'].replace('12월', new_month),
        assignee=source['fields']['assignee']['accountId']
    )

    # 3. 추가 필드 업데이트 (REST API)
    jira = JiraRestAPI()

    # 에픽 링크
    if source['fields'].get('customfield_10014'):
        jira.update_issue(new_issue['key'], {
            'customfield_10014': source['fields']['customfield_10014']
        })

    # 기한 (원본 + 1달)
    # ... 날짜 계산 로직

    # 체크박스 초기화
    # ... ADF 생성 로직

    return new_issue['key']
```

---

## KT Cloud Jira 참고 정보

### 프로젝트
- `TECHIOPS26`: 기술운영 2026

### 상태 전환 ID (TECHIOPS26)
| ID | 상태 |
|----|------|
| 2 | Backlog(백로그) |
| 3 | To Do(할일) |
| 4 | In Progress(진행 중) |
| 5 | In Review(검토 중) |
| 6 | Done(완료) |
| 7 | Cancel(취소) |

### 주요 커스텀 필드
| 필드 ID | 이름 |
|---------|------|
| customfield_10014 | Epic Link |
| customfield_10302 | Acceptance Criteria |
| customfield_14516 | A.C.(Acceptance Criteria) |

---

## 관련 문서

- [MCP Tools Guide](../claude_lessons_learned/common/mcp-tools-guide.md)
- [Jira REST API 공식 문서](https://developer.atlassian.com/cloud/jira/platform/rest/v3/)
