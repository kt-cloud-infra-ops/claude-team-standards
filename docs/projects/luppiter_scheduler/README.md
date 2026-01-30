# Luppiter Scheduler 문서

## 개요

| 항목 | 내용 |
|------|------|
| 프로젝트 | luppiter_scheduler |
| 언어 | Java (Spring Boot) |
| 역할 | 이벤트 취합, 알림 발송, 배치 작업 |

---

## 폴더 구조

```
luppiter_scheduler/
├── decisions/           # 의사결정 기록 (ADR)
├── o11y/                # Observability 연동 설계
├── event-pipeline.md    # 이벤트 파이프라인 구조
└── observability-event-schema.md  # O11y 이벤트 스키마
```

---

## 문서 목록

### 설계/아키텍처

| 문서 | 설명 |
|------|------|
| [event-pipeline.md](event-pipeline.md) | 이벤트 취합 파이프라인 구조 |
| [observability-event-schema.md](observability-event-schema.md) | Observability 이벤트 스키마 |

### Observability 연동 (o11y/)

| 문서 | 설명 |
|------|------|
| [01-design.md](o11y/01-design.md) | 연동 설계 |
| [02-ddl.sql](o11y/02-ddl.sql) | DDL 스크립트 |
| [04-functional-spec.md](o11y/04-functional-spec.md) | 기능 명세 |
| [05-implementation-guide.md](o11y/05-implementation-guide.md) | 구현 가이드 |

### 의사결정 (decisions/)

| 문서 | 설명 |
|------|------|
| [003-observability-integration-design.md](decisions/003-observability-integration-design.md) | O11y 연동 설계 ADR |
| [004-event-combine-performance.md](decisions/004-luppiter-scheduler-event-combine-performance-session.md) | 이벤트 취합 성능 개선 |

---

## 공통 가이드 참조

- [Java 코드 스타일](../../guides/java/kt-cloud-style.md)
- [SRE 코딩 가이드](../../guides/java/sre-coding.md)
- [디자인 패턴](../../guides/java/design-patterns.md)
- [DB 최적화](../../guides/db/database-optimization.md)

---

**최종 업데이트**: 2026-01-30
