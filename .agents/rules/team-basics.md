# Team Basics

## 저장소 목적

이 저장소는 **팀 공통 AI 에이전트 설정 + 문서 허브**입니다.
코드 프로젝트가 아니라 **팀 표준과 지식을 공유**하는 저장소입니다.
통합 지침은 `AGENTS.md`에, 상세 규칙은 `.agents/rules/`에 있습니다.

---

## 공유 vs 개인 영역

| 영역 | 위치 | Git 공유 | 변경 시 |
|------|------|---------|---------|
| **팀 규칙** | `.agents/rules/` | O | `/review-rules`로 리뷰 |
| **슬래시 커맨드** | `.agents/commands/` | O | `/review-rules`로 리뷰 |
| **통합 지침** | `AGENTS.md` | O | `/review-rules`로 리뷰 |
| **서비스 문서** | `docs/service/` | O | 자유 커밋 |
| **학습 내용** | `docs/lessons_learned/` | O | 자유 커밋 |
| **개인 문서** | `docs/personal/{사번}/` | O | 본인만 수정 |
| **워크스페이스** | `workspace/` | X (.gitignore) | 개인 설정 |
| **Jira 캐시** | `.claude/cache/` | X (.gitignore) | 자동 관리 |
| **임시 파일** | `docs/temp/` | X (.gitignore) | 작업 후 삭제 |

---

## 규칙 변경 프로세스

`.agents/rules/`, `.agents/commands/`, `AGENTS.md` 변경은 **팀 전원에게 영향**을 줍니다.

1. 변경 작성
2. `/review-rules` 실행 → 영향도 분석
3. 리뷰 판정에 따라 처리:
   - **경미** (오타/문서): 바로 커밋
   - **일반** (기존 룰 보완): 팀 채널 공유 후 커밋
   - **중요** (신규 룰/동작 변경): 팀원 확인 후 커밋
   - **CRITICAL** (워크플로우 변경): 팀 미팅에서 논의

커밋 메시지: `rules: <설명>` 또는 `commands: <설명>`

---

## 개인 폴더

각 팀원은 `docs/personal/{사번}/` 폴더를 사용합니다.

```
docs/personal/
├── 82253890/          # 김지웅
│   └── worklog/       # 작업일지
│       └── 2026/
│           └── 02/
├── {사번}/            # 다른 팀원
│   └── ...
└── README.md
```

규칙:
- **본인 폴더만 수정** (다른 팀원 폴더 수정 금지)
- Obsidian 태그에 `personal/{사번}` 포함
- 작업일지, 개인 메모 등 자유 구성

---

## 커밋 컨벤션

```
<type>: <설명>

types: feat, fix, refactor, docs, test, chore, rules, commands
```

| Type | 용도 | 예시 |
|------|------|------|
| `docs` | 서비스 문서, 학습 내용 | `docs: Luppiter SOP 추가` |
| `rules` | 팀 규칙 변경 | `rules: 보안 체크리스트 추가` |
| `commands` | 슬래시 커맨드 변경 | `commands: /deploy 커맨드 추가` |

---

## 금지 사항

1. **인증정보 커밋 금지**: API 키, 비밀번호, 토큰 (`~/.jira-credentials.json` 등은 홈 디렉토리에)
2. **workspace에 문서 저장 금지**: workspace는 코드 프로젝트 심볼릭 링크 전용
3. **다른 팀원 개인 폴더 수정 금지**: `docs/personal/{남의사번}/`
4. **규칙 무단 변경 금지**: `.agents/rules/` 변경 시 반드시 `/review-rules` 거치기

---

## 온보딩 순서

1. `git clone` → `~/Documents/ai-team-standards`
2. Claude Code에서 `/init` → Git/Jira 인증 설정
3. `/setup-workspace` → 개인 프로젝트 심볼릭 링크
4. `docs/personal/{사번}/` 폴더 생성
5. `/tasks` → 할 일 확인 후 작업 시작

---

## Related Rules

- [doc-organization.md](doc-organization.md) - 문서 조직 규칙
- [git-workflow.md](git-workflow.md) - Git 커밋/PR 워크플로우
- [security.md](security.md) - 보안 가이드라인
