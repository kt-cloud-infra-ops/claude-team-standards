---
tags:
  - type/automation
  - domain/rules
  - audience/claude
---

> 상위: [자동화 패턴](README.md)

# 세션 작업 분석 보고서

**분석 대상**: 2026-01-30 Claude Code 규칙 파일 정비 세션
**작성자**: Claude Code Analysis System
**대상**: 향후 자동화 개선

---

## 요약

8개의 Claude Code 규칙 파일(`~/.claude/rules/`)에 "## Related Rules" 섹션을 추가하는 작업에서 **반복되는 패턴 3가지**를 발견했습니다.

| 작업 | 반복 횟수 | 자동화 난이도 | 예상 절감 시간 |
|------|---------|------------|-------------|
| 규칙 파일 관계 식별 | 8회 | 중간 | 30분 |
| 교차참조 링크 추가 | 8회 | 낮음 | 10분 |
| 파일 양방향 동기화 | 2회 | 낮음 | 5분 |
| **합계** | - | **낮음~중간** | **45분** |

---

## 패턴 1: 동일 구조의 섹션 반복 추가

### 현재 상황

각 파일의 **마지막에 동일한 마크다운 구조로** 섹션 추가:

```markdown
---

## Related Rules

- [filename.md](filename.md) - Description of relationship
- [another-file.md](another-file.md) - Context
```

### 반복 특징

- **구조**: 모든 8개 파일에 동일
- **형식**: 수평선 (`---`) + 제목 + 마크다운 목록
- **위치**: 파일의 끝 (항상)
- **링크**: 상대 경로 (같은 디렉토리)

### 자동화 방안

**Template-based generation**:
```yaml
# rule-templates.yaml
sections:
  - name: Related Rules
    template: |
      ---

      ## Related Rules

      {% for rule in relatedRules %}
      - [{{ rule.filename }}]({{ rule.filename }}) - {{ rule.description }}
      {% endfor %}
```

**효과**:
- 수동 작업: 8개 파일 × 3분 = 24분
- 자동화: 1분 (템플릿 생성 + 모든 파일 생성)
- **절감**: 23분

---

## 패턴 2: 수동 관계 매핑

### 현재 상황

각 파일의 내용을 읽고 **수동으로 관련된 규칙 파일을 식별**:

```
agents.md 읽기
  → testing.md (tdd-guide agent 언급) → 관계 발견
  → security.md (security-reviewer 언급) → 관계 발견
  → git-workflow.md (agent 활용 워크플로우) → 관계 발견

...8개 파일 반복...
```

### 발견된 관계 그래프

```
agents.md ←→ testing.md (tdd-guide, e2e-runner)
       ├→ security.md (security-reviewer)
       ├→ git-workflow.md (workflow agent usage)
       └→ performance.md (model selection)

testing.md ←→ git-workflow.md (TDD workflow)
        ├→ coding-style.md (code quality)
        └→ agents.md (agent support)

security.md ←→ coding-style.md (input validation)
        ├→ git-workflow.md (pre-commit checks)
        └→ agents.md (security-reviewer)

git-workflow.md ←→ testing.md (TDD approach)
            ├→ agents.md (planner, tdd-guide, code-reviewer)
            ├→ security.md (pre-commit checklist)
            └→ hooks.md (commit hooks)

coding-style.md ←→ security.md (input validation)
           ├→ testing.md (code quality tests)
           └→ patterns.md (implementation patterns)

performance.md ←→ agents.md (agent selection)
           └→ hooks.md (auto-accept strategy)

patterns.md ←→ coding-style.md (code quality)
        └→ agents.md (parallel evaluation)

hooks.md ←→ git-workflow.md (commit hooks)
      ├→ performance.md (auto-accept)
      └→ patterns.md (TodoWrite best practices)

doc-organization.md ←→ git-workflow.md (doc commits)
                 └→ hooks.md (doc blocker)
```

### 자동화 방안

**Keyword-based relationship extraction**:

```json
{
  "agents.md": {
    "keywords": ["agent", "workflow", "planner", "tdd-guide", "code-reviewer", "security-reviewer"],
    "auto_candidates": [
      { "file": "testing.md", "score": 0.95, "reason": "tdd-guide, e2e-runner" },
      { "file": "git-workflow.md", "score": 0.92, "reason": "agent-driven workflow" },
      { "file": "security.md", "score": 0.88, "reason": "security-reviewer" }
    ]
  }
}
```

**구현 단계**:
1. 각 파일의 주요 키워드/개념 추출
2. 파일 간 키워드 교집합 계산
3. 유사도 점수로 관계 순위 매김
4. 임계값 이상만 자동 추가 (나머지 수동 검증)

**효과**:
- 수동 작업: 8개 파일 × 5분 (읽기 + 관계 판단) = 40분
- 자동화: 5분 (키워드 추출 + 매칭)
- **절감**: 35분

---

## 패턴 3: 파일 양방향 동기화

### 현재 상황

규칙 파일이 **두 위치에 존재**:
- `~/.claude/rules/` (개인 홈)
- `/Users/jiwoong.kim/Documents/ai-team-standards/.agents/rules/` (프로젝트 repo)

**문서 변경 시 양쪽을 수동으로 업데이트**:
```bash
# 프로젝트 repo에서 수정
vim /Users/jiwoong.kim/Documents/ai-team-standards/.agents/rules/doc-organization.md

# 홈 디렉토리로 복사
cp /Users/jiwoong.kim/Documents/ai-team-standards/.agents/rules/doc-organization.md \
   ~/.claude/rules/doc-organization.md
```

### 동기화 필요성

- **doc-organization.md**: 동기화 규칙 자체가 "양쪽 업데이트" 명시
- **다른 규칙 파일들**: 일관성 필요

### 자동화 방안

**Option 1: Git-based sync** (가장 간단)
```bash
#!/bin/bash
# sync-home-rules.sh

RULES_SOURCE="$HOME/Documents/ai-team-standards/.agents/rules"
RULES_HOME="$HOME/.agents/rules"

for file in agents.md coding-style.md security.md testing.md \
            git-workflow.md performance.md patterns.md hooks.md \
            doc-organization.md; do
  if [[ "$RULES_SOURCE/$file" -nt "$RULES_HOME/$file" ]]; then
    cp "$RULES_SOURCE/$file" "$RULES_HOME/$file"
    git -C "$RULES_HOME/.." add "$file"
    echo "Synced: $file"
  fi
done
```

**Option 2: Symlink** (가장 우아함, 위험도 높음)
```bash
# 프로젝트 repo의 rules를 home으로 symlink
# 위험: home 디렉토리가 git 추적 대상이 아님
ln -s ~/Documents/ai-team-standards/.agents/rules ~/.claude/rules-project
```

**Option 3: Watch-based sync** (가장 자동화)
```bash
# watchman을 이용한 실시간 감시
# 파일 변경 시 자동 동기화
watchman watch ~/.claude/rules
watchman -- trigger ~/.claude/rules sync-to-project -- \
  find . -name "*.md" -type f
```

**효과**:
- 수동 작업: 매 변경마다 2-3분 (복사 + 커밋)
- 자동화: 0분 (Git pre-commit 훅으로 자동)
- **절감**: 2-3분/변경

---

## 자동화 구현 계획

### Phase 1: 메타데이터 생성 (30분)
```bash
# 1. related-rules-map.json 수동 작성
# 각 파일의 키워드와 관계 정의

# 2. 유효성 검증
# - 모든 참조 파일 존재 확인
# - 순환 참조 확인
```

### Phase 2: 생성 스크립트 (1시간)
```python
# generate_related_rules.py
# 1. related-rules-map.json 로드
# 2. 각 규칙 파일 읽기
# 3. "## Related Rules" 섹션 생성/업데이트
# 4. 두 위치 자동 동기화
```

### Phase 3: Pre-commit 훅 통합 (30분)
```bash
# .git/hooks/pre-commit
# 규칙 파일 변경 감지 → 자동 동기화 + 재생성
```

### Phase 4: CI/CD 통합 (선택)
```yaml
# GitHub Actions
# - 규칙 파일 변경 시 자동 테스트
# - 관계 맵 검증
# - 양쪽 동기화 확인
```

---

## 예상 효과

### 시간 절감
- **초기 설정**: 2시간 (자동화 스크립트 구현)
- **규칙 파일당 절감**: 3-5분
- **10회 사용 시 점수**: 30-50분 절감 - 2시간 설정 = **손익분기점 도달 안 함**
- **20회 이상 사용 시**: **비용 회수 + 추가 이득**

### 품질 개선
- **일관성**: 수동 오류 제거
- **유지보수성**: 중앙 관리 (related-rules-map.json)
- **확장성**: 새 규칙 추가 시 자동 반영

### 확장 가능성
- 다른 문서 시스템에 적용 (프로젝트 문서, 결정 기록 등)
- 문서 간 링크 검증 자동화
- 문서 최신성 모니터링

---

## 권장 사항

### 즉시 실행 (오늘)
- [ ] 이 분석 보고서 저장
- [ ] `related-rules-map.json` 설계 시작

### 이번 주 (1주일)
- [ ] Python 생성 스크립트 작성
- [ ] 테스트 실행
- [ ] Pre-commit 훅 통합

### 이번 달 (2주일)
- [ ] 기존 규칙 파일 자동 생성 확인
- [ ] 문서화 (사용 방법)
- [ ] CI/CD 파이프라인 추가

---

## 참고 파일

- **자동화 제안**: `/Users/jiwoong.kim/Documents/ai-team-standards/docs/automations/006-cross-reference-rules-automation.md`
- **규칙 디렉토리**: `~/.claude/rules/` (개인)
- **프로젝트 규칙**: `/Users/jiwoong.kim/Documents/ai-team-standards/.agents/rules/` (repo)
- **관련 가이드**: `docs/automations/README.md`

---

## 결론

3가지 반복 패턴(섹션 생성, 관계 매핑, 파일 동기화)은 모두 자동화 가능합니다.
**초기 투자 2시간 대비 지속적인 유지보수 시간 절감**이 예상되므로,
규칙 파일 변경 빈도가 높은 환경에서 **매우 가치 있는 자동화**입니다.

특히 "관련 규칙 자동 매핑" 기능은 **문서 간 네비게이션 개선**으로
전체 워크플로우 효율성을 높일 수 있습니다.
