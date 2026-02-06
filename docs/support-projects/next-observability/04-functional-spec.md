# Observability 연동 - 기능별 상세 설계서

> 작성일: 2026-01-20
> 참고: 01-design.md, 02-ddl.sql, 03-event-workflow.puml

---

## 목차

1. [시스템별 처리 방식 요약](#1-시스템별-처리-방식-요약)
2. [실시간 이벤트 처리 (Worker)](#2-실시간-이벤트-처리-worker)
3. [이벤트 조회 (Web)](#3-이벤트-조회-web)
4. [인벤토리 등록 (Infra)](#4-인벤토리-등록-infra)
5. [서비스/플랫폼 등록 (O11y)](#5-서비스플랫폼-등록-o11y)
6. [관제 대상 삭제](#6-관제-대상-삭제)
7. [예외 관리](#7-예외-관리)
8. [메인터넌스 관리](#8-메인터넌스-관리)
9. [기존 쿼리 영향도 분석 (inventory_master UNION)](#9-기존-쿼리-영향도-분석-inventory_master-union)

---

## 1. 시스템별 처리 방식 요약

### 1.1 전체 요약표

| 기능 | Zabbix | Zenius | O11y Infra | O11y Service/Platform |
|------|--------|--------|------------|----------------------|
| **이벤트 수집** | API 폴링 | DB 조회 (seq) | DB 조회 (seq) | DB 조회 (seq) |
| **매칭 테이블** | inventory_master | inventory_master | inventory_master | cmon_service_inventory_master |
| **매칭 키** | target_ip | target_ip | target_ip | target_name + region |
| **등록** | API 연동 | DB만 | DB만 | DB만 |
| **삭제** | API 실제 삭제 | DB만 삭제 | DB만 삭제 | DB만 삭제 |
| **예외** | DB 자체 관리 | DB 자체 관리 | DB 자체 관리 | DB 자체 관리 |
| **메인터넌스** | API 실제 중단 | 미지원 | API 실제 중단 | API 실제 중단 |

### 1.2 Worker 구조

```
EventWorkerFactory
├── EST010 → ZabbixEventWorker (v5)
├── EST011 → ZabbixEventWorker (v7)
├── EST020 → ZeniusEventWorker
└── EST030 → ObservabilityEventWorker (신규)
```

### 1.3 관제영역 분류

| 시스템 | 관제영역 |
|--------|---------|
| Zabbix | CSW, HW, VM |
| Zenius | NW |
| O11y Infra | CSW, HW, VM |
| O11y Service | Service |
| O11y Platform | Platform |

---

## 2. 실시간 이벤트 처리 (Worker)

### 2.1 처리 흐름

```
[모니터링 시스템] 이벤트 발생
       │
       ▼
[Luppiter Scheduler] 워커별 이벤트 수집
       │
       ├─ ZabbixEventWorker: Zabbix API 폴링
       ├─ ZeniusEventWorker: Zenius DB 조회 (seq 기반 증분)
       └─ ObservabilityEventWorker: O11y DB 조회 (seq 기반 증분)
       │
       ▼
[이벤트 타입 분류] Infra / Service / Platform
       │
       ├─ Infra: 호스트 IP 기반 inventory_master 조회
       │         → 관제영역 파생 (CSW/HW/NW/VM)
       │
       └─ Service/Platform: 네임스페이스+리전 기반
                            cmon_service_inventory_master 조회
                            → 미등록 시 Slack 알림
       │
       ▼
[예외 대상 체크] cmon_service_exception 조회
       │         ※ 메인터넌스는 소스 시스템에서 이미 중단됨
       │
       ├─ 예외 대상 → 이벤트 무시
       └─ 정상 대상 → 이벤트 저장
       │
       ▼
[DB 저장]
  ├─ cmon_event_info (이벤트 정보)
  └─ cmon_event_resp_manage_info (응대 정보)
```

### 2.2 관련 테이블

| 테이블 | 용도 | 비고 |
|--------|------|------|
| inventory_master | Infra 매칭 | 기존 |
| cmon_service_inventory_master | Service/Platform 매칭 | 신규 |
| cmon_event_info | 이벤트 저장 | source, type, dashboard_url, dimensions 컬럼 추가 |
| cmon_event_resp_manage_info | 응대 정보 | 기존 |
| cmon_service_exception | 예외 대상 조회 | 기존 |
| x01_if_event_obs | O11y 임시 연동 테이블 | 신규 |

### 2.3 미등록 이벤트 처리

- **조건**: Service/Platform 이벤트 중 cmon_service_inventory_master에 매칭 실패
- **처리**: Slack #luppiter-unregistered-events 채널로 알림
- **저장**: cmon_event_info에 저장 안함

---

## 3. 이벤트 조회 (Web)

### 3.1 처리 흐름

```
[사용자] 이벤트 조회 요청
       │
       ▼
[Luppiter Web] 사용자 권한 확인
       │         (호스트그룹/레이어코드)
       │
       ▼
[DB] 권한 기반 이벤트 조회
       │    (계위체계 필터링)
       │
       ▼
[Luppiter Web] 이벤트 목록 반환
       │
       ▼
[사용자] 이벤트 확인 (인지/이관/조치완료)
```

### 3.2 화면 변경 사항

- **source 컬럼 추가**: 연동시스템 표시 (Zabbix/Zenius/Grafana/Mimir/Loki)
- **하이퍼링크 추가**:
  - dashboard_url → 이벤트 제목 클릭 시 대시보드 이동
  - dimensions → 호스트명 클릭 시 상세 정보

---

## 4. 인벤토리 등록 (Infra)

### 4.1 대상 시스템

| 시스템 | 관제영역 | API 연동 |
|--------|---------|----------|
| Zabbix | CSW, HW, VM | O (Zabbix API) |
| Zenius | NW | X (DB만) |
| O11y Infra | CSW, HW, VM | X (DB만) |

### 4.2 처리 흐름

```
[사용자] 인벤토리 등록 요청 (Infra 대상)
       │
       ▼
[Luppiter Web] 모니터링 유형 선택
       │         (Zabbix / Zenius / O11y Infra)
       │
       ▼
[DB] 인벤토리 등록
       │    테이블: inventory_master
       │    키: target_ip (zabbix_ip)
       │
       ▼
[분기]
  ├─ Zabbix → [모니터링 시스템] Zabbix API 등록
  └─ Zenius/O11y Infra → DB만 등록 (소스 시스템 등록 X)
```

### 4.3 관련 테이블

| 테이블 | 용도 |
|--------|------|
| inventory_master | Infra 인벤토리 등록 |

---

## 5. 서비스/플랫폼 등록 (O11y)

### 5.1 대상 시스템

| 시스템 | 관제영역 | API 연동 |
|--------|---------|----------|
| O11y Service | Service | X (DB만) |
| O11y Platform | Platform | X (DB만) |

### 5.2 처리 흐름

```
[사용자] 서비스/플랫폼 등록 요청
       │
       ▼
[Luppiter Web] 서비스/플랫폼 정보 입력
       │         - namespace
       │         - 리전 (존)
       │         - 표준서비스
       │         - L1~L4 계위
       │
       ▼
[DB] 서비스/플랫폼 등록
       │    테이블: cmon_service_inventory_master
       │    키: target_name + region
       │
       ▼
[DB] 호스트그룹 자동생성
       │    형식: {L1}-{L3}-{L4}-{관제영역}
       │
       ▼
[사용자] 등록 완료 확인
```

### 5.3 관련 테이블

| 테이블 | 용도 |
|--------|------|
| cmon_service_inventory_master | 서비스/플랫폼 등록 (신규) |
| cmon_layer_code_info | 계위 코드 관리 (기존) |

### 5.4 화면 입력 항목

| 항목 | 설명 | 필수 |
|------|------|------|
| 서비스/플랫폼 타입 | Service / Platform 선택 | Y |
| namespace | 네임스페이스 | Y |
| 리전 (존) | 리전 구분 (예: DX-G-SE) | Y |
| 표준서비스 | L3 코드와 매핑 | Y |
| L1 (분류) | 계위 1레벨 | Y |
| L2 (도메인) | 계위 2레벨 | Y |
| L3 (표준서비스) | 계위 3레벨 | Y |
| L4 (Zone) | 계위 4레벨 | Y |

---

## 6. 관제 대상 삭제

### 6.1 시스템별 처리 방식

| 시스템 | 삭제 방식 | 삭제 테이블 |
|--------|----------|------------|
| Zabbix | API 실제 삭제 | cmon_manage_hosts_* + Zabbix API |
| Zenius | DB만 삭제 | cmon_manage_hosts_* |
| O11y | DB만 삭제 | cmon_manage_hosts_* |

### 6.2 처리 흐름

```
[사용자] 관제 대상 삭제 요청
       │
       ▼
[Luppiter Web] 모니터링 유형 선택
       │         (Zabbix / Zenius / O11y)
       │
       ▼
[DB] 삭제 정보 저장
       │    - cmon_manage_hosts_mst
       │    - cmon_manage_hosts_detail
       │    - cmon_manage_hosts_history
       │
       ▼
[분기]
  ├─ Zabbix → [모니터링 시스템] Zabbix API 실제 삭제
  └─ Zenius/O11y → DB 인벤토리만 삭제 (소스 시스템 삭제 X)
```

### 6.3 관련 테이블

| 테이블 | 용도 |
|--------|------|
| cmon_manage_hosts_mst | 삭제 요청 마스터 |
| cmon_manage_hosts_detail | 삭제 대상 상세 |
| cmon_manage_hosts_history | 삭제 이력 |

### 6.4 화면 변경 사항

- 탭 분리: Zabbix / Zenius / Observability

---

## 7. 예외 관리

### 7.1 시스템별 처리 방식

| 시스템 | 장비 대상 조회 | 이벤트 목록 조회 | 예외 저장 |
|--------|---------------|-----------------|----------|
| Zabbix | inventory_master | Zabbix API (trigger) | DB 자체 관리 |
| Zenius | inventory_master | 인벤토리 기반 (DB) | DB 자체 관리 |
| O11y Infra | inventory_master | 인벤토리 + API | DB 자체 관리 |
| O11y Service/Platform | cmon_service_inventory_master | 인벤토리 + API | DB 자체 관리 |

> **중요**: 예외는 모든 시스템이 DB 자체 관리 (API 연동 X)

### 7.2 처리 흐름

```
[사용자] 예외 등록 요청
       │
       ▼
[Luppiter Web] 모니터링 유형 선택
       │
       ▼
[분기: 장비/이벤트 목록 조회]
  │
  ├─ Zabbix
  │    ├─ [DB] 장비 대상 조회 (inventory_master)
  │    └─ [Zabbix API] trigger 목록 조회
  │
  ├─ Zenius
  │    ├─ [DB] 장비 대상 조회 (inventory_master)
  │    └─ [DB] 이벤트 목록 조회 (인벤토리 기반)
  │
  └─ O11y
       ├─ [DB] 장비 대상 조회
       │       - Infra: inventory_master
       │       - Service/Platform: cmon_service_inventory_master
       └─ [DB + O11y API] 이벤트 목록 조회
       │
       ▼
[사용자] 예외 대상 선택
       │
       ▼
[DB] 예외 정보 저장
       │    - cmon_exception_event (마스터)
       │    - cmon_exception_event_detail (Infra)
       │    - cmon_exception_service_detail (Service/Platform) - 신규
       │    - cmon_exception_event_history (이력)
       │
       ※ API 연동 없음 (DB 자체 관리)
```

### 7.3 관련 테이블

| 테이블 | 용도 | 비고 |
|--------|------|------|
| cmon_exception_event | 예외 마스터 | 기존 |
| cmon_exception_event_detail | Infra 예외 상세 | 기존 |
| cmon_exception_service_detail | Service/Platform 예외 상세 | 신규 |
| cmon_exception_event_history | 예외 이력 | 기존 |

### 7.4 화면 변경 사항

- **타입 선택 버튼** → 팝업에서 타입 선택
  - Infra (Zabbix, Zenius, Observability)
  - Service (Observability)
  - Platform (Observability)
- 선택한 타입에 따라 컬럼 표시 분기
  - Infra: 전체 컬럼 (IP, 장비위치, 설비바코드 등)
  - Service/Platform: Infra 전용 컬럼 제외

---

## 8. 메인터넌스 관리

### 8.1 시스템별 처리 방식

| 시스템 | 메인터넌스 지원 | 처리 방식 |
|--------|---------------|----------|
| Zabbix | O | API 실제 중단 |
| Zenius | X (미지원) | - |
| O11y | O | API 실제 중단 |

> **중요**: Zenius는 메인터넌스 미지원

### 8.2 처리 흐름

```
[사용자] 메인터넌스 등록 요청
       │    (Zabbix 또는 O11y만 가능)
       │
       ▼
[Luppiter Web] 메인터넌스 정보 입력
       │
       ▼
[DB] 메인터넌스 정보 저장
       │    - cmon_maintenance_event (마스터)
       │    - cmon_maintenance_event_detail (Infra)
       │    - cmon_maintenance_service_detail (Service/Platform) - 신규
       │
       ▼
[모니터링 시스템] API 실제 중단 처리
       │    - Zabbix API
       │    - O11y API
       │
       ※ 메인터넌스 중인 대상은 이벤트 자체가 발생하지 않음
```

### 8.3 관련 테이블

| 테이블 | 용도 | 비고 |
|--------|------|------|
| cmon_maintenance_event | 메인터넌스 마스터 | 기존 |
| cmon_maintenance_event_detail | Infra 메인터넌스 상세 | 기존 |
| cmon_maintenance_service_detail | Service/Platform 메인터넌스 상세 | 신규 |

### 8.4 화면 변경 사항

- **타입 선택 버튼** → 팝업에서 타입 선택
  - Infra (Zabbix, Zenius, Observability)
  - Service (Observability)
  - Platform (Observability)
- 선택한 타입에 따라 컬럼 표시 분기
- Zenius는 메인터넌스 미지원 (팝업에서 안내)

---

## 9. 기존 쿼리 영향도 분석 (inventory_master UNION)

> 작성일: 2026-02-06
> 관련: LUPR-699 (WEB), LUPR-700 (Scheduler)

### 9.1 개요

`cmon_service_inventory_master` 추가에 따라, 기존에 `inventory_master`만 조회하던 쿼리에
서비스 인벤토리를 UNION으로 포함해야 한다.

**미적용 시**: 서비스/플랫폼을 등록해도 기존 화면(대시보드, 이벤트, 인시던트 등)에서 보이지 않음.

---

### 9.2 영향 범위 요약

| 우선순위 | 파일 | 화면/기능 | UNION 대상 쿼리 수 |
|:--------:|------|----------|:-----------------:|
| 🔴 P0 | sql-dashboard.xml | 관제 대시보드 | 7 |
| 🔴 P0 | sql-evt.xml | 이벤트 상황관리/이력/인시던트 | 5~7 |
| 🔴 P0 | MaintenanceAlarmServiceMapper.xml | 메인터넌스 알람 (Scheduler) | 5 |
| 🔴 P0 | ExceptionEventAlarmServiceMapper.xml | 예외 알람 (Scheduler) | 1 |
| 🟡 P1 | sql-cmm.xml | 공통 관제영역 조회 | 1 |
| 🟡 P1 | sql-evt-cmm.xml | 예외/메인터넌스 공통 장비 조회 | 1 |
| 🟡 P1 | sql-icd.xml | 인시던트 검색 조건 | 2 |
| 🟡 P1 | morning_report (Python) | 모닝리포트 집계 | 2 |
| 🟢 P2 | sql-stt.xml | 서비스는 별도 화면 분리 | - |
| 🟢 P2 | sql-api.xml | Infra 전용 API | - |
| 🟢 P2 | sql-zab.xml | Zabbix 전용 | - |

---

### 9.3 P0 상세 — sql-dashboard.xml (관제 대시보드)

| 쿼리 ID/용도 | 라인 | 현재 JOIN | 영향 |
|-------------|------|----------|------|
| 대시보드 이벤트 현황 | L20 | `INNER JOIN inventory_master inv ON ei.target_ip = inv.zabbix_ip` | 서비스 이벤트가 대시보드에 안 보임 |
| 센터별 장비 수 집계 | L66-95 | `FROM inventory_master mst` | 서비스 인벤토리 장비 수 누락 |
| 존별 장비 수 집계 | L121-130 | `FROM inventory_master mst` | 존별 집계 누락 |
| 존타입별 집계 | L175-184 | `FROM inventory_master mst` | 존타입별 집계 누락 |
| 표준서비스별 통계 | L239-244 | `FROM inventory_master inv` | 표준서비스별 집계 누락 |
| 호스트그룹 권한 매핑 | L420-424 | `INNER JOIN inventory_master mst` | 서비스 인벤토리 권한 매핑 안됨 |
| 인벤토리 카운트 (존별) | L477-482 | `FROM inventory_master inv` | 관제현황 수치 불일치 |

### 9.4 P0 상세 — sql-evt.xml (이벤트 관리)

| 쿼리 ID/용도 | 라인 | 현재 JOIN | 영향 |
|-------------|------|----------|------|
| 실시간 이벤트 목록 | L384-388 | `INNER JOIN inventory_master B ON A.target_ip = B.zabbix_ip` | 서비스 이벤트에 인벤토리 정보 안 붙음 |
| 이벤트 이력 조회 | L613-617 | `INNER JOIN inventory_master B` | 이력에서 서비스 이벤트 정보 누락 |
| 이벤트 정제관리 | L1122-1126 | `LEFT JOIN inventory_master B` | 정제관리에서 서비스 이벤트 누락 |
| 이벤트 이력 V2 | L1271-1275 | `LEFT JOIN inventory_master B` | 서비스 이벤트 이력 누락 |
| 인시던트 이벤트 | L1500-1504 | `LEFT JOIN inventory_master B` | 인시던트에서 서비스 이벤트 없음 |

### 9.5 P0 상세 — Scheduler Mapper

**MaintenanceAlarmServiceMapper.xml**:

| 쿼리 용도 | 라인 | 영향 |
|-----------|------|------|
| 메인터넌스 알람 대상 inventory 조회 | L96-102 | 서비스 메인터넌스 알람 발송 안됨 |
| 메인터넌스 이력-인벤토리 매핑 | L431-447 | 서비스 메인터넌스 이력 누락 |
| 메인터넌스 대상-인벤토리 매핑 | L696-702, L740-755 | 서비스 대상 매핑 안됨 |
| 운영담당부서 매핑 | L857-861 | 서비스 인벤토리 운영부서 매핑 안됨 |

**ExceptionEventAlarmServiceMapper.xml**:

| 쿼리 용도 | 라인 | 영향 |
|-----------|------|------|
| 예외 상세-인벤토리 매핑 | L61-66 | 서비스 예외 대상 매핑 안됨 |

---

### 9.6 컬럼 매핑

| inventory_master | cmon_service_inventory_master | 비고 |
|------------------|-------------------------------|------|
| zabbix_ip (PK) | target_name 또는 service_seq | 키 타입이 다름 |
| host_nm | service_nm | |
| control_area | svc_type ('Service'/'Platform') | |
| host_group_nm | host_group_nm | 동일 |
| l1~l3_layer_cd, zone | l1~l3_layer_cd, region | 동일 구조 |
| system_code | 'OBS' 고정값 | |
| mgmt_ip, ipmi_ip, equnr | NULL | 서비스에 없음 |

### 9.7 UNION 적용 패턴

```sql
-- AS-IS
FROM inventory_master im
LEFT JOIN inventory_master_sub ims ON im.zabbix_ip = ims.zabbix_ip

-- TO-BE (UNION ALL 서브쿼리)
FROM (
    SELECT zabbix_ip, host_nm, control_area, host_group_nm,
           l1_layer_cd, l2_layer_cd, l3_layer_cd, zone, system_code,
           mgmt_ip, ipmi_ip, equnr, idc_center_code
    FROM inventory_master

    UNION ALL

    SELECT target_name AS zabbix_ip, service_nm AS host_nm,
           svc_type AS control_area, host_group_nm,
           l1_layer_cd, l2_layer_cd, l3_layer_cd, region AS zone,
           'OBS' AS system_code,
           NULL AS mgmt_ip, NULL AS ipmi_ip, NULL AS equnr, NULL AS idc_center_code
    FROM cmon_service_inventory_master
    WHERE use_yn = 'Y'
) im
-- inventory_master_sub JOIN은 Infra 전용이므로 LEFT JOIN 유지하되 서비스는 NULL
```

### 9.8 대안: 통합 뷰 생성

반복 UNION을 줄이기 위해 뷰 생성 고려:

```sql
CREATE VIEW v_inventory_all AS
SELECT zabbix_ip, host_nm, ... FROM inventory_master
UNION ALL
SELECT target_name, service_nm, ... FROM cmon_service_inventory_master WHERE use_yn = 'Y';
```

장점: 기존 쿼리에서 `inventory_master` → `v_inventory_all`로 교체만 하면 됨.
단점: inventory_master_sub JOIN 처리, 성능 검증 필요.

---

## 부록: 테이블 변경 요약

### 신규 테이블

| 테이블 | 용도 |
|--------|------|
| cmon_service_inventory_master | Service/Platform 등록 관리 |
| cmon_exception_service_detail | 예외 상세 (Service/Platform용) |
| cmon_maintenance_service_detail | 메인터넌스 상세 (Service/Platform용) |
| x01_if_event_obs | Observability 임시 연동 테이블 |

### 컬럼 추가

| 테이블 | 추가 컬럼 |
|--------|----------|
| cmon_event_info | source, type, dashboard_url, dimensions |

---

## 부록: 다이어그램 참조

- 전체 워크플로우: `03-event-workflow.puml`
- 관제 삭제 프로세스 (AS-IS/TO-BE): `luppiter_web/docs/관제 삭제 프로세스.puml`
