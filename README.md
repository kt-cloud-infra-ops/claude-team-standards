# Team Standards

팀 전체가 일관된 방식으로 AI 코딩 에이전트를 사용하기 위한 공유 설정 저장소입니다.
Claude Code, Codex, Cursor, GitHub Copilot 등 도구에 무관하게 동일한 규칙을 적용합니다.

## 목적

- **일관된 코딩 스타일**: 팀 공통 규칙 적용
- **도구 무관**: `AGENTS.md` 단일 소스로 모든 AI 에이전트 지원
- **지식 공유**: 학습 내용, 의사결정 기록 공유
- **생산성 향상**: 검증된 워크플로우 커맨드 활용

---

## 빠른 시작

### 1. 저장소 클론

```bash
cd ~/Documents
git clone https://github.com/kt-cloud-infra-ops/ai-team-standards.git
```

### 2. AI 도구로 열기

```bash
cd ~/Documents/ai-team-standards
claude          # Claude Code
codex           # OpenAI Codex
cursor .        # Cursor
code .          # VS Code + Copilot
```

AI 도구가 `AGENTS.md`를 자동으로 읽어 팀 규칙을 적용합니다.

### 3. 워크스페이스 설정

```
/setup-workspace
```

프롬프트에 따라 로컬 프로젝트 경로를 입력하면 `workspace/` 폴더에 심볼릭 링크가 생성됩니다.

---

## 폴더 구조

```
claude/
├── AGENTS.md                      # 통합 AI 지침 (모든 도구 공용)
├── CLAUDE.md                      # Claude Code 호환 포인터
├── README.md                      # 이 파일 (온보딩)
├── workspace/                     # 개인별 프로젝트 심볼릭 링크 (git 제외)
│
├── docs/
│   ├── service/                   # 서비스별 문서 (Confluence 동기화)
│   │   └── luppiter/              # Luppiter 서비스
│   │       ├── architecture/      # 시스템 아키텍처
│   │       ├── features/          # 주요 기능 명세
│   │       ├── sop/               # 운영 절차서
│   │       ├── luppiter_scheduler/
│   │       └── luppiter_web/
│   │   # 향후: gaia/, hera/, infrafe/
│   │
│   ├── automations/        # AI 에이전트용 — 자동화 패턴
│   ├── lessons_learned/    # AI 에이전트용 — 학습 내용
│   │   ├── java/
│   │   ├── db/
│   │   └── common/
│   ├── decisions/                 # 저장소 운영 ADR
│   ├── ktcloud/                   # 회사 공통 가이드
│   ├── personal/                  # 개인 문서
│   └── temp/                      # 임시 문서
│
├── .agents/
│   ├── commands/                  # 워크플로우 커맨드
│   └── rules/                     # 팀 규칙
└── .claude/
    ├── commands → ../.agents/commands  # 심볼릭 링크
    └── rules → ../.agents/rules       # 심볼릭 링크
```

### 문서 분류

| 폴더 | 대상 | Confluence |
|------|------|------------|
| `docs/automations/`, `docs/lessons_learned/` | AI 에이전트 참조 | X |
| 그 외 `docs/` | 사람이 보는 문서 | O |

---

## 주요 슬래시 커맨드

| 커맨드 | 설명 |
|--------|------|
| `/setup-workspace` | 워크스페이스 프로젝트 동기화 |
| `/status` | 프로젝트 현황 확인 |
| `/wrap` | 세션 마무리 (인사이트 추출) |
| `/plan` | 구현 계획 수립 |
| `/tdd` | 테스트 주도 개발 |
| `/code-review` | 코드 리뷰 |
| `/review-rules` | 공통룰 변경 리뷰 |

---

## 팀 규칙

### 코딩 스타일

- **불변성 우선**: 객체 mutation 금지, 새 객체 생성
- **파일 크기**: 200-400줄 권장, 800줄 이내
- **에러 처리**: 모든 예외 상황 명시적 처리

### 테스트

- **최소 커버리지**: 80%
- **TDD 필수**: 테스트 먼저 작성

### 보안

- **시크릿 금지**: 하드코딩된 API 키, 비밀번호 절대 금지
- **입력 검증**: 모든 사용자 입력 검증 필수

> 상세 규칙: `.agents/rules/` 참조

---

## 개인 폴더 설정

최초 사용 시 개인 폴더를 생성합니다:

```bash
mkdir -p docs/personal/{사번}/worklog/2026
```

개인 작업일지, 메모 등은 이 폴더에 자유롭게 저장합니다.
다른 팀원의 폴더는 수정하지 않습니다.

---

## 규칙 변경

`.agents/rules/`, `.agents/commands/`, `AGENTS.md` 변경은 팀 전체에 영향을 줍니다.
변경 시 `/review-rules`를 실행하여 영향도를 확인하고, 판정에 따라 팀원과 공유합니다.

> 상세: `.agents/rules/team-basics.md`

---

## 기여 방법

| 내용 | 저장 위치 |
|------|----------|
| 서비스 문서 | `docs/service/{서비스}/` |
| 학습 내용 | `docs/lessons_learned/` |
| 의사결정 기록 | `docs/decisions/` |
| 자동화 패턴 | `docs/automations/` |
| 슬래시 커맨드 | `.agents/commands/` |

---

## 문의

이슈나 개선사항은 GitHub Issues로 등록해주세요.
