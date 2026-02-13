# Agent Orchestration

## Core Principle

- Team-standard execution must be reproducible from this repository alone.
- Required sources: `AGENTS.md`, `.agents/rules/`, `.agents/commands/`.
- Tool-specific home paths (`~/.claude/...`, `~/.codex/...`) are optional accelerators only.

## Role-Based Agents

| Role | Purpose | When to Use |
|------|---------|-------------|
| planner | Implementation planning | Complex features, refactoring |
| architect | System design | Architectural decisions |
| tdd-guide | Test-driven development | New features, bug fixes |
| code-reviewer | Code review | After writing code |
| security-reviewer | Security analysis | Before commits |
| build-error-resolver | Fix build errors | When build fails |
| e2e-runner | E2E testing | Critical user flows |
| refactor-cleaner | Dead code cleanup | Code maintenance |
| doc-updater | Documentation | Updating docs |

If a tool supports sub-agents, map these role names to the tool's equivalent feature.
If not, execute the same workflow directly using `.agents/commands/` and `.agents/rules/`.

## Immediate Agent Usage

No user prompt needed:
1. Complex feature requests - Use **planner** agent
2. Code just written/modified - Use **code-reviewer** agent
3. Bug fix or new feature - Use **tdd-guide** agent
4. Architectural decision - Use **architect** agent

## Parallel Task Execution

ALWAYS use parallel Task execution for independent operations:

```markdown
# GOOD: Parallel execution
Launch 3 agents in parallel:
1. Agent 1: Security analysis of auth.ts
2. Agent 2: Performance review of cache system
3. Agent 3: Type checking of utils.ts

# BAD: Sequential when unnecessary
First agent 1, then agent 2, then agent 3
```

## Multi-Perspective Analysis

For complex problems, use split role sub-agents:
- Factual reviewer
- Senior engineer
- Security expert
- Consistency reviewer
- Redundancy checker

---

## Related Rules

- [performance.md](performance.md) - Model selection guidance
- [git-workflow.md](git-workflow.md) - Agent usage in feature workflow
- [testing.md](testing.md) - tdd-guide, e2e-runner context
- [security.md](security.md) - security-reviewer context
