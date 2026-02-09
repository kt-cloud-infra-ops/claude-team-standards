# Luppiter Scheduler 설계문서·Jira 참조

Confluence 설계문서와 Jira 티켓 확인용. **설계문서 업데이트가 필요한 경우** 이 목록을 기준으로 Confluence/Jira에서 반영 여부 확인.

---

## 0. 기존 아키텍처 vs 이번 커밋 변경 (차이만)

> 미등록 이벤트 알림(LUPR-698/702) 커밋 기준. **설계문서에 있던 기존 구조**와 **이번 커밋으로 추가·달라진 점**만 대조.

### 0.1 배치 Job 목록

| 구분 | 기존 아키텍처 (설계문서) | 이번 커밋으로 인한 변경 |
|------|--------------------------|--------------------------|
| **알람 Job** | EventAlarmServiceJob, MaintenanceAlarmServiceJob, ExceptionEventAlarmServiceJob, HostManageAlarmServiceJob **4종** | **+ UnregisteredEventAlarmServiceJob 1종 추가** (미등록 이벤트 전용) |
| **발송 경로** | AS-IS: scheduler → message_bridge / TO-BE: scheduler → **luppiter_web** → message_bridge | 이번 Job은 **scheduler → luppiter_web API** 호출 (TO-BE 방향과 동일) |

### 0.2 발송/HTTP 클라이언트

| 구분 | 기존 아키텍처 (설계문서) | 이번 커밋으로 인한 변경 |
|------|--------------------------|--------------------------|
| **클래스** | MessageServiceSender, SlackMessageSender (`/media/message/`, `/media/slack/`) | **RestClientService 신규 추가** (`/utils/`). 기존 MessageServiceSender 등과 별도 경로 |
| **HTTP** | RestTemplate 등 기존 클라이언트 사용, 타임아웃 설정 문서화 권장 | RestClientService는 **RestTemplate 사용하나 타임아웃 없음** (기존 패턴과 다름) |
| **의존성** | Bean 주입으로 재사용 | MessageSender 내부에서 **ApplicationContextProvider.getBean(RestClientService)** 사용 (기존 패턴과 다름) |

### 0.3 미등록 이벤트·채널

| 구분 | 기존 아키텍처 (설계문서) | 이번 커밋으로 인한 변경 |
|------|--------------------------|--------------------------|
| **채널 ID** | 미등록 이벤트 = `C0ACCJENW23` → **c00_system_properties** `slack.unregistered.channel` 등 **설정에서 조회** | 코드에 **`List.of("C0ACCJENW23")` 하드코딩** (설계와 다름, 설정으로 빼야 함) |
| **데이터 소스** | 설계서에는 “미등록 이벤트” 용도만 정의, 테이블은 O11y 연동(x01_if_event_obs) 문서에 있음 | **x01_if_event_obs** 조회, inventory_master/d00_service_inventory_master에 없는 건만 (if_dt 구간 조건) |
| **템플릿/엔드포인트** | TO-BE: Web API 호출 (템플릿 코드 등) | **EVENT_UNREGISTERED_ALARM** + **SLACK_CHANNEL**, URL = server.luppiter.api.url + 위 두 값 조합 |

### 0.4 데이터 흐름 (이번 커밋만)

| 단계 | 기존 알람 Job (설계서) | 이번 추가된 UnregisteredEventAlarm 흐름 |
|------|------------------------|----------------------------------------|
| 1 | 기존: cmon_event_info 등 메인 테이블 또는 기존 Mapper | **UnregisteredEventAlarmServiceMapper**로 **x01_if_event_obs** 조회 (미등록 조건) |
| 2 | MessageServiceSender 등으로 발송 요청 | **MessageSender** 내부 클래스가 **RestClientService.callApi()** 로 **luppiter_web** 호출 |
| 3 | message_bridge → 외부 | luppiter_web이 실제 슬랙 발송 (설계 TO-BE와 동일) |

### 0.5 요약: 설계 대비 다른 점

| 항목 | 설계/기존 | 이번 커밋 |
|------|-----------|-----------|
| Job 수 | 알람 Job 4종 | **+1종** (UnregisteredEventAlarmServiceJob) |
| 채널 ID | 설정(prop/DB) 조회 | **하드코딩** |
| RestTemplate | 타임아웃 설정 | **타임아웃 없음** |
| 발송 클라이언트 주입 | Bean 생성자 주입 | **getBean() 사용** |
| 발송용 신규 클래스 | - | **RestClientService**, **UnregisteredEventAlarmServiceMapper** 추가 |

---

## 1. Confluence 설계문서 (luppiter_scheduler 관련)

| 구분 | 제목 | URL |
|------|------|-----|
| **아키텍처** | Luppiter Scheduler 아키텍처 | https://ktcloud.atlassian.net/wiki/spaces/CL23/pages/1712849686 |
| **이벤트 취합** | 이벤트 취합 성능 개선 (Java 전환) | https://ktcloud.atlassian.net/wiki/spaces/CL23/pages/1689813293 |
| **메시지 발송** | 매체발송 기능 정리 (SREP) | https://ktcloud.atlassian.net/wiki/spaces/SREP/pages/1381466169 |
| **O11y/Next** | Next 요구사항 (SREP) | https://ktcloud.atlassian.net/wiki/spaces/SREP/pages/1560215751/Next |
| **DB** | DB 스키마 (Confluence) | https://ktcloud.atlassian.net/wiki/x/hAZZX |

**스페이스**: [기술] InfraOps개발팀 → CL23  
**공통**: SREP 스페이스 메시지/발송·Next 요구사항

---

## 2. Jira 티켓 (스케줄러 관련)

### LUPR (InfraOps개발팀 개발 관리)

| 이슈키 | 제목 |
|--------|------|
| LUPR-698 | 미등록 서비스/플랫폼 이벤트 발생시 슬랙 알림 모듈 개발 |
| LUPR-701 | 메인터넌스 알람 서비스 적용 (Scheduler) |
| LUPR-702 | 알람 채널(슬랙_채널) 발송 모듈 개발 |
| LUPR-488 | 유피테르 NEXT 수용 (모듈화 및 이벤트연동) – 에픽 |
| LUPR-479 | Luppiter_scheduler 이벤트취합 기능 개선 |
| LUPR-645 | 스케줄러 이벤트 연동 추상화 |
| LUPR-657 | 이벤트 연동 모듈 추상화 |

### TECHIOPS26 (연동 에픽/상위)

| 이슈키 | 제목 |
|--------|------|
| TECHIOPS26-73 | luppiter scheduler 코드 분석 |
| TECHIOPS26-265 | Scheduler 이벤트 병합 성능 개선 |
| TECHIOPS26-166 | Observability 이벤트 수집/병합 |
| TECHIOPS26-128 | 이벤트 조회 O11y 연동 |
| TECHIOPS26-81 | 메인터넌스 관리 O11y 타입 |

---

## 3. 설계문서 업데이트 시 반영할 내용 (참고)

미등록 이벤트 알림(LUPR-698/702) 구현 기준으로, Confluence 설계에 아래가 반영돼 있는지 확인 권장.

| 항목 | 반영 내용 |
|------|-----------|
| **구성요소** | `UnregisteredEventAlarmServiceJob` 추가, 실행 주기(예: 매분 :50), Mapper·RestClientService·MessageSender 역할 |
| **데이터 흐름** | x01_if_event_obs → Mapper 조회 → Job → MessageSender → Web API 호출 |
| **설정** | 채널 ID는 설정(prop/DB, 예: `slack.unregistered.channel`)에서 조회. API URL은 `server.luppiter.api.url` + 템플릿 + 채널 |
| **API 호출** | RestTemplate 사용, 타임아웃 설정 명시 |
| **의존성** | 발송용 클라이언트는 Bean 생성자 주입으로 재사용 |

---

**최종 업데이트**: 2026-02-06
