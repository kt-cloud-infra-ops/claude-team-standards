# Team Standards

팀 전체가 일관된 방식으로 AI 코딩 에이전트를 사용하기 위한 통합 지침입니다.
이 파일은 도구에 무관하게 (Claude Code, Codex, Cursor, Copilot 등) 모든 AI 에이전트가 읽는 단일 소스입니다.

---

## 프로젝트 구조

```
claude/
├── AGENTS.md                      # 이 파일 — 통합 지침
├── CLAUDE.md                      # Claude Code 호환 포인터
├── README.md                      # 팀원 온보딩 가이드
│
├── docs/
│   ├── service/                   # 서비스별 문서 (Confluence 동기화)
│   │   ├── luppiter/              # Luppiter — 관제 플랫폼
│   │   ├── gaia/                  # Gaia — 인프라 자동화
│   │   ├── hera/                  # Hera — 모니터링 플랫폼
│   │   ├── infrafe/               # InfraFE — 인프라 프론트엔드
│   │   ├── cmdb/                  # CMDB — 구성관리 DB
│   │   └── hermes/                # Hermes — 메시징/알림
│   │
│   ├── automations/        # AI 에이전트용 — 자동화 패턴
│   ├── lessons_learned/    # AI 에이전트용 — 학습 내용
│   ├── support-projects/          # 지원 프로젝트 (Confluence 동기화)
│   ├── decisions/                 # 저장소 운영 ADR
│   ├── ktcloud/                   # 회사 공통 가이드
│   ├── personal/                  # 개인 문서 (사번별)
│   └── temp/                      # 임시 문서 (.gitignore)
│
├── workspace/                     # 하위 프로젝트 심볼릭 링크 (.gitignore)
├── .agents/
│   ├── rules/                     # 상세 규칙 (실제 파일)
│   └── commands/                  # 워크플로우 커맨드 (실제 파일)
└── .claude/
    ├── rules → ../.agents/rules   # 심볼릭 링크 (Claude Code 호환)
    └── commands → ../.agents/commands
```

### 문서 분류

| 폴더 | 대상 | Confluence 동기화 |
|------|------|-------------------|
| `docs/automations/`, `docs/lessons_learned/` | AI 에이전트 참조 | X |
| 그 외 `docs/` | 사람이 보는 문서 | O |

---

## 핵심 원칙

1. **반복 발견 → 자동화**: 반복 작업을 `docs/automations/`에 기록
2. **지식 축적**: 학습 내용을 `docs/lessons_learned/`에 문서화
3. **하위 프로젝트 통합 관리**: 여러 프로젝트의 컨텍스트를 한 곳에서 파악
4. **기존 시스템 영향도 필수 검토**: 새 테이블/엔티티/기능 추가 시 횡단 영향 분석 (`.agents/rules/impact-analysis.md`)

---

## 코드 스타일

### 공통

- **불변성 우선**: 객체 mutation 금지, 항상 새 객체 생성
- **파일 크기**: 200-400줄 권장, 800줄 이내
- **함수 크기**: 50줄 이내
- **중첩 깊이**: 4단계 이내
- **에러 처리**: 모든 예외 상황 명시적 처리, 에러 메시지에 민감 정보 포함 금지
- **입력 검증**: 시스템 경계(사용자 입력, 외부 API)에서 필수
- **하드코딩 금지**: 시크릿, 매직 넘버 사용 금지

### Java 코드 스타일

| 항목 | 규칙 |
|------|------|
| 인코딩/새줄 | UTF-8, LF |
| 들여쓰기 | 하드탭 (4 spaces) |
| 최대 줄 너비 | 120자 |
| 중괄호 | K&R 스타일 |
| Naming | 클래스: PascalCase, 메서드/변수: camelCase, 상수: UPPER_SNAKE_CASE |
| 접두사 | Enum: E, Interface: I |
| 접미사 | Entity, Configuration, Aspect |

### SRE 코딩 규칙

- 타임아웃: 모든 외부 호출에 필수
- 재시도: Transient 에러만, Exponential Backoff
- 로깅: 작업 시작/완료, 외부 API 호출, 에러 스택트레이스
- Health Check: 필수 구현

> 상세: `.agents/rules/coding-style.md`, `docs/lessons_learned/java/`

---

## 테스트

- **최소 커버리지**: 80%
- **TDD 필수**: 테스트 먼저 작성 (RED → GREEN → REFACTOR)
- **테스트 유형**: Unit + Integration + E2E (Playwright) 모두 필요
- **테스트 실패 시**: 구현을 수정, 테스트를 수정하지 않음 (테스트가 틀린 경우 제외)

> 상세: `.agents/rules/testing.md`

---

## 보안

커밋 전 필수 확인:
- 하드코딩된 시크릿 없음 (API 키, 비밀번호, 토큰)
- 모든 사용자 입력 검증됨
- SQL Injection 방지 (파라미터화 쿼리)
- XSS 방지 (HTML 새니타이징)
- 에러 메시지에 민감 정보 미포함

> 상세: `.agents/rules/security.md`

---

## Git 컨벤션

### 커밋 메시지

```
<type>: <description>
```

| Type | 용도 |
|------|------|
| `feat` | 새 기능 |
| `fix` | 버그 수정 |
| `refactor` | 리팩토링 |
| `docs` | 문서 |
| `test` | 테스트 |
| `chore` | 잡일 |
| `rules` | 팀 규칙 변경 |
| `commands` | 워크플로우 커맨드 변경 |

### PR 작성

1. 전체 커밋 히스토리 분석 (최신 커밋만이 아닌 전체)
2. `git diff [base-branch]...HEAD`로 전체 변경 확인
3. 포괄적인 PR 요약 작성
4. 테스트 계획 포함

> 상세: `.agents/rules/git-workflow.md`

---

## 팀 기본룰

### 공유 vs 개인 영역

| 영역 | 위치 | Git 공유 | 변경 시 |
|------|------|---------|---------|
| 팀 규칙 | `.agents/rules/` | O | 리뷰 필요 |
| 워크플로우 커맨드 | `.agents/commands/` | O | 리뷰 필요 |
| 서비스 문서 | `docs/service/` | O | 자유 커밋 |
| 개인 문서 | `docs/personal/{사번}/` | O | 본인만 수정 |
| 워크스페이스 | `workspace/` | X | 개인 설정 |
| 임시 파일 | `docs/temp/` | X | 작업 후 삭제 |

### 규칙 변경 프로세스

`.agents/rules/`, `.agents/commands/`, `AGENTS.md` 변경 시:
1. 변경 작성
2. 영향도 분석 (누가 영향받는가, 동작이 달라지는가)
3. 판정: 경미(바로 커밋) / 일반(팀 채널 공유) / 중요(팀원 확인) / CRITICAL(팀 미팅)

### 금지 사항

1. 인증정보 커밋 금지
2. workspace에 문서 저장 금지
3. 다른 팀원 개인 폴더 수정 금지
4. 규칙 무단 변경 금지

> 상세: `.agents/rules/team-basics.md`

---

## 문서 저장 규칙

| 문서 유형 | 저장 위치 |
|----------|----------|
| 서비스 문서 (Confluence) | `docs/service/{서비스}/` |
| 지원 프로젝트 문서 | `docs/support-projects/{프로젝트}/` |
| 임시 작업 파일 | `docs/temp/` |
| AI 학습 내용 | `docs/lessons_learned/{언어}/` |
| 자동화 패턴 | `docs/automations/` |
| 저장소 운영 ADR | `docs/decisions/` |
| 개인 문서 | `docs/personal/{사번}/` |

> 상세: `.agents/rules/doc-organization.md`

---

## Jira 연동

- 프로젝트: LUPR (유피테르), TECHIOPS26 (인프라옵스개발관리)
- API: REST API v3 사용 (`/rest/api/3/`)
- 인증: Basic Auth (email + API token)
- 이슈 단위: Epic = 1개월, Task = 1주
- A.C. 형식: 마크다운 체크박스 필수

> 상세: `.agents/rules/jira-workflow.md`, `docs/ktcloud/jira/jira-rest-api-guide.md`

---

## 워크플로우 커맨드

`.agents/commands/` 에 정의된 재사용 가능한 워크플로우:

| 커맨드 | 설명 |
|--------|------|
| `/init` | 초기 환경 설정 (Git, Jira 인증) |
| `/setup-workspace` | 워크스페이스 프로젝트 동기화 |
| `/tasks` | Jira + 로컬 TASKS.md 통합 조회 |
| `/wrap` | 세션 마무리 (5가지 병렬 분석) |
| `/status` | 프로젝트 현황 확인 |
| `/plan` | 작업 계획 수립 |
| `/code-review` | 코드 리뷰 |
| `/tdd` | TDD 워크플로우 |
| `/e2e` | Playwright E2E 테스트 |
| `/review-rules` | 공통룰 변경 리뷰 |

사용법: 사용자가 커맨드를 언급하면, `.agents/commands/{커맨드}.md` 파일을 읽고 해당 워크플로우를 실행.

---

## 하위 프로젝트

`workspace/` 폴더에서 심볼릭 링크로 관리:

| 프로젝트 | 설명 | 기술 스택 |
|---------|------|----------|
| luppiter_web | 관제 웹 플랫폼 | Java/Spring, MyBatis, JSP |
| luppiter_scheduler | 스케줄러 | Java/Spring |
| luppiter_morning_report | 모닝 리포트 | Python |
| test_luppiter_inv_api | 인벤토리 API | Spring Boot |
| luppiter_web_e2e | E2E 테스트 | Playwright/TypeScript |

---

## 상세 규칙 참조

`.agents/rules/` 디렉토리에 상세 규칙이 markdown 파일로 존재합니다.
동적 파일 읽기가 가능한 도구는 아래 경로를 직접 참조하세요:

| 파일 | 역할 |
|------|------|
| `team-basics.md` | 팀 기본룰 (공유/개인 영역, 온보딩) |
| `coding-style.md` | 코드 스타일 (불변성, 파일 구조) |
| `testing.md` | TDD 워크플로우, 커버리지 |
| `security.md` | 보안 체크리스트 |
| `git-workflow.md` | 커밋/PR/기능 구현 프로세스 |
| `jira-workflow.md` | Jira 이슈 관리 규칙 |
| `doc-organization.md` | 문서 분류, Obsidian 태그 |
| `impact-analysis.md` | 기존 시스템 영향도 분석 |
| `patterns.md` | 공통 구현 패턴 |
| `performance.md` | 성능 최적화, 모델 선택 |
| `agents.md` | 에이전트 오케스트레이션 |
| `preferences.md` | 사용자 선호 (언어 피드백) |
| `project-docs.md` | 프로젝트 문서 작성 규칙 |

---

## 변경 관리

이 `AGENTS.md` 파일 변경 시:
- 핵심 규칙 인라인 섹션 수정 → 대응하는 `.agents/rules/` 파일도 동기화
- `.agents/rules/` 파일 추가/삭제 → "상세 규칙 참조" 테이블 업데이트
- 워크플로우 커맨드 추가 → "워크플로우 커맨드" 테이블 업데이트

---

*최종 업데이트: 2026-02-13*
