---
tags:
  - type/reference
  - domain/observability
  - service/luppiter
  - audience/team
---

> 상위: [docs](../../README.md)

# Observability 연동 설계

## 개요

NEXT Infra/Platform 이벤트 관제를 Luppiter로 통합하는 프로젝트 문서입니다.

- **프로젝트**: luppiter_scheduler + luppiter_web
- **일정**: 개발 2/13, 검증 2/27

---

## 문서 목록

### 공통 설계

| 문서 | 설명 |
|------|------|
| [01-design.md](01-design.md) | 전체 연동 설계서 |
| [02-ddl.sql](02-ddl.sql) | DDL 스크립트 |
| [03-event-workflow.puml](03-event-workflow.puml) | 이벤트 워크플로우 다이어그램 |
| [04-functional-spec.md](04-functional-spec.md) | 기능별 상세 설계 |
| [05-api-spec-maintenance.md](05-api-spec-maintenance.md) | 메인터넌스 API 스펙 협의 |
| [jira-issues.md](jira-issues.md) | Jira 이슈 목록 및 멀티리전 영향도 |

### Scheduler: DB→API 전환

| 문서 | 설명 |
|------|------|
| [06-scheduler-api-migration.md](06-scheduler-api-migration.md) | DB→API 변경 설계 + 영향도 분석 |
| [06-01-implementation-guide.md](06-01-implementation-guide.md) | 상세 개발 가이드 (복붙 수준) |

### 구현 가이드

| 문서 | 설명 |
|------|------|
| [implementation-guide.md](implementation-guide.md) | Scheduler + Web 통합 구현 가이드 |

**구현 가이드 목차:**
- Part 1: Scheduler (ObservabilityEventWorker, 프로시저)
- Part 2: Web (서비스등록, 삭제, 예외, 메인터넌스)

---

## 영역 구분

| 프로젝트 | 담당 영역 |
|----------|----------|
| **luppiter_scheduler** | Worker (EST030), 프로시저, 임시 테이블 |
| **luppiter_web** | 서비스/플랫폼 등록, 관제 삭제, 예외/메인터넌스 UI |

---

## UI 변경 요약

| 화면 | 변경 내용 |
|------|----------|
| 서비스/플랫폼 등록 | 신규 화면 (L1~L4 선택 → 호스트그룹 자동생성) |
| 예외 등록 | 타입 선택 팝업 (Infra / Service / Platform) |
| 메인터넌스 등록 | 타입 선택 팝업 (Infra / Service / Platform) |
| 관제 삭제 | 탭 분리: Zabbix / Observability |
| 이벤트 목록 | source 컬럼 추가, 하이퍼링크 |

---

**최종 업데이트**: 2026-02-03
