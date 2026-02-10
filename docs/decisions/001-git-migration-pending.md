---
tags:
  - type/adr
  - domain/git
  - audience/team
---

> 상위: [decisions](README.md) · [docs](../README.md)

# ADR-001: Git 저장소 이전 (보류)

## 상태
보류 (1주 단위 확인 필요)

## 날짜
2026-01-19

## 컨텍스트
- 현재: 사내망 프라이빗 Git
- 목표: SaaS 형태 접근 가능한 Git으로 이전 예정
- 이전 시점: 미정

## 결정
Git 초기화는 SaaS Git 이전 후 진행

## 리마인더
**1주에 한 번 확인 필요:**
- [ ] SaaS Git 접근 가능 여부 확인
- [ ] 이전 일정 확정 여부 확인

## 확인 이력
| 날짜 | 상태 | 비고 |
|------|------|------|
| 2026-01-19 | 보류 | 최초 기록 |

## 이전 완료 후 작업
1. 메인 프로젝트 Git 초기화
2. 원격 저장소 연결
3. 초기 커밋
4. 하위 프로젝트 submodule 검토

---

다음: [ADR-002: CLAUDE.md 분산 구조](002-claude-md-distributed-structure.md)
