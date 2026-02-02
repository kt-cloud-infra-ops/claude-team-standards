# Claude Team Standards

팀 전체가 일관된 방식으로 Claude Code/Cursor를 사용하기 위한 공유 설정 저장소입니다.

## 목적

- **일관된 코딩 스타일**: 팀 공통 규칙 적용
- **지식 공유**: 학습 내용, 의사결정 기록 공유
- **생산성 향상**: 검증된 슬래시 커맨드 활용

---

## 빠른 시작

### 1. 저장소 클론

```bash
cd ~/Documents
git clone https://github.com/kt-cloud-infra-ops/claude-team-standards.git claude
```

### 2. 워크스페이스 설정

Claude Code 실행 후:

```
/setup-workspace
```

프롬프트에 따라 로컬 프로젝트 경로를 입력하면 `workspace/` 폴더에 심볼릭 링크가 생성됩니다.

### 3. 사용 시작

```bash
cd ~/Documents/claude
claude  # 또는 Cursor에서 폴더 열기
```

---

## 폴더 구조

```
claude/
├── CLAUDE.md                      # Claude에게 주는 지침
├── README.md                      # 이 파일
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
│   ├── claude_automations/        # Claude용 - 자동화 패턴
│   ├── claude_lessons_learned/    # Claude용 - 학습 내용
│   │   ├── java/
│   │   ├── db/
│   │   └── common/
│   ├── decisions/                 # 저장소 운영 ADR
│   ├── ktcloud/                   # 회사 공통 가이드
│   ├── personal/                  # 개인 문서
│   └── temp/                      # 임시 문서
│
└── .claude/
    ├── commands/                  # 슬래시 커맨드
    └── rules/                     # 프로젝트별 규칙
```

### 문서 분류 규칙

| 접두사 | 의미 | Confluence |
|--------|------|------------|
| `claude_` | Claude AI가 참조/활용 | X |
| 없음 | 사람이 보는 문서 | O |

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

> 상세 규칙: `.claude/rules/` 참조

---

## 기여 방법

| 내용 | 저장 위치 |
|------|----------|
| 서비스 문서 | `docs/service/{서비스}/` |
| 학습 내용 | `docs/claude_lessons_learned/` |
| 의사결정 기록 | `docs/decisions/` |
| 자동화 패턴 | `docs/claude_automations/` |
| 슬래시 커맨드 | `.claude/commands/` |

---

## 문의

이슈나 개선사항은 GitHub Issues로 등록해주세요.
