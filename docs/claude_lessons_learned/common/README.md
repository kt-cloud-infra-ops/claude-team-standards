# Common Guides & Learning Resources

Cross-language and cross-project guides that apply to all teams at KT Cloud.

## Documents

### System & Process

#### [Rule System Architecture](rule-system-architecture.md)
**Type**: System Architecture | **Complexity**: Beginner
**When to Read**: Understanding how global, project, and session rules work together

Explains:
- Layered rule architecture (global → project → session)
- Why cross-references are critical
- Synchronization strategies for distributed rules
- How auto-classification helps organize documents
- Decision records for architectural choices

**Key Insight**: Distributed rule systems need explicit synchronization and visible dependencies to avoid chaos.

---

#### [Rule Synchronization Patterns](rule-synchronization-patterns.md)
**Type**: Pattern Reference | **Complexity**: Intermediate
**When to Read**: Actually implementing rule changes across multiple locations

Practical patterns:
- Pattern 1: Global-to-Project Sync
- Pattern 2: Project-Specific Overrides
- Pattern 3: Cross-Reference Web
- Pattern 4: Multi-Location Update Protocol
- Pattern 5: Conflict Resolution
- Pattern 6: Rule Evolution Tracking
- Pattern 7: Auto-Synced Rule Areas
- Pattern 8: Documentation Comments in Code

Includes ready-to-use checklists and bash scripts.

**Key Insight**: Following a consistent protocol prevents sync errors and makes changes auditable.

---

#### [Rule Design Principles](rule-design-principles.md)
**Type**: Design Principles | **Complexity**: Advanced
**When to Read**: Before creating or significantly updating shared rules

Core principles:
1. Layered Authority - Different layers, different authority levels
2. Explicit Scope Declaration - No ambiguous boundaries
3. Dependency Transparency - Show what depends on what
4. Versioning by Default - Track changes and migrations
5. Explicitness Over Implicitness - Assume nothing about reader context
6. Context-Aware Defaults - Different guidance for different situations
7. Migration Pathways - Clear upgrade paths when rules change
8. Observable Compliance - Ways to verify rule is followed

Includes structural guidelines, anti-patterns, governance model, and metrics.

**Key Insight**: Good rules scale when they're explicit, versioned, and observable.

---

## Learning Session Context

**Date**: 2026-01-30
**Session Focus**: Analyzing and documenting rule system architecture

### What This Session Revealed

#### Problem Discovered
When implementing rules across multiple locations (~/.claude/rules, .claude/rules/, CLAUDE.md), consistency breaks down without explicit synchronization strategy.

#### Solution Emerged
A layered architecture with:
- **Global defaults** for team-wide standards
- **Project overrides** for specific constraints
- **Session context** for current work guidance
- **Cross-references** to show dependencies
- **Synchronization protocol** to keep in sync

#### Why It Matters
- Rules are team knowledge artifacts
- Distributed rules require explicit governance
- Without clear structure, contradictions emerge
- Cross-references enable navigation and discovery

### Key Takeaways for Teams

1. **Rules are Architecture Decisions**: Treat them like code ADRs
2. **Explicit Beats Implicit**: Make scope, dependencies, authority clear
3. **Layers Prevent Chaos**: Global → Project → Session hierarchy works
4. **Sync is Mandatory**: Passive "natural sync" doesn't work
5. **Dependencies Matter**: Rules aren't isolated; show the web
6. **Verification is Key**: If you can't verify it, it won't be followed

## Related Documents

### In This Repository
- **서비스별 문서**: `docs/service/luppiter/`
- **Java Guides**: `docs/claude_lessons_learned/java/`
- **Database Guides**: `docs/claude_lessons_learned/db/`

### Global Rules
All global rules are in `~/.claude/rules/`:
- `agents.md` - Agent orchestration and when to use each
- `coding-style.md` - Code style and quality requirements
- `doc-organization.md` - Where to save documents
- `git-workflow.md` - Git practices and feature workflow
- `hooks.md` - Pre/post tool execution hooks
- `performance.md` - Model selection and context management
- `patterns.md` - Common code patterns (API response, custom hooks, etc.)
- `security.md` - Security guidelines and mandatory checks
- `testing.md` - Testing requirements (80%+ coverage)

### Related Projects
- **luppiter_scheduler**: `docs/service/luppiter/luppiter_scheduler/`
- **luppiter_web**: `docs/service/luppiter/luppiter_web/`

## How to Use These Documents

### For Individual Contributors
1. Start with [Rule System Architecture](rule-system-architecture.md) to understand the overall structure
2. Reference [Rule Synchronization Patterns](rule-synchronization-patterns.md) when making changes
3. Consult [Rule Design Principles](rule-design-principles.md) to understand "why" behind rules

### For Team Leads
1. Review [Rule Design Principles](rule-design-principles.md) before creating team-wide rules
2. Use [Rule Synchronization Patterns](rule-synchronization-patterns.md) to update shared rules
3. Reference [Rule System Architecture](rule-system-architecture.md) when onboarding new teams

### For Architects
1. Study [Rule Design Principles](rule-design-principles.md) for governance model and metrics
2. Use [Rule System Architecture](rule-system-architecture.md) for understanding layering
3. Reference [Rule Synchronization Patterns](rule-synchronization-patterns.md) for implementation details

## Implementation Checklist

When establishing rule systems in your team:

```markdown
- [ ] Choose appropriate layers (global/project/session)
- [ ] Create CLAUDE.md for project context
- [ ] Establish cross-reference convention
- [ ] Define synchronization protocol
- [ ] Communicate layers and authority to team
- [ ] Set up verification mechanisms (automated or manual)
- [ ] Document migration path for rule changes
- [ ] Add version tracking to rules
- [ ] Create related rules section template
- [ ] Establish governance (who approves what)
```

## Feedback & Improvements

These documents capture learnings from one implementation cycle. As you use them:
- Note what works well
- Flag what's unclear or incomplete
- Suggest improvements via PR or discussion
- Share adaptations for other contexts

---

**Created**: 2026-01-30
**Type**: Guide Index
**Status**: Active
**Maintained By**: Claude Code Team
**Last Updated**: 2026-01-30
