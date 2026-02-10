# Performance Optimization

## Model Selection Strategy

**Haiku 4.5** (90% of Sonnet capability, 3x cost savings):
- Lightweight agents with frequent invocation
- Pair programming and code generation
- Worker agents in multi-agent systems

**Sonnet 4.5** (Best coding model):
- Main development work
- Orchestrating multi-agent workflows
- Complex coding tasks

**Opus 4.5** (Deepest reasoning):
- Complex architectural decisions
- Maximum reasoning requirements
- Research and analysis tasks

## Skill Model Mapping

스킬(슬래시 커맨드) 실행 시 Task 도구로 위임할 때 아래 모델을 사용:

| 모델 | 스킬 | 이유 |
|------|------|------|
| **haiku** | `/tasks`, `/status`, `/init`, `/setup-workspace`, `/create-service`, `/add-project` | 단순 조회/파일 생성 |
| **sonnet** | `/code-review`, `/tdd`, `/build-fix`, `/refactor-clean`, `/test-coverage`, `/e2e`, `/update-docs`, `/update-codemaps` | 일반 코딩/분석 |
| **opus** | `/plan`, `/learn`, `/wrap`, `/session-insights` | 심층 분석/추론 |

각 스킬 파일의 frontmatter에 `model:` 필드로 명시되어 있음.

## Task 위임 모델 원칙

스킬 외에도 Task 도구로 작업을 위임할 때 동일 원칙 적용:

| 작업 유형 | 모델 | 예시 |
|----------|------|------|
| 외부 API 조회 → 로컬 저장 | haiku | Confluence 동기화, Jira 조회, 인벤토리 갱신 |
| 데이터 분석/편집/의사결정 | sonnet/opus | 내용 검토, 문서 작성, 코드 변경점 분석 |

**혼합 사용 패턴**: 조회(haiku) → 분석/편집(메인 모델) → 업로드(haiku)

## Context Window Management

Avoid last 20% of context window for:
- Large-scale refactoring
- Feature implementation spanning multiple files
- Debugging complex interactions

Lower context sensitivity tasks:
- Single-file edits
- Independent utility creation
- Documentation updates
- Simple bug fixes

## Ultrathink + Plan Mode

For complex tasks requiring deep reasoning:
1. Use `ultrathink` for enhanced thinking
2. Enable **Plan Mode** for structured approach
3. "Rev the engine" with multiple critique rounds
4. Use split role sub-agents for diverse analysis

## Build Troubleshooting

If build fails:
1. Use **build-error-resolver** agent
2. Analyze error messages
3. Fix incrementally
4. Verify after each fix

---

## Related Rules

- [agents.md](agents.md) - Agent list, parallel execution patterns
- [hooks.md](hooks.md) - Auto-accept permissions strategy
