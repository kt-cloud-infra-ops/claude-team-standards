# Claude Main Project

이 프로젝트는 상위 폴더에서 하위 프로젝트들을 통합 관리하는 메인 프로젝트입니다.

## 프로젝트 구조

```
claude/
├── CLAUDE.md           # 이 파일 - Claude에게 주는 지침
├── docs/
│   ├── service/                 # Confluence 동기화 대상 (사람용)
│   │   └── luppiter/
│   │       ├── architecture/    # → [LUPPITER] 서비스 아키텍처
│   │       ├── features/        # → [LUPPITER] 주요 기능 명세서
│   │       ├── history/         # → [LUPPITER] History
│   │       ├── sop/             # → [LUPPITER] SOP
│   │       ├── support-projects/  # → 05. 지원 프로젝트
│   │       ├── luppiter_scheduler/
│   │       │   ├── decisions/   # → [LUPPITER] History (설계 결정)
│   │       │   └── claude_temp/ # Claude 전용 (Confluence X)
│   │       ├── luppiter_web/
│   │       │   ├── screens/     # → 주요 기능 명세서 > 화면 명세
│   │       │   ├── api/         # → 주요 기능 명세서 > API
│   │       │   └── claude_temp/ # Claude 전용 (Confluence X)
│   │       └── luppiter_morning_report/
│   │
│   ├── claude_lessons_learned/  # Claude 학습 내용
│   │   ├── java/       # Java 가이드
│   │   ├── db/         # DB 가이드
│   │   └── common/     # 공통 가이드
│   ├── claude_automations/      # 자동화 패턴
│   ├── decisions/               # 팀 의사결정 (ADR)
│   └── temp/                    # 임시 문서
├── workspace/          # 하위 프로젝트 (심볼릭 링크)
└── .claude/
    ├── settings.local.json
    └── commands/       # 슬래시 커맨드
```

> 문서 저장 위치 규칙: `~/.claude/rules/doc-organization.md`

## 핵심 원칙

1. **반복 발견 → 자동화**: 반복되는 작업을 발견하면 자동화 패턴으로 기록
2. **지식 축적**: 세션에서 배운 것들을 문서로 남겨 재사용
3. **하위 프로젝트 통합 관리**: 여러 프로젝트의 컨텍스트를 한 곳에서 파악

## 슬래시 커맨드

- `/wrap` - 세션 마무리 (5가지 병렬 분석)
- `/status` - 프로젝트 현황 확인
- `/session-insights` - 세션 데이터 분석 대시보드

---

## 하위 프로젝트

`workspace/` 폴더에서 관리되는 프로젝트 목록:

| 프로젝트 | 설명 | CLAUDE.md | 비고 |
|---------|------|-----------|------|
| luppiter_web | 웹 프로젝트 (Java/Spring) | - | |
| luppiter_scheduler | 스케줄러 (Java/Spring) | - | 성능 이슈 진행 중 |
| test_luppiter_inv_api | 인벤토리 API (Spring Boot) | O | |
| luppiter_morning_report | 모닝 리포트 (Python) | O | |
| poc_zabbix_slack_check_api | Zabbix API (Python 2.7) | O | |
| zabbix_lib | Zabbix 라이브러리 | - | |
| test_claude_code | Claude 테스트 | - | |
| hands_on_a2a_opensource_korea | 오픈소스 프로젝트 | - | |
| test_slack_send | Slack 테스트 | - | |
| test_concurrent_execution | 동시 실행 테스트 | - | |

---

## 공통 코딩 가이드

### Java 코드 스타일

KT Cloud 전체 Java 프로젝트에 적용되는 코드 스타일 가이드.

| 항목 | 규칙 |
|------|------|
| 인코딩/새줄 | UTF-8, LF |
| 들여쓰기 | 하드탭 (4 spaces) |
| 최대 줄 너비 | 120자 |
| 중괄호 | K&R 스타일 |
| Naming | 클래스: PascalCase, 메서드/변수: camelCase, 상수: UPPER_SNAKE_CASE |
| 접두사 | Enum: E, Interface: I |
| 접미사 | Entity, Configuration, Aspect |

> 상세: `docs/claude_lessons_learned/java/kt-cloud-style.md`

### 디자인 패턴 (개념)

| 패턴 | 용도 |
|------|------|
| Builder | 복잡한 객체 생성 |
| Factory | 타입별 객체 생성 |
| Strategy | 알고리즘 교체 |
| Adapter | 외부 시스템 연동 |
| Facade | 복잡한 작업 단순화 |
| Observer | 이벤트 기반 처리 |

**Anti-Pattern 주의**: God Object, Magic Numbers, Copy-Paste

> 상세: `docs/claude_lessons_learned/java/design-patterns.md`

### SRE 코딩 규칙 (개념)

**1. 로깅 필수 포인트**
- 작업 시작/완료 로깅
- 외부 API 호출 로깅
- 에러 발생 시 스택트레이스 포함

**2. 회복력 (Resilience)**
- 타임아웃: 모든 외부 호출에 필수
- 재시도: Transient 에러만, Exponential Backoff
- 서킷브레이커: 연속 실패 시 빠른 실패

**3. 운영 필수 구현**
- Health Check 엔드포인트
- Graceful Shutdown
- 설정 외부화
- 메트릭 수집

**4. 체크리스트**
- [ ] 외부 호출 타임아웃 설정
- [ ] 구조화된 로그 (key=value 형식)
- [ ] 재시도/서킷브레이커 적용
- [ ] Health check 구현

> 상세: `docs/claude_lessons_learned/java/sre-coding.md`

---

## 주간 리마인더

| 항목 | 주기 | 상태 | 마지막 확인 |
|------|------|------|-------------|
| Git SaaS 이전 확인 | 1주 | 보류 | 2026-01-19 |

> 상세: `docs/decisions/001-git-migration-pending.md`

---

## 진행 중인 작업

### Observability 연동 프로젝트 (2026-01-19 ~)

**상태**: 설계 완료, DDL 완료, 개발 전

**프로젝트**: luppiter_scheduler + luppiter_web

**목표**: NEXT Infra/Platform 이벤트 관제를 Luppiter로 통합

**완료된 검토 (6/7)**:
- [x] #1 Worker 구조: 단일 ObservabilityEventWorker (EST030)
- [x] #2 키 매핑: Infra=IP, Service/Platform=target_name+region
- [x] #3 등록 테이블: cmon_service_inventory_master 신규
- [x] #4 계위 구조: 기존 L1~L4 동일 사용
- [x] #5 예외/메인터넌스: SERVICE_DETAIL 별도 테이블
- [x] #6 이벤트 저장: cmon_event_info 통합 + 컬럼 추가
- [x] #7 미등록 서비스 알림: Slack #luppiter-unregistered-events

**다음 작업**:
1. ObservabilityEventWorker 개발
2. 프로시저 작성 (p_combine_event_obs)
3. 서비스/플랫폼 등록 화면 개발
4. 예외/메인터넌스 타입 선택 팝업 개발

**참고 문서**:
- 설계: `docs/service/luppiter/support-projects/next-observability/01-design.md`
- DDL: `docs/service/luppiter/support-projects/next-observability/02-ddl.sql`
- ADR: `docs/service/luppiter/luppiter_scheduler/decisions/003-observability-integration-design.md`

**Confluence**: [기술] InfraOps개발팀 > 05. 지원 프로젝트 > next-observability

**일정**: 개발 2/13, 검증 2/27

---

## Luppiter Scheduler 이벤트 취합 성능 이슈 (2026-01-28 ~)

**상태**: 설계 완료, 개발 대기

**프로젝트**: luppiter_scheduler

**목표**: CombineEventServiceJob 성능 개선 (36s → 6~8s) 및 알림 누락 해소

**완료된 조치**:
- [x] x01_if_event_data DROP/재생성 (Zabbix) - 2026-01-29
- [x] x01_if_event_zenius DROP/재생성 (Zenius) - 2026-01-29
- [x] 프로시저 → Java 전환 설계 완료 - 2026-01-30

**다음 작업 (Phase 1: 프로시저 → Java)**:
- [ ] AbstractEventCombineService 추상 클래스 설계
- [ ] ZabbixEventCombineService 구현
- [ ] ZeniusEventCombineService 구현
- [ ] EventCombineOrchestrator + 병렬 처리 구현
- [ ] Shadow Mode 병행 운영 검증
- [ ] STG/PRD 배포

**후속 작업**:
- [ ] DB 월별 파티션 (DBA 협의)
- [ ] Phase 2: API 연동 + 통합 테이블 (Phase 1 완료 후)

**참고 문서**:
- **설계서**: `docs/service/luppiter/luppiter_scheduler/event-combine-java-migration-design.md`
- **구현 가이드**: `docs/service/luppiter/luppiter_scheduler/claude_event-combine-implementation-guide.md`
- 세션 정리: `docs/service/luppiter/luppiter_scheduler/decisions/003-observability-integration-design.md`

---

## 작업 시 참고사항

### 문서 저장 (자동 분류)
- **Luppiter 프로젝트 문서** → `docs/service/luppiter/<프로젝트>/` (Confluence 동기화)
- **Claude 전용 임시 파일** → `docs/service/luppiter/<프로젝트>/claude_temp/` (Confluence X)
- **팀 전체 의사결정** → `docs/decisions/`
- **학습 내용** → `docs/claude_lessons_learned/<언어>/`
- **자동화 패턴** → `docs/claude_automations/`

> 상세: `~/.claude/rules/doc-organization.md`

- **하위 프로젝트 작업 시**: 해당 프로젝트의 CLAUDE.md 먼저 확인
