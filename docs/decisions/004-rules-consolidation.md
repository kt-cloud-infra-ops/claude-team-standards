---
tags:
  - type/adr
  - domain/rules
  - audience/team
---

> 상위: [decisions](README.md) · [docs](../README.md)

# ADR-004: 개인 rules를 프로젝트 rules로 통합

## 상태
승인됨

## 날짜
2026-02-06

## 컨텍스트
Claude Code rules 파일이 두 곳에 분산되어 있었음:
- **개인** `~/.claude/rules/` (11개 파일, 722줄)
- **프로젝트** `.agents/rules/` (3개 파일, 344줄)

문제점:
1. `doc-organization.md`가 양쪽에 거의 동일하게 존재 → 매 세션 ~230줄 이중 로드 (토큰 낭비)
2. 개인 rules는 Git 관리 안 됨 → 팀원 공유 불가
3. 내용 대부분이 팀 표준 (코딩 스타일, 테스트, 보안 등)인데 개인 폴더에 위치

## 결정
- **팀 표준 rules 9개** → 프로젝트 `.agents/rules/`로 이동 (Git 공유)
- **개인 환경 의존 파일 1개** (`hooks.md`) → 개인 `~/.claude/rules/`에 유지
- 중복 파일 (`doc-organization.md`, `jira-workflow.md`) → 프로젝트에만 유지

### 최종 구조

| 위치 | 파일 수 | 역할 |
|------|---------|------|
| `.agents/rules/` (프로젝트) | 11개 (741줄) | 팀 표준 (Git 공유) |
| `~/.claude/rules/` (개인) | 1개 (53줄) | 개인 환경 설정 (hooks) |

## 대안
1. **개인 유지, 프로젝트에 복사**: 양쪽 유지 → 동기화 부담 지속, 기각
2. **프로젝트 삭제, 개인만**: 팀 공유 불가, 기각
3. **개인을 최소 참조로**: "프로젝트 rules 참조" 한 줄만 → 다른 프로젝트에서 무의미, 기각

## 결과
- 세션당 토큰: 1,066줄 → 794줄 (~25% 절약)
- 중복 0줄 (이전 ~230줄)
- 팀원이 `git pull`하면 rules 자동 적용
- 규칙 변경 시 `.agents/rules/` 수정 → Git commit으로 팀 전파

---

이전: [ADR-003: Git 운영 정책](003-git-workflow.md)
