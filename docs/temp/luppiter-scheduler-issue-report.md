# Luppiter Scheduler 이벤트 취합 성능 이슈

## 1. 시스템 개요

### 1.1 전체 구조

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         외부 모니터링 시스템                              │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐       │
│  │ Zabbix   │ │ Zabbix   │ │ Zabbix   │ │ Zabbix   │ │ Zenius   │       │
│  │ (CSW)    │ │ (HW)     │ │ (BD)     │ │ (YS)     │ │          │       │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘       │
└───────┼────────────┼────────────┼────────────┼────────────┼─────────────┘
        │            │            │            │            │
        ▼            ▼            ▼            ▼            ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      Luppiter Scheduler                                  │
│                                                                          │
│  ① 수집 Job (매분 :00)                                                   │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ ZabbixEventJob × 4, ZeniusEventJob × 1                           │   │
│  │ → 외부 시스템에서 이벤트 조회 → 임시 테이블 저장                    │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                              ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │              임시 테이블 (x01_if_event_data, x01_if_event_zenius)  │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                              ▼                                           │
│  ② 취합 Job (매분 :20) ← ⚠️ 성능 이슈 발생 지점                          │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ CombineEventServiceJob                                            │   │
│  │ → 임시 테이블 → 메인 테이블 (cmon_event_info) 통합                  │   │
│  │ → 인벤토리 매핑, 예외 처리, 해소 처리                               │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                              ▼                                           │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    메인 테이블 (cmon_event_info)                   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                              ▼                                           │
│  ③ 알림 Job (매분 :50)                                                   │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │ EventAlarmServiceJob                                              │   │
│  │ → 메인 테이블에서 발송 대상 조회 → SMS/LMS/Email/Slack 발송         │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                          │
└─────────────────────────────────────────────────────────────────────────┘
```

### 1.2 스케줄 타임라인 (매분 기준)

```
:00        :20                :50        :00(다음분)
 │          │                  │          │
 ▼          ▼                  ▼          ▼
수집Job    취합Job            알림Job    수집Job
시작       시작               시작       시작
           │                  │
           │←── 정상: 30초 ──→│
           │                  │
           │←── 현재: 36초 ────│→ 겹침 발생!
```

### 1.3 주요 테이블

| 테이블 | 용도 | 비고 |
|--------|------|------|
| x01_if_event_data | Zabbix 이벤트 임시 저장 | 수집 → 취합 |
| x01_if_event_zenius | Zenius 이벤트 임시 저장 | 수집 → 취합 |
| cmon_event_info | 통합 이벤트 (메인) | 취합 → 알림 |
| c01_batch_event | 배치 Job 설정 | system_code, sync_idx |

### 1.4 처리 흐름

```
[외부 Zabbix/Zenius]
        │
        ▼ API 호출
[수집 Job] ──INSERT──▶ [임시 테이블]
                              │
                              ▼ 프로시저 호출
[취합 Job] ◀─────────────────┘
        │
        │  1. 신규 이벤트 INSERT (인벤토리 매핑)
        │  2. 대응관리 정보 INSERT
        │  3. 해소 이벤트 UPDATE
        │  4. sync_idx 갱신
        ▼
[메인 테이블: cmon_event_info]
        │
        ▼ SELECT (last_occu_time = 현재 분)
[알림 Job] ──발송──▶ [SMS/LMS/Email/Slack]
```

---

## 2. 현황

| 항목 | 값 |
|-----|-----|
| 대상 Job | CombineEventServiceJob |
| 실행 주기 | 매분 :20 |
| 정상 소요시간 | 10~15초 |
| 현재 소요시간 | **28초 → 36초 (증가 추세)** |

## 3. 영향

### 알림 발송 지연/누락 발생

```
:20  취합모듈 시작
:50  알림모듈 시작 (이 시점에 커밋된 이벤트만 조회)
:56  취합모듈 종료 (36초 소요 시)
```

- 알림모듈은 `last_occu_time = 현재 분`인 이벤트만 조회
- 취합/알림 겹치는 시간(6초) 동안 처리되는 시스템의 이벤트 **누락**
- 취합 시간 증가 → 누락 이벤트 증가

### 누락 범위

| 취합 소요시간 | 겹침 | 누락 |
|-------------|------|------|
| ~30초 | 없음 | 없음 |
| 36초 | 6초 | 일부 (마지막 처리 시스템) |
| 50초 | 20초 | 다수 |
| 60초+ | 분 초과 | **전체** |

## 4. 원인 분석

### 4.1 순차 처리 구조

```java
for(Map<String, String> map : batchMapList) {
    eventBatchMapper.combineEventForZabbix(combineParams);
}
```

- 6개 시스템을 순차 처리
- 각 시스템별 개별 커밋 (일부 발송, 일부 누락)

### 4.2 임시 테이블 데이터 누적

| 테이블 | 크기 | 용도 |
|--------|------|------|
| x01_if_event_data | ~7GB | Zabbix 이벤트 임시 |
| x01_if_event_zenius | ~7GB | Zenius 이벤트 임시 |

- 정리 없이 계속 누적
- 조회 성능 저하

### 4.3 인덱스 누락

```
x01_if_event_data    → 인덱스 있음 ✅
x01_if_event_zenius  → 인덱스 없음 ❌
```

## 5. 즉시 조치 (DB 작업)

> Zabbix/Zenius 테이블 분리 → 순차 작업으로 서비스 영향 최소화

### 5.1 Phase 1: Zabbix 테이블 (x01_if_event_data)

**Step 1. Zabbix Job만 중지**
```sql
-- Zabbix 수집 Job 중지 (ES0001~ES0005: Zabbix)
UPDATE c01_batch_event
SET use_yn = 'N'
WHERE system_code IN ('ES0001', 'ES0002', 'ES0003', 'ES0004', 'ES0005');
```

**Step 2. 테이블 DROP 및 재생성**
```sql
DROP TABLE IF EXISTS x01_if_event_data;

CREATE TABLE public.x01_if_event_data (
    system_code         varchar(50) not null,
    event_id            int8 not null,
    event_dt            timestamp not null,
    event_level         int8 not null,
    event_contents      varchar(2048) not null,
    event_status        int4 not null,
    recovery_dst_id     int8,
    event_ip            varchar(20),
    host_id             int8,
    template_id         int8,
    trigger_id          int8,
    item_id             int8,
    status_agent        int4,
    status_ipmi         int4,
    status_snmp         int4,
    status_jmx          int4,
    if_dt               timestamp not null,
    maintenance_status  int4
);

CREATE INDEX x01_if_event_data_system_code_idx ON x01_if_event_data (system_code, event_id);
CREATE INDEX x01_if_event_data_event_id_idx ON x01_if_event_data (event_id);
CREATE INDEX x01_if_event_data_trigger_id_idx ON x01_if_event_data (trigger_id);
```

**Step 3. Zabbix Job 재시작**
```sql
UPDATE c01_batch_event
SET use_yn = 'Y'
WHERE system_code IN ('ES0001', 'ES0002', 'ES0003', 'ES0004', 'ES0005');
```

---

### 5.2 Phase 2: Zenius 테이블 (x01_if_event_zenius)

**Step 1. Zenius Job만 중지**
```sql
-- Zenius 수집 Job 중지 (ES0006: Zenius)
UPDATE c01_batch_event
SET use_yn = 'N'
WHERE system_code = 'ES0006';
```

**Step 2. 테이블 DROP 및 재생성**
```sql
DROP TABLE IF EXISTS x01_if_event_zenius;

CREATE TABLE public.x01_if_event_zenius (
    system_code varchar(50) NOT NULL,
    z_status int4 NULL,
    z_alert int4 NULL,
    z_evttime timestamp NULL,
    z_rectime timestamp NULL,
    z_infraid int4 NULL,
    z_myhost varchar(500) NULL,
    z_myip varchar(200) NULL,
    z_myname varchar(200) NULL,
    z_mymsg varchar(1000) NULL,
    z_myid varchar(20) NULL,
    z_setid int4 NULL,
    zenius_level varchar(20) NULL,
    infra_code int4 NULL,
    event_level int8 NOT NULL,
    set_name varchar(20) NULL,
    event_code varchar(20) NULL,
    if_idx varchar(30) NULL,
    if_dt timestamp NOT NULL,
    maintenance_status int4 NULL
);

CREATE INDEX x01_if_event_zenius_system_code_idx ON x01_if_event_zenius (system_code, if_idx);
CREATE INDEX x01_if_event_zenius_z_myip_z_myid_idx ON x01_if_event_zenius (z_myip, z_myid);
```

**Step 3. Zenius Job 재시작**
```sql
UPDATE c01_batch_event
SET use_yn = 'Y'
WHERE system_code = 'ES0006';
```

---

### 예상 소요시간

| Phase | 작업 | 소요시간 |
|-------|------|----------|
| Phase 1 | Zabbix 테이블 | ~1분 |
| Phase 2 | Zenius 테이블 | ~1분 |
| **전체** | | **~2분** |

### 예상 효과

- 취합 소요시간: 36초 → **10초 이내**
- 알림 누락 해소
- **순차 작업으로 전체 서비스 중단 없음**

## 6. 장기 개선 방향

### 6.1 주기적 정리 체계 구축

| 항목 | 내용 |
|-----|------|
| Job | CleanupIfEventDataJob |
| 주기 | 매일 03:00 |
| 보관 정책 | 7일 (또는 30일) |
| 대상 | x01_if_event_data, x01_if_event_zenius |
| 적용 시점 | **스케줄러 배포 시 적용** |

### 6.2 DB 파티션 검토

| 항목 | 내용 |
|-----|------|
| 대상 | x01_if_event_data, x01_if_event_zenius |
| 전략 | Range 파티션 (월별/일별) |
| 장점 | DELETE 대비 파티션 DROP으로 즉시 정리, 조회 성능 향상 |
| 상태 | **DBA 협의 진행 중** |

### 6.3 Java 로직 전환

| 항목 | 내용 |
|-----|------|
| AS-IS | PL/SQL 프로시저 (p_combine_event_zabbix, p_combine_event_zenius) |
| TO-BE | Java 서비스 (ZabbixEventCombineService, ZeniusEventCombineService) |
| 병렬 처리 | CompletableFuture로 6개 시스템 동시 처리 |
| 기대 효과 | 속도 3~4배 개선, 유지보수성 향상, 단위 테스트 가능 |

### 6.4 마이그레이션 계획

| 단계 | 작업 | 비고 |
|-----|------|------|
| 1 | 주기적 정리 Job 개발 | 재발 방지 |
| 2 | DB 파티션 검토/적용 | DBA 협의 |
| 3 | Java 서비스 구현 | 프로시저 전환 |
| 4 | 병렬 처리 구현 | Orchestrator |
| 5 | 테스트 및 배포 | STG → PRD |

> 상세 구현 가이드: `docs/temp/luppiter-scheduler-event-combine-improvement.md`

## 7. 작업 일정

| 단계 | 내용 | 비고 |
|-----|------|------|
| 1 | 공지 | Slack |
| 2 | Phase 1: Zabbix | Job 중지 → DROP/재생성 → Job 재시작 |
| 3 | Phase 2: Zenius | Job 중지 → DROP/재생성 → Job 재시작 |
| 4 | 모니터링 | 취합 시간 확인 |
