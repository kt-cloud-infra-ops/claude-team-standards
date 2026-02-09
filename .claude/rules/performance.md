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
