# 프로젝트 문서 작성 규칙

서비스 내 프로젝트 문서 작성 시 따르는 규칙입니다.

## 프로젝트 문서 위치

```
docs/service/{서비스}/projects/{프로젝트}/
```

## 필수 파일

### 1. README.md

```markdown
# {프로젝트명}

{프로젝트 설명}

## 기술 스택

| 항목 | 내용 |
|------|------|
| 언어 | Java 17 |
| 프레임워크 | Spring Boot 3.x |
| 빌드 | Gradle |
| DB | PostgreSQL |

## 주요 기능

- 기능 1
- 기능 2

## 관련 문서

- [설계 문서](./feature-design.md)
- [API 문서](./api/)

---

**최종 업데이트**: YYYY-MM-DD
```

### 2. decisions/ 폴더

프로젝트 레벨 설계 결정 (ADR) 저장

```
decisions/
├── 001-architecture-decision.md
├── 002-database-schema.md
└── ...
```

## 선택적 폴더

| 폴더 | 용도 | 대상 |
|------|------|------|
| `api/` | API 문서 | 웹/API 프로젝트 |
| `screens/` | 화면 명세 | 웹 프로젝트 |
| `batch/` | 배치 작업 문서 | 스케줄러 |
| `integrations/` | 연동 문서 | 외부 시스템 연동 |

## Confluence 동기화

- `claude_` 접두사 없는 파일만 동기화 대상
- 임시 작업 파일은 `docs/temp/`에 저장 (프로젝트 폴더 X)

## 프로젝트 추가 체크리스트

- [ ] `projects/{프로젝트}/README.md` 생성
- [ ] `projects/{프로젝트}/decisions/` 폴더 생성
- [ ] 서비스 `README.md`의 프로젝트 구성 테이블 업데이트
- [ ] 필요시 추가 폴더 생성 (api/, screens/ 등)

## 프로젝트명 규칙

- 서비스 접두사 제거: `luppiter_scheduler` → `scheduler`
- 소문자 + 언더스코어: `morning_report`
- 짧고 명확하게: `web`, `api`, `scheduler`

---

## Related Rules

- [doc-organization.md](doc-organization.md) - 문서 조직 규칙
