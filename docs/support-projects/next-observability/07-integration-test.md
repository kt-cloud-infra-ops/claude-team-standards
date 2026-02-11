---
tags:
  - type/spec
  - service/luppiter
  - service/luppiter/o11y
  - audience/team
---

> 상위: [next-observability](README.md) · [docs](../../README.md)

# Observability 통합테스트 시나리오

> 작성일: 2026-02-11
> Mock 서버: `workspace/o11y-mock/mock_server.py` (port 5050)
> 환경: STG (CentOS 7.9)

---

## 목차

1. [사전 조건](#1-사전-조건)
2. [이벤트 수집 (Scheduler)](#2-이벤트-수집-scheduler)
3. [이벤트 처리 (Combine 프로시저)](#3-이벤트-처리-combine-프로시저)
4. [이벤트 조회 (Web)](#4-이벤트-조회-web)
5. [메인터넌스 관리 (Web → O11y API)](#5-메인터넌스-관리-web--o11y-api)
6. [예외 관리 (Web → DB)](#6-예외-관리-web--db)
7. [미등록 이벤트 알림](#7-미등록-이벤트-알림)
8. [회귀 테스트](#8-회귀-테스트)

---

## 1. 사전 조건

### 1.1 DB 사전 데이터

테스트 전 아래 데이터가 STG DB에 등록되어 있어야 한다.

#### DDL 실행

| # | 대상 | 비고 |
|---|------|------|
| 1 | `x01_if_event_obs` 테이블 생성 | 02-ddl.sql §4 |
| 2 | `cmon_service_inventory_master` 테이블 생성 | 02-ddl.sql §1 |
| 3 | `cmon_exception_service_detail` 테이블 생성 | 02-ddl.sql §2 |
| 4 | `cmon_maintenance_service_detail` 테이블 생성 | 02-ddl.sql §3 |
| 5 | `cmon_event_info` 컬럼 추가 (source, type, dashboard_url, dimensions) | 02-ddl.sql §5 |
| 6 | `c00_common_code` Service/Platform 공통코드 | 02-ddl.sql §6 |
| 7 | `p_combine_event_obs` 프로시저 생성 | |

#### 인벤토리 시드 (Mock 이벤트와 매칭)

```sql
-- Infra: Mock 이벤트 cursor 0001~0004, 0015와 매칭
INSERT INTO inventory_master (zabbix_ip, host_nm, control_area, host_group_nm, system_code, use_yn)
VALUES
  ('10.2.14.55', 'NEXT-GB-STG-01', 'HW', 'NEXT-Infra-Storage-DX-G-GB', 'OBS', 'Y'),
  ('10.2.14.56', 'NEXT-GB-STG-02', 'HW', 'NEXT-Infra-Storage-DX-G-GB', 'OBS', 'Y'),
  ('10.3.20.10', 'NEXT-SE-VM-01', 'VM', 'NEXT-Infra-VM-DX-G-SE', 'OBS', 'Y'),
  ('10.2.14.100', 'NEXT-GB-CSW-01', 'CSW', 'NEXT-Infra-CSW-DX-G-GB', 'OBS', 'Y');
-- 10.99.99.99 는 의도적으로 미등록 (미등록 이벤트 테스트)

-- Service/Platform: Mock 이벤트 cursor 0005~0012와 매칭
INSERT INTO cmon_service_inventory_master (service_nm, region, svc_type, host_group_nm, use_yn)
VALUES
  ('next-iam-service', 'DX-G-SE', 'service', 'NEXT-vpc-DX-G-SE', 'Y'),
  ('next-portal-service', 'DX-G-GB', 'service', 'NEXT-vpc-DX-G-GB', 'Y'),
  ('next-billing-service', 'DX-G-SE', 'service', 'NEXT-vpc-DX-G-SE', 'Y'),
  ('next-observability', 'DX-G-GB', 'platform', 'NEXT-Observability-DX-G-GB', 'Y'),
  ('next-observability', 'DX-G-SE', 'platform', 'NEXT-Observability-DX-G-SE', 'Y');
-- unknown-new-service 는 의도적으로 미등록 (미등록 이벤트 테스트)
```

> **참고**: Service target_name에는 suffix(`-abcd1234`)가 붙어서 옴. 매칭 로직은 `service_nm`이 `target_name`의 **prefix**인지 비교해야 함 (예: `next-iam-service`가 `next-iam-service-abcd1234`에 포함).

> **필드 매핑**: Mock API의 `cursor` 필드는 DB `x01_if_event_obs` 테이블의 `seq` 컬럼에 저장된다.

#### Scheduler 배치 등록

```sql
-- C01_DBCONN_INFO: Mock API 연결 정보
INSERT INTO c01_dbconn_info (system_code, db_driver, db_url, db_user_nm, db_user_pwd, use_yn)
VALUES ('ES0010', 'http', 'http://{mock-server-ip}:5050', '', '', 'Y');

-- C01_BATCH_EVENT: 배치 등록
INSERT INTO c01_batch_event (system_code, batch_title, event_sync_type, use_yn, cron_exp)
VALUES ('ES0010', '[O11y-STG] Mock 이벤트 수집', 'EST030', 'Y', '0 * * * * ?');
```

### 1.2 Mock 서버 기동

```bash
# 기본 (active 메인터넌스 4건 + expired 1건, 이벤트 15건)
python mock_server.py

# 메인터넌스 전부 만료 상태로 시작
python mock_server.py all-expired

# 특정 메인터넌스만 만료
python mock_server.py expire 0001 0002
```

### 1.3 Mock 서버 시드 데이터 요약

#### 이벤트 15건

| # | cursor (뒤 4자리) | type | status | target | event_id | event_level | 매칭 | 비고 |
|---|:-:|------|--------|--------|----------|:-----------:|:----:|------|
| 1 | 0001 | infra | firing | 10.2.14.55 | a3b1c5d9e2f4 | critical | O | |
| 2 | 0002 | infra | firing | 10.2.14.56 | b4c2d6e3f5a7 | warning | O | |
| 3 | 0003 | infra | **firing** | 10.3.20.10 | **c5d3e7f4a6b8** | warning | O | 0004의 선행 |
| 4 | 0004 | infra | **resolved** | 10.3.20.10 | **c5d3e7f4a6b8** | warning | O | 0003과 짝 |
| 5 | 0005 | service | firing | next-iam-service-abcd1234 | d6e4f8a5b7c9 | critical | O | |
| 6 | 0006 | service | firing | next-portal-service-ef567890 | e7f5a9b6c8d0 | warning | O | |
| 7 | 0007 | service | **firing** | next-billing-service-gh901234 | **f8a6b0c7d9e1** | fatal | O | 0008의 선행 |
| 8 | 0008 | service | **resolved** | next-billing-service-gh901234 | **f8a6b0c7d9e1** | fatal | O | 0007과 짝 |
| 9 | 0009 | platform | firing | next-observability | a1b7c1d8e0f2 | warning | O | |
| 10 | 0010 | platform | firing | next-observability | b2c8d2e9f1a3 | critical | O | |
| 11 | 0011 | platform | **firing** | next-observability | **c3d9e3f0a2b4** | warning | O | 0012의 선행 |
| 12 | 0012 | platform | **resolved** | next-observability | **c3d9e3f0a2b4** | warning | O | 0011과 짝 |
| 13 | 0013 | infra | firing | **10.99.99.99** | d4e0f4a1b3c5 | critical | **X** | 미등록 |
| 14 | 0014 | service | firing | **unknown-new-service-zz999999** | e5f1a5b2c4d6 | fatal | **X** | 미등록 |
| 15 | 0015 | infra | firing | 10.2.14.100 | f6a2b6c3d5e7 | warning | O | CSW |

> **firing/resolved 짝**: 같은 `event_id`를 공유. 프로시저에서 resolved 이벤트는 같은 event_id의 firing row를 UPDATE.

#### 메인터넌스 5건

| ID | title | status | 타입 |
|----|-------|--------|------|
| silence-0001 | DX-G 정기점검 | active | 복합 (infra+service+platform) |
| silence-0002 | DB서버 패치 | active | infra only |
| silence-0003 | IAM 서비스 배포 | active | service only |
| silence-0004 | Observability 플랫폼 업그레이드 | active | platform only |
| silence-0005 | 만료된 점검 (테스트용) | expired | infra |

---

## 2. 이벤트 수집 (Scheduler)

> 대상: `ObservabilityEventWorker` (EST030)
> 흐름: Mock API → X01_IF_EVENT_OBS

### TC-EVT-001: 최초 폴링 (cursor=0)

| 항목 | 내용 |
|------|------|
| **목적** | 스케줄러 최초 실행 시 전체 이벤트 수집 |
| **사전조건** | `c01_batch_event.if_idx = 0` (또는 NULL) |
| **실행** | EST030 Worker 수동 실행 또는 cron 대기 |
| **기대결과** | |
| | `x01_if_event_obs` 에 15건 INSERT |
| | `c01_batch_event.if_idx = 1739260800000000015` (마지막 cursor) |

**검증 SQL**:
```sql
SELECT count(*) FROM x01_if_event_obs WHERE system_code = 'ES0010';
-- 기대: 15

SELECT if_idx FROM c01_batch_event WHERE system_code = 'ES0010';
-- 기대: 1739260800000000015
```

### TC-EVT-002: 증분 폴링 (변화 없음)

| 항목 | 내용 |
|------|------|
| **목적** | 신규 이벤트 없을 때 빈 응답 처리 |
| **사전조건** | TC-EVT-001 이후, Mock 서버에 추가 이벤트 없음 |
| **실행** | EST030 Worker 재실행 |
| **기대결과** | |
| | API 응답: `items: [], has_more: false` |
| | `x01_if_event_obs` 추가 INSERT 없음 |
| | `c01_batch_event.if_idx` 변경 없음 |
| | 로그: "가져올 원본 데이터가 없음" |

### TC-EVT-003: has_more 페이지네이션

| 항목 | 내용 |
|------|------|
| **목적** | 대량 이벤트 시 has_more 루프 정상 동작 |
| **사전조건** | Mock 서버에 이벤트 15건 시드 (limit=5로 축소 테스트) |
| **실행** | Worker의 `FETCH_LIMIT`을 5로 설정 후 실행 |
| **기대결과** | |
| | 1차: cursor 0~5 → has_more=true, 5건 INSERT |
| | 2차: cursor 5~10 → has_more=true, 5건 INSERT |
| | 3차: cursor 10~15 → has_more=false, 5건 INSERT |
| | 총 15건 INSERT, 3회 API 호출 |

### TC-EVT-004: X01_IF_EVENT_OBS 데이터 무결성

| 항목 | 내용 |
|------|------|
| **목적** | 임시 테이블 INSERT 시 모든 필드가 정확히 매핑되는지 확인 |
| **사전조건** | TC-EVT-001 완료 |
| **실행** | - |

**검증 SQL**:
```sql
-- Infra firing 이벤트 (cursor 0001)
SELECT seq, event_id, type, status, region, zone,
       target_ip, target_name, target_contents,
       event_level, trigger_id, stdnm, occu_time, r_time,
       source, dashboard_url, dimensions
FROM x01_if_event_obs
WHERE event_id = 'a3b1c5d9e2f4';
-- 기대:
--   seq = 1739260800000000001
--   type='infra', status='firing', target_ip='10.2.14.55'
--   source='mimir', dashboard_url IS NOT NULL
--   dimensions::text LIKE '%gyeongbuk-1%'

-- Service firing 이벤트 (cursor 0005)
SELECT * FROM x01_if_event_obs WHERE event_id = 'd6e4f8a5b7c9';
-- 기대:
--   type='service', target_ip IS NULL
--   target_name='next-iam-service-abcd1234'
--   source='loki'

-- Infra resolved 이벤트 (cursor 0004, firing 0003과 동일 event_id)
SELECT * FROM x01_if_event_obs
WHERE event_id = 'c5d3e7f4a6b8' AND status = 'resolved';
-- 기대:
--   seq = 1739260800000000004
--   status='resolved', r_time = '2026-02-11T09:05:00Z'
```

### TC-EVT-005: API 연결 실패 처리

| 항목 | 내용 |
|------|------|
| **목적** | Mock 서버 중지 상태에서 Worker 에러 핸들링 |
| **사전조건** | Mock 서버 중지 |
| **실행** | EST030 Worker 실행 |
| **기대결과** | |
| | ConnectException 발생 |
| | `c01_batch_event.if_idx` 변경 없음 (롤백) |
| | 에러 로그 출력 |
| | 다음 cron에서 재시도 가능 |

### TC-EVT-006: API 응답 오류 (flag=false)

| 항목 | 내용 |
|------|------|
| **목적** | O11y API가 에러 응답을 보낸 경우 |
| **사전조건** | Mock 서버에서 flag=false 응답 반환하도록 설정 |
| **실행** | EST030 Worker 실행 |
| **기대결과** | |
| | 에러 로그: "O11y API error: {message}" |
| | `x01_if_event_obs` INSERT 없음 |
| | `c01_batch_event.if_idx` 변경 없음 |

---

## 3. 이벤트 처리 (Combine 프로시저)

> 대상: `p_combine_event_obs`
> 흐름: X01_IF_EVENT_OBS → cmon_event_info (매칭 + 예외필터)

### TC-CMB-001: Infra 이벤트 매칭 (firing)

| 항목 | 내용 |
|------|------|
| **목적** | Infra firing 이벤트가 inventory_master 매칭 후 cmon_event_info에 INSERT |
| **사전조건** | TC-EVT-001 완료 (x01_if_event_obs에 15건) |
| **실행** | `CALL p_combine_event_obs()` |
| **기대결과** | |
| | event_id `a3b1c5d9e2f4` (cursor 0001) → cmon_event_info INSERT |
| | `target_ip = '10.2.14.55'` |
| | `control_area = 'HW'` (inventory_master에서 매핑) |
| | `host_group_nm = 'NEXT-Infra-Storage-DX-G-GB'` |
| | `source = 'mimir'`, `type = 'infra'` |
| | `dashboard_url` IS NOT NULL |
| | `dimensions` JSONB 정상 저장 |

**검증 SQL**:
```sql
SELECT event_id, target_ip, control_area, host_group_nm,
       source, type, dashboard_url, dimensions
FROM cmon_event_info
WHERE event_id = 'a3b1c5d9e2f4';
```

### TC-CMB-002: resolved 이벤트 매칭 (event_id 기반 UPDATE)

| 항목 | 내용 |
|------|------|
| **목적** | resolved 이벤트가 같은 event_id의 firing row를 UPDATE |
| **사전조건** | cursor 0003 (firing, event_id: c5d3e7f4a6b8) → INSERT 완료 |
| **테스트 대상** | cursor 0004 (resolved, event_id: c5d3e7f4a6b8) |
| **실행** | `CALL p_combine_event_obs()` |
| **기대결과** | |
| | cmon_event_info에서 `event_id = 'c5d3e7f4a6b8'` 인 row UPDATE |
| | `r_time = '2026-02-11T09:05:00Z'` |
| | `status = 'resolved'` |
| | 신규 INSERT 아님 (기존 firing row 업데이트) |

> **핵심**: firing과 resolved는 **동일한 event_id**를 공유. 프로시저에서 `WHERE event_id = v_row.event_id`로 기존 firing row를 찾아 UPDATE.

**검증 SQL**:
```sql
-- firing→resolved UPDATE 확인 (infra)
SELECT event_id, status, r_time
FROM cmon_event_info
WHERE event_id = 'c5d3e7f4a6b8';
-- 기대: status='resolved', r_time='2026-02-11T09:05:00Z'

-- Service resolved도 동일 패턴 (cursor 0007→0008)
SELECT event_id, status, r_time
FROM cmon_event_info
WHERE event_id = 'f8a6b0c7d9e1';
-- 기대: status='resolved', r_time='2026-02-11T08:45:00Z'

-- Platform resolved도 동일 패턴 (cursor 0011→0012)
SELECT event_id, status, r_time
FROM cmon_event_info
WHERE event_id = 'c3d9e3f0a2b4';
-- 기대: status='resolved', r_time='2026-02-11T07:30:00Z'
```

### TC-CMB-003: Service 이벤트 매칭

| 항목 | 내용 |
|------|------|
| **목적** | Service 이벤트가 cmon_service_inventory_master 매칭 후 INSERT |
| **사전조건** | cursor 0005 이벤트 (target_name: next-iam-service-abcd1234) |
| **실행** | `CALL p_combine_event_obs()` |
| **기대결과** | |
| | `target_name`에서 suffix 제거 후 `service_nm = 'next-iam-service'` + `region = 'DX-G-SE'` 매칭 |
| | cmon_event_info INSERT |
| | `control_area = 'Service'` (svc_type에서 매핑) |
| | `host_group_nm = 'NEXT-vpc-DX-G-SE'` |
| | `source = 'loki'`, `type = 'service'` |

**검증 SQL**:
```sql
SELECT event_id, target_name, type, source, host_group_nm
FROM cmon_event_info
WHERE event_id = 'd6e4f8a5b7c9';
-- 기대: type='service', source='loki'
```

### TC-CMB-004: Platform 이벤트 매칭

| 항목 | 내용 |
|------|------|
| **목적** | Platform 이벤트가 cmon_service_inventory_master 매칭 후 INSERT |
| **사전조건** | cursor 0009 이벤트 (target_name: next-observability, region: DX-G-GB) |
| **실행** | `CALL p_combine_event_obs()` |
| **기대결과** | |
| | `service_nm = 'next-observability'` + `region = 'DX-G-GB'` 매칭 |
| | `control_area = 'Platform'` |
| | `source = 'mimir'`, `type = 'platform'` |

### TC-CMB-005: 미등록 Infra 이벤트 Skip

| 항목 | 내용 |
|------|------|
| **목적** | inventory_master에 없는 IP의 이벤트는 cmon_event_info에 저장 안 함 |
| **사전조건** | cursor 0013 이벤트 (target_ip: 10.99.99.99 — 미등록) |
| **실행** | `CALL p_combine_event_obs()` |
| **기대결과** | |
| | cmon_event_info에 해당 event_id **없음** |
| | x01_if_event_obs에 해당 row는 processed_yn = 'Y' (또는 남아있음) |

**검증 SQL**:
```sql
SELECT count(*) FROM cmon_event_info WHERE event_id = 'd4e0f4a1b3c5';
-- 기대: 0
```

### TC-CMB-006: 미등록 Service 이벤트 Skip

| 항목 | 내용 |
|------|------|
| **목적** | cmon_service_inventory_master에 없는 서비스의 이벤트는 저장 안 함 |
| **사전조건** | cursor 0014 이벤트 (target_name: unknown-new-service-zz999999 — 미등록) |
| **실행** | `CALL p_combine_event_obs()` |
| **기대결과** | |
| | cmon_event_info에 해당 event_id **없음** |
| | 미등록 알림 대상으로 남아있음 (§7 참고) |

### TC-CMB-007: 처리 결과 집계

| 항목 | 내용 |
|------|------|
| **목적** | 전체 15건 처리 후 cmon_event_info 최종 건수 확인 |
| **실행** | TC-CMB-001~006 완료 후 |

**검증 SQL**:
```sql
-- 전체 등록 건수
-- 15건 중 미등록 2건(cursor 0013, 0014) 제외 = 13건
-- firing 10건 → INSERT 10건
-- resolved 3건(cursor 0004, 0008, 0012) → 같은 event_id의 firing row UPDATE
-- 최종: cmon_event_info에 10 rows
SELECT count(*) FROM cmon_event_info WHERE source IN ('mimir', 'loki');
-- 기대: 10

-- 타입별 건수
SELECT type, count(*) FROM cmon_event_info
WHERE source IN ('mimir', 'loki')
GROUP BY type;
-- 기대: infra=4, service=3, platform=3
-- infra: 0001, 0002, 0003(→resolved), 0015 = 4건
-- service: 0005, 0006, 0007(→resolved) = 3건
-- platform: 0009, 0010, 0011(→resolved) = 3건

-- status별 건수
SELECT status, count(*) FROM cmon_event_info
WHERE source IN ('mimir', 'loki')
GROUP BY status;
-- 기대: firing=7, resolved=3
```

---

## 4. 이벤트 조회 (Web)

> 대상: luppiter_web 이벤트 조회 화면
> 흐름: 사용자 → Web → DB (UNION ALL 쿼리)

### TC-VIEW-001: 이벤트 목록 통합 조회

| 항목 | 내용 |
|------|------|
| **목적** | infra + service + platform 이벤트가 하나의 목록에 통합 표시 |
| **사전조건** | §3 프로시저 실행 완료 (cmon_event_info에 이벤트 존재) |
| **실행** | 이벤트 상황관리 화면 진입 |
| **기대결과** | |
| | Infra 이벤트 (10.2.14.55 등) 표시 |
| | Service 이벤트 (next-iam-service 등) 표시 |
| | Platform 이벤트 (next-observability 등) 표시 |
| | 모든 이벤트가 한 테이블에 혼합 표시 |

### TC-VIEW-002: source 컬럼 표시

| 항목 | 내용 |
|------|------|
| **목적** | 연동시스템 구분 컬럼이 정상 표시 |
| **실행** | 이벤트 목록 조회 |
| **기대결과** | |
| | Infra 이벤트: source = `mimir` |
| | Service 이벤트: source = `loki` |
| | 기존 Zabbix 이벤트: source = `zabbix` |

### TC-VIEW-003: dashboard_url 하이퍼링크

| 항목 | 내용 |
|------|------|
| **목적** | dashboard_url이 있는 이벤트에 클릭 가능한 링크 표시 |
| **실행** | 이벤트 목록에서 cursor 0001 이벤트 확인 |
| **기대결과** | |
| | 이벤트 제목 클릭 시 `https://grafana.example.com/d/hw-cpu?...` 로 이동 |
| | dashboard_url이 NULL인 이벤트(cursor 0006 등)는 링크 없이 텍스트만 표시 |

### TC-VIEW-004: 관제영역 필터 확장

| 항목 | 내용 |
|------|------|
| **목적** | 관제영역 드롭다운에 Service, Platform 추가 |
| **실행** | 이벤트 목록 화면 필터 드롭다운 확인 |
| **기대결과** | |
| | 기존: CSW, HW, NW, VM |
| | 추가: **Service**, **Platform** |
| | Service 선택 시 service 이벤트만 필터 |
| | Platform 선택 시 platform 이벤트만 필터 |

### TC-VIEW-005: 대시보드 서비스 이벤트 집계

| 항목 | 내용 |
|------|------|
| **목적** | 관제 대시보드에 서비스/플랫폼 이벤트 건수 반영 |
| **실행** | 관제 대시보드 화면 진입 |
| **기대결과** | |
| | 센터별 장비 수 집계에 서비스 인벤토리 포함 |
| | 이벤트 현황에 O11y 이벤트 건수 포함 |
| | UNION ALL 쿼리 적용 확인 (sql-dashboard.xml) |

---

## 5. 메인터넌스 관리 (Web → O11y API)

> 대상: luppiter_web 메인터넌스 화면 → Mock API
> API 엔드포인트: `http://{mock-server}:5050/api/v1/maintenance/*`

### TC-MNT-001: 메인터넌스 생성 — Infra 단독

| 항목 | 내용 |
|------|------|
| **목적** | Infra 대상 메인터넌스 생성 시 O11y API 정상 호출 |
| **실행** | 메인터넌스 등록 → 타입: Infra(O11y) → 대상: 10.2.14.55 (DX-G-GB) |
| **기대결과** | |
| | `POST /api/v1/maintenance/create` 호출 |
| | 요청 body: `targets[0].type = "infra"`, `targets[0].target_ip = "10.2.14.55"` |
| | 응답: `flag: true`, `maintenance_id` 반환 |
| | DB: `cmon_maintenance_event` INSERT |
| | DB: `cmon_maintenance_event_detail` INSERT (Infra용) |
| | DB: `maintenance_id` 저장 (O11y API 응답값) |

### TC-MNT-002: 메인터넌스 생성 — Service 단독

| 항목 | 내용 |
|------|------|
| **목적** | Service 대상 메인터넌스 생성 |
| **실행** | 메인터넌스 등록 → 타입: Service → 대상: next-iam-service (DX-G-SE) |
| **기대결과** | |
| | 요청 body: `targets[0].type = "service"`, `targets[0].target_name = "next-iam-service"` |
| | 응답: `flag: true` |
| | DB: `cmon_maintenance_service_detail` INSERT (Service용) |

### TC-MNT-003: 메인터넌스 생성 — 복합 (Infra + Service + Platform)

| 항목 | 내용 |
|------|------|
| **목적** | 복합 타입 대상을 한 번에 등록 |
| **실행** | 메인터넌스 등록 → 대상: infra(10.2.14.55) + service(next-iam-service) + platform(next-observability) |
| **기대결과** | |
| | 단일 API 호출에 targets 3건 포함 |
| | DB: `cmon_maintenance_event_detail` 1건 + `cmon_maintenance_service_detail` 2건 |

### TC-MNT-004: 메인터넌스 수정 — 대상 추가/삭제

| 항목 | 내용 |
|------|------|
| **목적** | 기존 메인터넌스에 대상 추가(A) / 삭제(R) |
| **사전조건** | TC-MNT-001에서 생성한 maintenance_id |
| **실행** | 메인터넌스 수정 → 대상 추가: 10.2.14.56 (action: A) |
| **기대결과** | |
| | `PUT /api/v1/maintenance/update` 호출 |
| | 요청 body: `targets[0].action = "A"` |
| | 응답: `flag: true`, `updated_at` 반환 |
| | DB: `cmon_maintenance_event_detail` 1건 추가 |

### TC-MNT-005: 메인터넌스 종료

| 항목 | 내용 |
|------|------|
| **목적** | 메인터넌스 종료 시 O11y API expire 호출 |
| **사전조건** | TC-MNT-001에서 생성한 maintenance_id |
| **실행** | 메인터넌스 종료 버튼 클릭 |
| **기대결과** | |
| | `POST /api/v1/maintenance/expire` 호출 |
| | 응답: `flag: true`, `status: "expired"` |
| | DB: `device_status = '종료'` UPDATE |

### TC-MNT-006: 메인터넌스 조회 (상태 동기화)

| 항목 | 내용 |
|------|------|
| **목적** | 메인터넌스 목록에서 O11y 상태 조회 |
| **사전조건** | O11y 측에서 직접 만료한 경우 (Mock: silence-0005 expired) |
| **실행** | 메인터넌스 목록 화면 진입 |
| **기대결과** | |
| | `POST /api/v1/maintenance/get` 호출 |
| | DB와 API 상태 비교 → 불일치 시 동기화 |

### TC-MNT-007: O11y API 실패 시 롤백

| 항목 | 내용 |
|------|------|
| **목적** | API 호출 실패 시 DB 저장도 롤백 |
| **사전조건** | Mock 서버 중지 |
| **실행** | 메인터넌스 등록 시도 |
| **기대결과** | |
| | API 연결 실패 |
| | DB: INSERT 롤백 (cmon_maintenance_event, detail 모두) |
| | 화면: 에러 메시지 표시 ("O11y API 연결 실패") |

### TC-MNT-008: Zenius 메인터넌스 미지원

| 항목 | 내용 |
|------|------|
| **목적** | Zenius 장비에 대한 메인터넌스 등록 차단 |
| **실행** | 메인터넌스 등록 → 타입 선택 팝업 |
| **기대결과** | |
| | Zenius는 팝업에서 "미지원" 안내 |
| | 등록 불가 |

---

## 6. 예외 관리 (Web → DB)

> 대상: luppiter_web 예외 관리 화면
> 특징: API 연동 없음, DB 자체 관리
> 이벤트 목록: `cmon_event_info`에서 DISTINCT 조회 (발생 이력 기반, Zabbix API trigger 방식과 다름)

**이벤트 목록 조회 쿼리 (참고)**:
```sql
-- Infra: 해당 IP에서 발생한 이벤트 목록
SELECT DISTINCT target_item, trigger_id
FROM cmon_event_info
WHERE target_ip = :target_ip
  AND source IN ('mimir', 'loki')
  AND type = 'infra';

-- Service/Platform: 해당 서비스에서 발생한 이벤트 목록
-- 참고: target_name → cmon_event_info.hostname 매핑 (01-design.md §4.2)
SELECT DISTINCT target_item, trigger_id
FROM cmon_event_info
WHERE hostname = :target_name
  AND source IN ('mimir', 'loki')
  AND type = :svc_type;
```

### TC-EXC-001: Infra 예외 등록

| 항목 | 내용 |
|------|------|
| **목적** | O11y Infra 대상 예외 등록 |
| **사전조건** | §3 프로시저 완료 (cmon_event_info에 10.2.14.55 이벤트 존재) |
| **실행** | 예외 등록 → 타입: Infra(O11y) → 대상: 10.2.14.55 선택 → 이벤트 목록에서 "CPU 사용량" 선택 |
| **기대결과** | |
| | 이벤트 목록: `cmon_event_info`에서 10.2.14.55의 DISTINCT 이벤트만 표시 |
| | DB: `cmon_exception_event` INSERT |
| | DB: `cmon_exception_event_detail` INSERT (기존 테이블) |
| | 해당 IP의 해당 trigger 이벤트가 향후 필터링됨 |

### TC-EXC-002: Service 예외 등록

| 항목 | 내용 |
|------|------|
| **목적** | Service 대상 예외 등록 (신규 테이블 사용) |
| **사전조건** | §3 프로시저 완료 (cmon_event_info에 next-iam-service 이벤트 존재) |
| **실행** | 예외 등록 → 타입: Service → 대상: next-iam-service (DX-G-SE) → 이벤트 목록에서 선택 |
| **기대결과** | |
| | 이벤트 목록: `cmon_event_info`에서 next-iam-service의 DISTINCT 이벤트만 표시 |
| | DB: `cmon_exception_event` INSERT |
| | DB: `cmon_exception_service_detail` INSERT (**신규 테이블**) |
| | `svc_type = 'service'`, `service_nm`, `region` 저장 |

### TC-EXC-003: Platform 예외 등록

| 항목 | 내용 |
|------|------|
| **목적** | Platform 대상 예외 등록 |
| **사전조건** | §3 프로시저 완료 (cmon_event_info에 next-observability 이벤트 존재) |
| **실행** | 예외 등록 → 타입: Platform → 대상: next-observability (DX-G-GB) → 이벤트 목록에서 선택 |
| **기대결과** | |
| | 이벤트 목록: `cmon_event_info`에서 next-observability의 DISTINCT 이벤트만 표시 |
| | DB: `cmon_exception_service_detail` INSERT |
| | `svc_type = 'platform'` |

### TC-EXC-004: 예외 이벤트 필터링 검증

| 항목 | 내용 |
|------|------|
| **목적** | 예외 등록 후 해당 이벤트가 실제 필터링되는지 확인 |
| **사전조건** | TC-EXC-001 완료 (10.2.14.55 CPU 이벤트 예외 등록) |
| **실행** | Mock 서버 재시작 → Scheduler Worker 재실행 → 프로시저 실행 |
| **기대결과** | |
| | cursor 0001 이벤트 (10.2.14.55, trigger: rule-uid-hw-001) |
| | 프로시저에서 예외 체크 → cmon_event_info에 INSERT 안 됨 |

**검증 SQL**:
```sql
-- 예외 등록 확인
SELECT * FROM cmon_exception_event_detail
WHERE target_ip = '10.2.14.55';

-- 프로시저 실행 후, 해당 이벤트가 필터링되었는지
-- (이전에 INSERT된 이벤트는 삭제 안 됨, 신규 수집분만 필터)
```

### TC-EXC-005: 타입별 화면 분기

| 항목 | 내용 |
|------|------|
| **목적** | 예외 등록 팝업에서 타입별 컬럼 표시 분기 |
| **실행** | 예외 등록 → 타입 선택 팝업 |
| **기대결과** | |
| | Infra 선택: IP, 장비위치, 설비바코드 등 전체 컬럼 표시 |
| | Service 선택: Infra 전용 컬럼 제외, 서비스명/리전 표시 |
| | Platform 선택: Service와 동일 레이아웃 |

---

## 7. 미등록 이벤트 알림

> 대상: UnregisteredEventAlarmServiceJob
> 흐름: X01_IF_EVENT_OBS에서 미등록 건 조회 → Slack 알림

### TC-UNREG-001: 미등록 Infra 이벤트 알림

| 항목 | 내용 |
|------|------|
| **목적** | inventory_master에 없는 IP의 이벤트 → Slack 알림 |
| **사전조건** | cursor 0013 이벤트 수집 완료 (target_ip: 10.99.99.99) |
| **실행** | UnregisteredEventAlarmServiceJob 실행 |
| **기대결과** | |
| | x01_if_event_obs에서 10.99.99.99가 inventory_master에 매칭 안 됨 감지 |
| | Slack #luppiter-unregistered-events 채널 알림 |
| | 알림 내용: IP, 이벤트 내용, 리전 등 |

### TC-UNREG-002: 미등록 Service 이벤트 알림

| 항목 | 내용 |
|------|------|
| **목적** | cmon_service_inventory_master에 없는 서비스의 이벤트 → Slack 알림 |
| **사전조건** | cursor 0014 이벤트 수집 완료 (target_name: unknown-new-service-zz999999) |
| **실행** | UnregisteredEventAlarmServiceJob 실행 |
| **기대결과** | |
| | 매칭 실패 감지 |
| | Slack 알림: 서비스명, 리전, 이벤트 내용 |

---

## 8. 회귀 테스트

> 대상: EventWorkerFactory 구조 변경 후 기존 시스템 정상 동작 확인

### TC-REG-001: Zabbix Worker (EST010/011) 정상 동작

| 항목 | 내용 |
|------|------|
| **목적** | Factory abstract combine() 추가 후 기존 Zabbix 이벤트 수집 정상 |
| **실행** | EST010 Worker 수동 실행 |
| **기대결과** | |
| | Zabbix API 폴링 정상 |
| | combineEventForZabbix 프로시저 정상 호출 |
| | cmon_event_info INSERT 정상 |

### TC-REG-002: Zenius Worker (EST020) 정상 동작

| 항목 | 내용 |
|------|------|
| **목적** | 기존 Zenius 이벤트 수집 정상 |
| **실행** | EST020 Worker 수동 실행 |
| **기대결과** | |
| | Zenius DB 폴링 정상 |
| | combineEventForZenius 프로시저 정상 호출 |

### TC-REG-003: 대시보드 기존 데이터 정상 표시

| 항목 | 내용 |
|------|------|
| **목적** | UNION ALL 적용 후 기존 Zabbix/Zenius 이벤트 정상 표시 |
| **실행** | 관제 대시보드 화면 진입 |
| **기대결과** | |
| | 기존 센터별 장비 수 변동 없음 (또는 서비스 인벤토리 추가분만 증가) |
| | 기존 이벤트 건수 정상 |
| | source가 NULL인 기존 이벤트 → 마이그레이션으로 'zabbix' 세팅 확인 |

### TC-REG-004: 엑셀 다운로드 정상

| 항목 | 내용 |
|------|------|
| **목적** | 이벤트 엑셀 다운로드에 서비스 이벤트 포함 |
| **실행** | 이벤트 이력 → 엑셀 다운로드 |
| **기대결과** | |
| | O11y 이벤트 포함 |
| | source, type 컬럼 표시 |

---

## 테스트 실행 순서 (권장)

```
1. DB 사전 데이터 세팅 (§1.1)
2. Mock 서버 기동 (§1.2)

--- 이벤트 수집 ---
3. TC-EVT-001: 최초 폴링 (15건)
4. TC-EVT-004: 데이터 무결성 확인
5. TC-EVT-002: 증분 폴링 (빈 응답)

--- 이벤트 처리 ---
6. TC-CMB-001: Infra firing 매칭
7. TC-CMB-002: resolved event_id 기반 UPDATE
8. TC-CMB-003~004: Service/Platform 매칭
9. TC-CMB-005~006: 미등록 Skip
10. TC-CMB-007: 집계 확인 (10 rows)

--- Web 조회 ---
11. TC-VIEW-001~005: 이벤트 목록/대시보드

--- 예외 관리 ---
12. TC-EXC-001~003: 타입별 예외 등록
13. TC-EXC-004: 필터링 검증

--- 메인터넌스 ---
14. TC-MNT-001~003: 생성 (타입별)
15. TC-MNT-004: 수정
16. TC-MNT-005: 종료
17. TC-MNT-007: API 실패 롤백

--- 미등록 알림 ---
18. TC-UNREG-001~002: Slack 알림

--- 회귀 ---
19. TC-REG-001~004: 기존 시스템 정상
```

---

## 관련 문서

| 문서 | 내용 |
|------|------|
| [01-design.md](01-design.md) | 설계 개요 |
| [04-functional-spec.md](04-functional-spec.md) | 기능별 상세 설계 |
| [05-api-spec-maintenance.md](05-api-spec-maintenance.md) | 메인터넌스 API 스펙 |
| [06-scheduler-api-migration.md](06-scheduler-api-migration.md) | Scheduler DB→API 전환 설계 |
| [implementation-guide.md](implementation-guide.md) | 구현 가이드 |
| [Confluence: STG O11y Mock API 서버](https://ktcloud.atlassian.net/wiki/spaces/SREP/pages/1731430138) | Mock 서버 사용 가이드 |
