---
description: Test Coverage
model: sonnet
---

> **실행 모델**: `sonnet` — 이 스킬을 Task 도구로 위임 시 `model: "sonnet"`를 사용하세요.

# Test Coverage

Analyze test coverage and generate missing tests:

1. Run tests with coverage: npm test --coverage or pnpm test --coverage

2. Analyze coverage report (coverage/coverage-summary.json)

3. Identify files below 80% coverage threshold

4. For each under-covered file:
   - Analyze untested code paths
   - Generate unit tests for functions
   - Generate integration tests for APIs
   - Generate E2E tests for critical flows

5. Verify new tests pass

6. Show before/after coverage metrics

7. Ensure project reaches 80%+ overall coverage

Focus on:
- Happy path scenarios
- Error handling
- Edge cases (null, undefined, empty)
- Boundary conditions
