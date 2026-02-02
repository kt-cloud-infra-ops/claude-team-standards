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
| [event-combine-java-migration-design.md](event-combine-java-migration-design.md) | **이벤트 취합 Java 전환 설계서** |
| [event-combine-implementation-guide.md](event-combine-implementation-guide.md) | **이벤트 취합 구현 가이드** (100% 코드) |

### Observability 연동

> O11y 설계 문서는 상위 프로젝트에 위치: [luppiter_web/o11y](../luppiter_web/o11y/)

| 담당 영역 | 내용 |
|----------|------|
| Worker | ObservabilityEventWorker (EST030) |
| 프로시저 | p_combine_event_obs |
| 임시 테이블 | x01_if_event_obs |

### 의사결정 (decisions/)

| 문서 | 설명 |
|------|------|
| [003-observability-integration-design.md](decisions/003-observability-integration-design.md) | O11y 연동 설계 ADR |
| [004-event-combine-performance.md](decisions/004-luppiter-scheduler-event-combine-performance-session.md) | 이벤트 취합 성능 개선 |

---

## 공통 가이드 참조

- [Java 코드 스타일](../../../claude_lessons_learned/java/kt-cloud-style.md)
- [SRE 코딩 가이드](../../../claude_lessons_learned/java/sre-coding.md)
- [디자인 패턴](../../../claude_lessons_learned/java/design-patterns.md)
- [DB 최적화](../../../claude_lessons_learned/db/database-optimization.md)

## Confluence 동기화

이슈 히스토리는 Confluence에도 동기화됨:
- `docs/confluence/luppiter/history/`

---

**최종 업데이트**: 2026-02-02
