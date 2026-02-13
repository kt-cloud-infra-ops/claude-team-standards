# Copilot Instructions

이 프로젝트의 통합 지침은 저장소 루트의 `AGENTS.md`에 있습니다.

## 핵심 규칙 요약

- **코드 스타일**: 불변성 우선, 파일 200-400줄, 함수 50줄 이내
- **테스트**: TDD 필수, 80%+ 커버리지, Unit + Integration + E2E
- **보안**: 시크릿 하드코딩 금지, 입력 검증 필수, SQL Injection/XSS 방지
- **커밋**: `<type>: <description>` (feat, fix, docs, test, refactor, chore, rules, commands)
- **Java**: UTF-8/LF, 하드탭, 120자, K&R 중괄호, PascalCase/camelCase
- **문서**: `docs/` 폴더에 저장, Confluence = Source of Truth, `automations/`·`lessons_learned/` = AI 전용

## 상세 규칙

`.agents/rules/` 디렉토리의 markdown 파일에 상세 규칙이 있습니다.

전체 지침: [AGENTS.md](../AGENTS.md)
