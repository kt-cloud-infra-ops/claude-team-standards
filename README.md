# Claude Team Standards

팀 전체가 일관된 방식으로 Claude Code를 사용하기 위한 공유 설정 저장소입니다.

## 목적

- **일관된 코딩 스타일**: 팀 공통 규칙 적용
- **지식 공유**: 학습 내용, 의사결정 기록 공유
- **생산성 향상**: 검증된 슬래시 커맨드 활용

---

## 빠른 시작

### 1. 저장소 클론

```bash
# 홈 디렉토리의 Documents에 클론 (권장)
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
claude
```

---

## 폴더 구조

```
claude-team-standards/
├── CLAUDE.md              # Claude에게 주는 팀 공통 지침
├── README.md              # 이 파일
├── workspace.example.json # 워크스페이스 설정 예시
├── .gitignore
│
├── workspace/             # 개인별 프로젝트 심볼릭 링크 (git 제외)
│
├── docs/                  # 공유 문서
│   ├── decisions/         # 의사결정 기록 (ADR)
│   ├── learnings/         # 학습 내용
│   ├── automations/       # 자동화 패턴
│   └── projects/          # 프로젝트별 문서
│       └── luppiter_web/  # 예: luppiter_web 문서
│
└── .claude/
    ├── commands/          # 슬래시 커맨드
    └── settings.local.json # 개인 설정 (git 제외)
```

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

> 상세 규칙: `~/.claude/rules/` 참조

---

## 기여 방법

1. 새로운 학습 내용 → `docs/learnings/`에 추가
2. 의사결정 기록 → `docs/decisions/`에 ADR 작성
3. 자동화 패턴 발견 → `docs/automations/`에 추가
4. 슬래시 커맨드 개선 → `.claude/commands/` 수정

---

## 문의

이슈나 개선사항은 GitHub Issues로 등록해주세요.
