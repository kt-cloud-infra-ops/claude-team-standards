# Document Organization Rules

## Rules 관리 원칙

| 위치 | 역할 | 내용 |
|------|------|------|
| `.claude/rules/` (프로젝트) | **팀 표준** (Git 공유) | 코딩, 테스트, 보안, 워크플로우 등 11개 |
| `~/.claude/rules/` (개인) | **개인 환경 설정만** | hooks.md (개인 IDE/설정 의존) |
| `CLAUDE.md` | **프로젝트 개요** | 구조, 슬래시 커맨드, 코딩 가이드 요약 |

**규칙 변경 시**: `.claude/rules/` 수정 → Git commit으로 팀 공유

---

## 폴더 구분

| 폴더 | 용도 | 대상 |
|------|------|------|
| `workspace/` | **코드만** | .java, .py, .js 등 |
| `docs/service/` | **서비스별 TASKS.md** | Jira 연동용 태스크 |
| `docs/temp/` | **임시 작업 문서** | 작업 중 문서, Confluence 업로드 전 |
| `docs/claude_*` | **Claude 전용** | lessons_learned, automations |

**절대 workspace에 문서를 저장하지 않음!**

---

## 폴더 구조

```
docs/
├── service/                 # 서비스별 TASKS.md만
│   ├── luppiter/
│   │   └── TASKS.md
│   ├── gaia/
│   │   └── TASKS.md
│   └── ...
│
├── temp/                    # 임시 작업 문서
│
├── claude_lessons_learned/  # Claude 학습 내용
│
├── claude_automations/      # 자동화 패턴
│
├── decisions/               # 팀 의사결정 (ADR)
│
└── ktcloud/                 # 회사 공통 가이드
```

---

## Confluence 운영 규칙

### 핵심 원칙

- **Confluence = Source of Truth** (메인 문서)
- **로컬 = 작업용 임시 문서** (docs/temp/)
- 작업 완료 후 Confluence 업로드 → 로컬 삭제

### Confluence 작업 흐름

1. **문서 작성**: `docs/temp/`에 임시 작성
2. **Confluence 업로드**: REST API로 직접 업로드
3. **로컬 삭제**: 업로드 완료 후 삭제

### Confluence 스페이스

- **스페이스**: [기술] InfraOps개발팀 (CL23)
- **URL**: https://ktcloud.atlassian.net/wiki/spaces/CL23/overview

---

## Claude 전용 문서 (Confluence X)

`claude_` prefix 사용:

| 폴더/파일 | 용도 |
|----------|------|
| `docs/claude_lessons_learned/` | 코딩 스타일, 디자인 패턴 |
| `docs/claude_automations/` | 자동화 패턴 |

---

## TASKS.md 관리

서비스별 `docs/service/{서비스}/TASKS.md`:
- Jira 이슈와 연동
- `/tasks` 커맨드로 조회
- 로컬에서만 관리 (Confluence X)

---

## 자동 저장 규칙

| 작업 유형 | 저장 위치 |
|----------|----------|
| 임시 작업/분석 | `docs/temp/` |
| 학습 내용 | `docs/claude_lessons_learned/<언어>/` |
| 자동화 패턴 | `docs/claude_automations/` |
| 팀 의사결정 | `docs/decisions/` |
| **최종 문서** | **Confluence 직접 업로드** |

---

## Naming Conventions

- kebab-case: `design-patterns.md`
- Claude 전용: `claude_` prefix 사용
- 설명적 이름 사용

---

## Related Rules

- [jira-workflow.md](jira-workflow.md) - Jira 워크플로우 규칙
- [project-docs.md](project-docs.md) - 프로젝트 문서 작성 규칙
