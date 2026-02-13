# Git Workflow

## Commit Message Format

```
<type>: <description>

<optional body>
```

Types: feat, fix, refactor, docs, test, chore, rules, commands

## Pull Request Workflow

When creating PRs:
1. Analyze full commit history (not just latest commit)
2. Use `git diff [base-branch]...HEAD` to see all changes
3. Draft comprehensive PR summary
4. Include test plan with TODOs
5. Push with `-u` flag if new branch

## Feature Implementation Workflow

1. **Plan First**
   - Use `/plan` workflow (or a planner role agent if supported)
   - Identify dependencies and risks
   - Break down into phases

2. **TDD Approach**
   - Use `/tdd` workflow (or a tdd-guide role agent if supported)
   - Write tests first (RED)
   - Implement to pass tests (GREEN)
   - Refactor (IMPROVE)
   - Verify 80%+ coverage

3. **Code Review**
   - Use `/code-review` workflow (or a code-reviewer role agent if supported)
   - Address CRITICAL and HIGH issues
   - Fix MEDIUM issues when possible

4. **Commit & Push**
   - Detailed commit messages
   - Follow conventional commits format

---

## Related Rules

- [testing.md](testing.md) - TDD workflow details, coverage requirements
- [agents.md](agents.md) - planner, tdd-guide, code-reviewer agents
- [security.md](security.md) - Pre-commit security checklist
