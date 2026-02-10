---
tags:
  - type/adr
  - domain/rules
  - audience/team
---

> 상위: [decisions](README.md) · [docs](../README.md)

# ADR-002: CLAUDE.md 프로젝트별 분산 구조

## 상태
승인됨

## 날짜
2026-01-19

## 컨텍스트
- 메인 CLAUDE.md가 1066줄로 비대화
- Java/Spring 코딩 룰북이 ~600줄 차지
- 프로젝트 진입 시 관련 정보 탐색 어려움
- 각 프로젝트의 기술 스택이 상이함 (Java, Python 2.7, Spring Boot 등)

## 결정
메인 CLAUDE.md는 전체 구조와 공통 원칙만 유지하고, 각 프로젝트는 자신의 CLAUDE.md에 프로젝트별 가이드를 보유한다.

## 구조

```
메인 (100-150줄)
└─ /claude/CLAUDE.md
   ├── 프로젝트 구조
   ├── 핵심 원칙
   ├── 슬래시 커맨드
   ├── 하위 프로젝트 목록
   ├── 공통 코딩 가이드 (개념만)
   └── 주간 리마인더

프로젝트별 (20-300줄)
└─ /{project}/CLAUDE.md
   ├── 프로젝트 개요
   ├── 기술 스택
   ├── 프로젝트 특화 가이드
   └── 문서 참조 링크

상세 학습
└─ /claude/docs/learnings/
   └── 구체적 기술 내용 (코딩 룰북, 패턴 등)
```

## 대안 검토

| 대안 | 장점 | 단점 | 결정 |
|------|------|------|------|
| 중앙화 유지 | 한 곳에서 모든 정보 | 파일 비대화, 탐색 어려움 | 기각 |
| 완전 분산 | 각 프로젝트 독립 | 공통 원칙 중복, 일관성 저하 | 기각 |
| 하이브리드 (채택) | 공통+프로젝트별 분리 | 문서 관리 포인트 증가 | 채택 |

## 구현 결과

| 프로젝트 | CLAUDE.md | 크기 | 비고 |
|---------|-----------|------|------|
| 메인 (claude) | O | 116줄 | 공통 원칙 |
| luppiter-web | O | ~300줄 | Java/Spring 룰북 포함 |
| luppiter_inv | O | ~20줄 | Spring Boot API |
| morning_report | O | ~25줄 | Python |
| zabbix_api | O | ~25줄 | Python 2.7 |
| 기타 10개 | - | - | 필요 시 추가 |

## 예상 결과
- 메인 CLAUDE.md 간결화: 1066줄 → 116줄 (-89%)
- 프로젝트 진입 시 해당 CLAUDE.md 우선 참조
- 신규 프로젝트 추가 시 명확한 구조 제공
- docs/learnings와의 명확한 역할 분담

## 제약 사항
- 각 프로젝트가 별도 git repo이므로 자동 동기화 불가
- 프로젝트별 CLAUDE.md는 해당 프로젝트에서 개별 커밋 필요
- 메인 프로젝트에서는 projects/ 심볼릭 링크로 접근만 가능

## 참고
- 관련 학습: `docs/learnings/006-documentation-architecture.md`

---

이전: [ADR-001: Git 이전 (보류)](001-git-migration-pending.md) · 다음: [ADR-003: Git 운영 정책](003-git-workflow.md)
