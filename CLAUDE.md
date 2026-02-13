# Project Instructions → AGENTS.md

이 프로젝트의 통합 지침은 `AGENTS.md`에 있습니다.
모든 AI 도구(Claude Code, Codex, Cursor, Copilot 등)가 동일한 규칙을 따릅니다.

## 지침 소스

| 파일 | 역할 |
|------|------|
| `AGENTS.md` | 통합 지침 (프로젝트 구조, 핵심 규칙, 워크플로우) |
| `.agents/rules/*.md` | 상세 규칙 (자동 로드) |
| `.agents/commands/*.md` | 워크플로우 커맨드 |

## Claude Code 사용자 참고

- `.claude/rules/` → `.agents/rules/` 심볼릭 링크로 자동 로드됩니다
- 프로젝트 구조, 서비스 목록, 전체 컨텍스트는 `AGENTS.md`를 참조하세요
- 하위 프로젝트 작업 시: 해당 프로젝트의 CLAUDE.md 먼저 확인
