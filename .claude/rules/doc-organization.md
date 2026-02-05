# Document Organization Rules

## CRITICAL: 공통 설정 변경 시 동기화 필수

**공통 의사결정/규칙 변경 요청 시:**
1. 반드시 현재 값 확인
2. 변경 내용 명확히 파악
3. 관련된 모든 위치 업데이트:
   - `~/.claude/rules/` (개인 홈)
   - `.claude/rules/` (프로젝트 repo)
   - `CLAUDE.md` (참조하는 경우)

---

## 폴더 구분 (3가지)

| 폴더 | 용도 | 대상 |
|------|------|------|
| `workspace/` | **코드만** | .java, .py, .js 등 |
| `docs/service/` | **Confluence 동기화** (사람용) | 아키텍처, SOP, 히스토리, 화면 명세 |
| `docs/claude_*` | **Claude 전용** | lessons_learned, automations |
| `docs/service/*/claude_*` | **Claude 전용** (프로젝트별) | temp, 구현 가이드 |

**절대 workspace에 문서를 저장하지 않음!**

---

## 폴더 구조

```
docs/
├── service/                 # Confluence 동기화 대상 (사람용)
│   └── luppiter/
│       ├── architecture/    # → [LUPPITER] 서비스 아키텍처
│       ├── features/        # → [LUPPITER] 주요 기능 명세서
│       ├── history/         # → [LUPPITER] History
│       ├── sop/             # → [LUPPITER] SOP
│       ├── luppiter_scheduler/
│       │   ├── decisions/   # → [LUPPITER] History (설계 결정)
│       │   └── claude_temp/ # Claude 전용 (Confluence X)
│       ├── luppiter_web/
│       │   ├── screens/     # → [LUPPITER] 주요 기능 명세서 > 화면 명세
│       │   ├── api/         # → [LUPPITER] 주요 기능 명세서 > API
│       │   └── claude_temp/ # Claude 전용 (Confluence X)
│       └── luppiter_morning_report/
│
├── support-projects/        # 지원 프로젝트 (서비스 횡단)
│   └── next-observability/  # → 05. 지원 프로젝트
│
├── claude_lessons_learned/  # Claude 학습 내용
│   ├── java/
│   ├── db/
│   └── common/
│
├── claude_automations/      # 자동화 패턴
│
├── decisions/               # 팀 의사결정 (ADR)
│
└── temp/                    # 임시 문서
```

---

## Confluence 동기화 규칙

### 동기화 대상 (`docs/service/luppiter/`)

| 로컬 폴더 | Confluence 위치 | 설명 |
|----------|----------------|------|
| `architecture/` | [LUPPITER] 서비스 아키텍처 | 시스템 구조, 권한 체계 |
| `features/` | [LUPPITER] 주요 기능 명세서 | API, 주요 기능 설명 |
| `history/` | [LUPPITER] History | 트러블슈팅, 장애 대응 |
| `sop/` | [LUPPITER] SOP | 운영 절차 |
| `luppiter_web/screens/` | [LUPPITER] 주요 기능 명세서 > 화면 명세 | 화면 기능 명세 |
| `luppiter_web/api/` | [LUPPITER] 주요 기능 명세서 > API | API 명세 |

### 동기화 절차

1. **변경 전 확인** - Confluence와 로컬 양쪽 확인
2. **사람이 의사결정** - 충돌 시 수동 머지
3. **업로드/다운로드** - Claude MCP 도구 사용

### 동기화 대상 (`docs/support-projects/`)

| 로컬 폴더 | Confluence 위치 | 설명 |
|----------|----------------|------|
| `next-observability/` | 05. 지원 프로젝트 | O11y 연동 |

### Confluence 스페이스 매핑

- **스페이스**: [기술] InfraOps개발팀 (CL23)
- **URL**: https://ktcloud.atlassian.net/wiki/spaces/CL23/overview

---

## Claude 전용 문서 (Confluence X)

`claude_` prefix 사용:

| 폴더/파일 | 용도 |
|----------|------|
| `docs/claude_lessons_learned/` | 코딩 스타일, 디자인 패턴 |
| `docs/claude_automations/` | 자동화 패턴 |
| `docs/service/*/claude_temp/` | 프로젝트별 임시 작업 파일 |
| `claude_*.md` 파일 | 구현 가이드, 분석 문서 |

---

## 자동 저장 규칙

Claude는 작업 컨텍스트 기반 자동 결정:

| 작업 유형 | 저장 위치 |
|----------|----------|
| 프로젝트 설계/결정 | `docs/service/luppiter/<프로젝트>/decisions/` |
| 트러블슈팅 완료 | `docs/service/luppiter/history/` |
| 화면 명세 | `docs/service/luppiter/luppiter_web/screens/` |
| 학습 내용 | `docs/claude_lessons_learned/<언어>/` |
| 자동화 패턴 | `docs/claude_automations/` |
| 팀 의사결정 | `docs/decisions/` |
| 임시 작업 | `docs/service/luppiter/<프로젝트>/claude_temp/` |

---

## Naming Conventions

- kebab-case: `design-patterns.md`
- 번호 없음: ~~004-design-patterns.md~~
- Claude 전용: `claude_` prefix 사용
- 설명적 이름 사용

---

## Related Rules

- [git-workflow.md](git-workflow.md) - Commit docs with code changes
- [hooks.md](hooks.md) - Doc blocker hook configuration
