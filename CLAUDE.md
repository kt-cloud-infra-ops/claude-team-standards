# Claude Main Project

이 프로젝트는 상위 폴더에서 하위 프로젝트들을 통합 관리하는 메인 프로젝트입니다.

## 프로젝트 구조

```
claude/
├── CLAUDE.md                      # 이 파일 - Claude에게 주는 지침
├── docs/
│   ├── service/                   # 서비스별 문서 (Confluence 동기화)
│   │   ├── luppiter/              # Luppiter - 관제 플랫폼
│   │   ├── gaia/                  # Gaia - 인프라 자동화
│   │   ├── hera/                  # Hera - 모니터링 플랫폼
│   │   ├── infrafe/               # InfraFE - 인프라 프론트엔드
│   │   ├── cmdb/                  # CMDB - 구성관리 DB
│   │   └── hermes/                # Hermes - 메시징/알림
│   │
│   ├── claude_automations/        # Claude용 - 자동화 패턴
│   ├── claude_lessons_learned/    # Claude용 - 학습 내용
│   │   ├── java/                  # Java 가이드
│   │   ├── db/                    # DB 가이드
│   │   └── common/                # 공통 가이드
│   ├── decisions/                 # 이 저장소 운영 관련 ADR
│   ├── ktcloud/                   # 회사 공통 가이드
│   ├── personal/                  # 개인 문서
│   └── temp/                      # 임시 문서 (통합 관리)
│
├── workspace/                     # 하위 프로젝트 (심볼릭 링크)
└── .claude/
    ├── commands/                  # 슬래시 커맨드
    └── rules/                     # 프로젝트별 규칙
```

### 문서 분류 규칙

| 접두사 | 의미 | Confluence |
|--------|------|------------|
| `claude_` | Claude AI가 참조/활용 | X |
| 없음 | 사람이 보는 문서 | O |

### 서비스 폴더 구조

```
service/{서비스}/
├── architecture/       # 서비스 아키텍처
├── features/           # 주요 기능 명세
├── sop/                # 운영 절차서
├── decisions/          # 서비스 레벨 ADR
└── projects/           # 프로젝트별 문서
    └── {프로젝트}/
        └── decisions/  # 프로젝트 레벨 ADR
```

### decisions 폴더 구분

| 위치 | 역할 |
|------|------|
| `docs/decisions/` | 이 claude 저장소 운영 관련 |
| `docs/service/{서비스}/decisions/` | 서비스 레벨 설계 결정 |
| `docs/service/{서비스}/projects/{프로젝트}/decisions/` | 프로젝트 레벨 설계 결정 |

---

## 핵심 원칙

1. **반복 발견 → 자동화**: 반복되는 작업을 발견하면 `docs/claude_automations/`에 기록
2. **지식 축적**: 세션에서 배운 것들을 `docs/claude_lessons_learned/`에 문서화
3. **하위 프로젝트 통합 관리**: 여러 프로젝트의 컨텍스트를 한 곳에서 파악

---

## 슬래시 커맨드

| 커맨드 | 설명 |
|--------|------|
| `/wrap` | 세션 마무리 (5가지 병렬 분석) |
| `/status` | 프로젝트 현황 확인 |
| `/session-insights` | 세션 데이터 분석 대시보드 |
| `/plan` | 작업 계획 수립 |
| `/code-review` | 코드 리뷰 |
| `/tdd` | TDD 워크플로우 |

---

## 하위 프로젝트

`workspace/` 폴더에서 관리되는 프로젝트 목록:

| 프로젝트 | 설명 | CLAUDE.md |
|---------|------|-----------|
| luppiter_web | 웹 프로젝트 (Java/Spring) | - |
| luppiter_scheduler | 스케줄러 (Java/Spring) | - |
| luppiter_morning_report | 모닝 리포트 (Python) | O |
| test_luppiter_inv_api | 인벤토리 API (Spring Boot) | O |
| luppiter_web_e2e | E2E 테스트 (Playwright) | - |

---

## 공통 코딩 가이드

### Java 코드 스타일

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

### 디자인 패턴

| 패턴 | 용도 |
|------|------|
| Template Method | 공통 흐름 + 차이점 분리 |
| Builder | 복잡한 객체 생성 |
| Factory | 타입별 객체 생성 |
| Strategy | 알고리즘 교체 |
| Adapter | 외부 시스템 연동 |

> 상세: `docs/claude_lessons_learned/java/design-patterns.md`

### SRE 코딩 규칙

- 타임아웃: 모든 외부 호출에 필수
- 재시도: Transient 에러만, Exponential Backoff
- 로깅: 작업 시작/완료, 외부 API 호출, 에러 스택트레이스
- Health Check: 필수 구현

> 상세: `docs/claude_lessons_learned/java/sre-coding.md`

---

## 진행 중인 작업

### Observability 연동 프로젝트 (2026-01-19 ~)

**상태**: 설계 완료, DDL 완료, 개발 전

**프로젝트**: luppiter_scheduler + luppiter_web

**목표**: NEXT Infra/Platform 이벤트 관제를 Luppiter로 통합

**다음 작업**:
1. ObservabilityEventWorker 개발
2. 프로시저 작성 (p_combine_event_obs)
3. 서비스/플랫폼 등록 화면 개발

**참고 문서**:
- 설계: `docs/service/luppiter/support-projects/next-observability/`
- ADR: `docs/service/luppiter/projects/scheduler/decisions/003-observability-integration-design.md`

**일정**: 개발 2/13, 검증 2/27

---

### Luppiter Scheduler 성능 개선 (2026-01-28 ~)

**상태**: 설계 완료, 개발 대기

**프로젝트**: luppiter_scheduler

**목표**: CombineEventServiceJob 성능 개선 (36s → 6~8s)

**완료**:
- [x] 임시 테이블 재생성 (2026-01-29)
- [x] 프로시저 → Java 전환 설계 (2026-01-30)

**다음 작업 (Phase 1)**:
- [ ] AbstractEventCombineService 구현
- [ ] ZabbixEventCombineService 구현
- [ ] ZeniusEventCombineService 구현
- [ ] Shadow Mode 병행 운영 검증

**참고 문서**:
- 설계서: `docs/service/luppiter/projects/scheduler/event-combine-java-migration.md`

---

## 문서 저장 규칙

| 문서 유형 | 저장 위치 |
|----------|----------|
| 서비스 문서 (Confluence) | `docs/service/{서비스}/` |
| 프로젝트 문서 | `docs/service/{서비스}/projects/{프로젝트}/` |
| 프로젝트별 설계 결정 | `docs/service/{서비스}/projects/{프로젝트}/decisions/` |
| 임시 작업 파일 | `docs/temp/` |
| Claude 학습 내용 | `docs/claude_lessons_learned/{언어}/` |
| 자동화 패턴 | `docs/claude_automations/` |
| 저장소 운영 ADR | `docs/decisions/` |

---

## 주간 리마인더

| 항목 | 주기 | 상태 | 마지막 확인 |
|------|------|------|-------------|
| Git SaaS 이전 확인 | 1주 | 보류 | 2026-01-19 |

> 상세: `docs/decisions/001-git-migration-pending.md`

---

## 작업 시 참고사항

- **하위 프로젝트 작업 시**: 해당 프로젝트의 CLAUDE.md 먼저 확인
- **새 문서 작성 시**: 위 저장 규칙 참고
- **Confluence 동기화**: `claude_` 접두사 없는 문서만 대상
