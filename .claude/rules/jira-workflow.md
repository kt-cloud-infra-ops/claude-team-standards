# Jira Workflow Rules

## CRITICAL: "지라/Jira" 키워드 감지

사용자가 "지라", "Jira", "LUPR-", "TECHIOPS26-" 키워드를 사용하면:

1. **먼저 읽기**: `docs/ktcloud/jira/jira-rest-api-guide.md`
2. 가이드의 필드 ID, 상태 Transition ID, A.C. 형식을 따른다
3. MCP Atlassian 도구 대신 curl REST API를 사용한다

---

## 로컬 캐시 (토큰 절약)

### 캐시 위치

```
.claude/cache/jira/
├── issues/           # 이슈별 캐시 ({KEY}.json)
└── searches/         # JQL 검색 캐시 ({hash}.json)
```

### 캐시 전략

| 작업 | TTL | 갱신 조건 |
|------|-----|----------|
| 이슈 조회 | 60분 | 수정 직후 즉시 갱신 |
| JQL 검색 | 30분 | TTL 만료 시 |
| 수정/생성/전환 후 | - | 해당 이슈 캐시 자동 갱신 |

### 캐시 파일 형식

```json
{
  "key": "LUPR-683",
  "cached_at": "2026-02-06T14:30:00+09:00",
  "ttl_minutes": 60,
  "data": { ... }
}
```

---

## 팀 구조

- **보고자(Reporter)**: 팀장 (김정남/bill.kim) — 모든 이슈 공통
- **담당자(Assignee)**: 실제 작업자
- **In Review**: 팀장(보고자) 검토 단계

---

## 이슈 생성/수정 규칙

### 이슈 생성 시 필수 필드

| 필드 | 값 | 비고 |
|------|-----|------|
| **reporter** | bill.kim (accountId: 712020:1253fda5-0458-4f4d-836a-2646b0576e3c) | 항상 팀장 |
| **assignee** | 실제 작업자 accountId | 사용자에게 확인 |

### 상태별 엄격도

| 상태 | 엄격도 | 필수 항목 |
|------|--------|----------|
| **Backlog** | 러프 | Summary, 대략적 Description |
| **To Do** | 상세 | Summary, Description, A.C., Start/Due date, Epic Link |
| **In Progress** | 엄격 | 위 전부 + 구체적 A.C. 체크박스 |

### A.C. 형식 - 반드시 마크다운 체크박스

```markdown
### 요구사항
- [ ] 구체적 완료 기준 1

### 개발 단계
- [ ] 요구사항 분석
- [ ] 설계
- [ ] 구현
- [ ] 단위 테스트
- [ ] 코드 리뷰
- [ ] 통합 테스트
```

### 부족하면 반드시 물어본다

- Summary/Description/A.C. 부족 시 사용자에게 질문
- 설계 내용 없으면 캐물어서 작성
- "개발 완료" 같은 모호한 A.C. 금지 → 구체적 항목으로 제안

---

## 이슈 조회 시 점검

| 항목 | 조치 |
|------|------|
| A.C. 형식 | 체크박스(taskList) 아니면 변환 |
| A.C. 내용 | 부족하면 보완 제안 |
| A.C. 개발 단계 | 없으면 추가 (분석→설계→구현→테스트→리뷰→통합) |
| 보고자 | 팀장(bill.kim)인지 확인 |
| Start/Due date | 없으면 설정 |
| Epic Link | 없으면 연결 |

---

## 태스크 완료 처리 4단계

1. **A.C. 내용 검토** → 부족하면 보완 제안
2. **A.C. 체크박스 완료** → 모든 taskItem state를 DONE
3. **Description 체크박스 완료** → 모든 taskItem state를 DONE
4. **상태 변경** → In Review(5) 또는 Done(6)

---

## 이슈 단위 기준

| 유형 | 기간 |
|------|------|
| Epic | 1개월 |
| Task | 1주 |

---

## Related Rules

- [doc-organization.md](doc-organization.md) - 문서 저장 규칙
