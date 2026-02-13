---
tags:
  - type/tasks
  - service/luppiter
  - service/luppiter/o11y
  - audience/personal
  - personal/82253890
---

> 상위: [next-observability](README.md) · [docs](../../README.md)

# O11y 리뷰 추적 문서

> 이 문서는 세션 간 컨텍스트 유지용. 새 세션에서 "o11y" 키워드로 요청 시 이 파일을 먼저 읽는다.
> 최종 업데이트: 2026-02-13 (개발사 diff 코드리뷰 3건 완료)
> **현재 단계: 개발사 코드 완료 → 코드리뷰 + 통합테스트 검증 중**

---

## 1. 현재 상황 요약

- **설계**: 내가 담당 (이 저장소 docs/)
- **개발**: 개발사 완료 (workspace/ 프로젝트에 반영됨)
- **단계**: 코드리뷰 + 통합테스트 검증
- **레퍼런스 구현**: feature/o11y 브랜치 (luppiter_web, luppiter_scheduler)
- **통합테스트 시나리오**: 07-integration-test.md

---

## 2. Confluence 스펙 변경 이력

### v30 (2026-02-11) — O11y View Table 변경

Confluence: "유피테르 이벤트 테이블 연동 관련" (page ID: 1549338244)

#### 2.1 타입/사이즈 변경

| 컬럼 | 기존 (로컬 DDL) | 변경 (Confluence v30) | 영향도 |
|------|-----------------|----------------------|--------|
| trigger_id | BIGINT | **varchar(50)** | CRITICAL — Rule UID가 문자열 (`rule-uid-hw-001`) |
| target_ip | varchar(20) | varchar(45) | 사이즈 증가 (IPv6 대비) |
| target_name | varchar(100) | varchar(256) | 사이즈 증가 |
| target_contents | varchar(1000) | varchar(2048) | 사이즈 증가 |

#### 2.2 NOT NULL 변경

| 컬럼 | 기존 | 변경 |
|------|------|------|
| type | nullable | NOT NULL |
| event_level | nullable | NOT NULL |

#### 2.3 삭제/추가

- 삭제: `event_drt_id`
- 추가 (이미 로컬 반영됨): `status`, `dashboard_url`, `stdnm`, `source`, `dimensions`

---

## 3. 설계 결정 사항

### 3.1 obs_event_id 컬럼 추가 (2026-02-12 결정)

- **배경**: `cmon_event_info.if_event_id`는 int8 (Zabbix용). O11y event_id는 varchar(30) fingerprint → int8에 저장 불가
- **결정**: `obs_event_id` VARCHAR(30) 별도 컬럼 추가
- **대안 검토**:
  - `if_event_id`를 varchar로 ALTER → 리스크 큼 (테이블 REWRITE, 기존 프로시저 전수 수정, 서비스 중단)
  - `if_event_key` → 범용적이나 의미 모호
  - `obs_event_id` → 기존 `x01_if_event_obs` 네이밍과 일관, 직관적
- **배포 영향**: nullable ADD COLUMN → 무중단

### 3.2 trigger_id 호환성 (2026-02-12 확인)

- **문제**: `cmon_event_info.trigger_id`는 int8. O11y trigger_id는 varchar(50) Rule UID
- **방향 미결정**: obs_trigger_id 별도 컬럼 추가 or 기존 trigger_id varchar 변환 검토 필요
- **TODO**: 기존 trigger_id 사용처 영향도 분석 후 결정

---

## 4. 통합테스트 시나리오 검증 결과 (2026-02-12)

> 07-integration-test.md 시나리오를 실제 코드(프로시저, Worker, DDL) 대비 검증

### 4.1 CRITICAL — 수정 필요

| # | 항목 | TC | 상세 | 상태 |
|---|------|-----|------|------|
| C1 | Service target_name prefix 매칭 미구현 | TC-CMB-003,004 | 프로시저 `svc_mst.service_nm = xeo.target_name` (정확일치). Mock은 suffix 포함 (`next-iam-service-abcd1234`). INNER JOIN 실패로 Service/Platform 전건 누락 | **결정: 방안A** — 프로시저 LIKE prefix 매칭으로 수정 요청. 07-integration-test.md 반영 완료 |
| C2 | event_level 필터로 warning 누락 | TC-CMB-007 | 설계 스펙상 O11y API는 critical/fatal만 발생 (01-design.md:135). 프로시저 정상 | **결정: Mock 데이터 수정** — warning→critical 변경. 07-integration-test.md 반영 완료 |
| C3 | 검증 SQL event_id vs obs_event_id 혼동 | TC-CMB-001~006 | `WHERE event_id = 'xxx'` → `WHERE obs_event_id = 'xxx'` (cmon_event_info.event_id는 시퀀스) | [x] 07-integration-test.md 수정 완료 |
| C4 | resolved UPDATE 컬럼 불일치 | TC-CMB-002 | 테스트 `status='resolved'` 기대. 실제 프로시저는 `zabbix_state='해소'` + `r_time` UPDATE. `status` 컬럼 없음 | [x] 07-integration-test.md 수정 완료 |

### 4.2 HIGH — 수정 필요

| # | 항목 | TC | 상세 | 상태 |
|---|------|-----|------|------|
| H1 | processed_yn 컬럼 미존재 | TC-CMB-005 | DDL에 해당 컬럼 없음. 프로시저는 처리 후 DELETE 방식 | [x] 07-integration-test.md 수정 완료 |
| H2 | gubun vs control_area 컬럼명 | TC-CMB-001,003 | cmon_event_info에는 `gubun` 컬럼으로 저장. 테스트는 `control_area` 참조 | [x] 07-integration-test.md 수정 완료 |
| H3 | svc_type 대소문자 | TC-CMB-003 | 테스트 `control_area='Service'` (Pascal). 실제 `gubun='service'` (lower) | [x] 07-integration-test.md 수정 완료 |
| H4 | Mock 서버 미존재 | §1.2 | `workspace/o11y-mock/mock_server.py` 생성 완료. API 계약 수정: cursor→seq, since_cursor→since_seq, items→events, last_cursor→last_seq, warning→critical | [x] |
| H5 | system_code 불일치 | §1.1, TC-EVT-001 | `ES0010` 통일 완료 (06-scheduler-api-migration.md 기준). implementation-guide.md OBS001→ES0010 수정 | [x] |

### 4.3 MEDIUM — 확인/보완 필요

| # | 항목 | TC | 상세 | 상태 |
|---|------|-----|------|------|
| M1 | TC-EVT-003 FETCH_LIMIT 변경 불가 | TC-EVT-003 | Worker의 `FETCH_LIMIT=1000` (상수). 테스트에서 5로 변경하려면 빌드 변경 필요 | [ ] |
| M2 | TC-EVT-001 cursor→seq 매핑 명확화 | TC-EVT-001 | `if_idx` vs `sync_idx` 컬럼 — Worker는 `if_idx`, 프로시저는 `sync_idx` 사용 | [ ] |
| M3 | TC-MNT API 엔드포인트 경로 | TC-MNT-001~008 | 테스트 `/api/v1/maintenance/create`, 실제 구현 확인 필요 | [ ] |
| M4 | TC-UNREG Slack 알림 테이블 | TC-UNREG-001,002 | `x01_unregistered_event_alert` 테이블 DDL 없음 (구현 가이드에만 참조) | [ ] |

### 4.4 정상 확인된 항목

| 항목 | TC | 확인 내용 |
|------|-----|----------|
| x01_if_event_obs DDL | TC-EVT-004 | 테이블 구조, PK, 컬럼 타입 일치 |
| SQL Injection 방어 | 전체 | MyBatis `#{}` 파라미터 바인딩 사용 |
| Worker API 패턴 | TC-EVT-001~006 | REST API 호출 + has_more 페이지네이션 정상 |
| Infra 매칭 로직 | TC-CMB-001 | `inventory_master.zabbix_ip = xeo.target_ip` INNER JOIN 정상 |
| 미등록 Infra Skip | TC-CMB-005 | INNER JOIN 미매칭 시 자동 제외 (정상) |
| 해소 이벤트 UPDATE | TC-CMB-002 | `obs_event_id` 기반 매칭으로 firing row UPDATE (로직 정상) |
| 예외 필터 | TC-EXC-004 | 프로시저 LEFT JOIN + event_state='예외' 정상 |
| 대응관리 INSERT | 프로시저 §1-3 | `cmon_event_resp_manage_info` INSERT + ON CONFLICT DO NOTHING |

---

## 5. 코드리뷰 결과 (2026-02-12)

### 5.1 luppiter_web (feature/o11y, c2ad4b9d) — 25 파일

| 심각도 | 건수 | 상태 |
|--------|------|------|
| CRITICAL | 3 | 레퍼런스 커밋 완료 (MEDIUM까지 수정) |
| HIGH | 3 | 레퍼런스 커밋 완료 |
| MEDIUM | 6 | 레퍼런스 커밋 완료 (4건 수정, 2건 참고) |

#### CRITICAL 수정사항

| # | 내용 | 파일 | 수정 |
|---|------|------|------|
| C1 | ex.printStackTrace() → log.error() | EvtController.java (serviceDeviceList) | 미수정 — 개발사 코드에서 확인 필요 |
| C2 | removeServiceInventory @Transactional 누락 | InventoryManagerServiceImpl.java | 미수정 — 개발사 확인 필요 |
| C3 | createServiceMaintenance catch가 예외 삼킴 → @Transactional 롤백 불가 | ZabServiceImpl.java | 미수정 — 개발사 확인 필요 |

### 5.2 luppiter_scheduler — 검증 완료

| 항목 | 결과 |
|------|------|
| ObservabilityEventWorker | API 호출 패턴, 에러 처리, 페이지네이션 정상 |
| EventWorkerFactory EST030 | enum 등록, combine 메서드 연결 정상 |
| p_combine_event_obs | Infra/Service/Platform 분기, 해소 UPDATE, 대응관리 INSERT 구조 정상 |
| EventBatchMapper.xml | insertTempEventObs, combineEventForObs CALL 정상 |

### 5.3 개발사 전달용 코드리뷰 피드백

| # | 심각도 | 항목 | 대상 |
|---|--------|------|------|
| 1 | CRITICAL | Service target_name prefix 매칭 미구현 | p_combine_event_obs JOIN 조건 |
| 2 | CRITICAL | ex.printStackTrace() 사용 | EvtController.java |
| 3 | CRITICAL | @Transactional 누락 | InventoryManagerServiceImpl.removeServiceInventory |
| 4 | CRITICAL | catch 내 예외 삼킴 → 롤백 불가 | ZabServiceImpl.createServiceMaintenance |
| 5 | HIGH | switch default 없음 (monitorType) | InventoryManagerController |
| 6 | HIGH | prompt() XSS 미검증 | subMaintenanceRegistPop.jsp |
| 7 | HIGH | INFO 레벨 과다 로깅 | EvtExcpService.java |

### 5.4 개발사 diff 코드리뷰 (2026-02-12~13)

> 개발사가 제출한 diff 파일을 feature/o11y 레퍼런스와 비교 → Jira 댓글로 피드백

| LUPR | 기능 | CRITICAL | HIGH | MEDIUM | Jira 댓글 | 상태 |
|------|------|----------|------|--------|-----------|------|
| LUPR-683 | 이벤트 예외 관리 기능 개선 | 1 | 2 | 2 | 174787 | 완료 |
| LUPR-684 | 메인터넌스 관리 기능 개선 | 3 | 5 | 1 | 174817 | 완료 |
| LUPR-692 | 관제삭제 기능 OBS 확장 | 3 | 2 | 0 | 174837 | 완료 |

#### LUPR-683 주요 이슈

| # | 심각도 | 내용 |
|---|--------|------|
| C1 | CRITICAL | obsMaintenanceRegistPop.jsp — system_code 하드코딩 누락 |
| H1 | HIGH | 서비스 메인터넌스 등록 시 silence_id 미저장 |
| H2 | HIGH | 예외 등록 팝업 — 타입 선택 후 초기화 누락 |

#### LUPR-684 주요 이슈

| # | 심각도 | 내용 |
|---|--------|------|
| C1 | CRITICAL | toUtcFormat() — KST→UTC 변환 없이 'Z' 접미사만 추가 |
| C2 | CRITICAL | expireMaintenance type 파라미터 누락 |
| C3 | CRITICAL | saveMaintenanceObs/deleteMaintenanceObs resultMap 덮어쓰기 |
| H1 | HIGH | maintenanceMail() NPE — type null 시 크래시 |
| H2 | HIGH | flag 누적 버그 — 복수 호스트 처리 시 이전 값 잔류 |
| H3 | HIGH | SQL endhost vs hosts 키 불일치 |
| H4 | HIGH | deleteMaintenanceHostList OR→AND 논리 오류 |
| H5 | HIGH | == 참조 비교 (String) |

#### LUPR-692 주요 이슈

| # | 심각도 | 내용 |
|---|--------|------|
| C1 | CRITICAL | getRemoveManageDetailList() — result 변수 덮어쓰기로 INFRA 호스트 데이터 소실 |
| C2 | CRITICAL | removeInfraInventory/removeServiceInventory — hostCloseMaintenance 결과 NPE |
| C3 | CRITICAL | removeInfraInventory/removeServiceInventory — @Transactional 누락 |
| H1 | HIGH | insertServiceInventoryHistory SQL — type, control_area 모두 svc_type 매핑 |
| H2 | HIGH | selectObsInfraMaintenanceList SQL 주석 ID 불일치 (복사-붙여넣기) |

---

## 6. 프로젝트별 변경 체크리스트

### 6.1 DDL (공통)

| # | 변경 내용 | 상태 | 비고 |
|---|----------|------|------|
| 1 | x01_if_event_obs: trigger_id BIGINT → VARCHAR(50) | [x] | Confluence v30 |
| 2 | x01_if_event_obs: target_ip VARCHAR(20) → VARCHAR(45) | [x] | Confluence v30 |
| 3 | x01_if_event_obs: target_name VARCHAR(100) → VARCHAR(256) | [x] | Confluence v30 |
| 4 | x01_if_event_obs: target_contents VARCHAR(1000) → VARCHAR(2048) | [x] | Confluence v30 |
| 5 | x01_if_event_obs: type, event_level → NOT NULL | [x] | Confluence v30 |
| 6 | cmon_event_info: ADD obs_event_id VARCHAR(30) | [x] | 설계 결정 3.1 |
| 7 | cmon_event_info: trigger_id 호환 방안 | [ ] | 설계 결정 3.2 미결 |
| 8 | cmon_service_inventory_master 생성 | [x] | DDL |
| 9 | cmon_exception_service_detail 생성 | [x] | DDL |
| 10 | cmon_maintenance_service_detail 생성 | [x] | DDL |
| 11 | cmon_event_info: ADD source, type, dashboard_url, dimensions | [x] | DDL |
| 12 | 공통코드 CONTROL_AREA Service/Platform 추가 | [x] | DML |
| 13 | 기존 이벤트 source='zabbix', type='infra' 마이그레이션 | [x] | DML |
| 14 | p_combine_event_obs 프로시저 생성 | [x] | Scheduler DDML |
| 15 | c01_batch_event EST030 등록 | [x] | DML |

### 6.2 Scheduler (luppiter_scheduler)

| # | 파일/영역 | 변경 내용 | 상태 | 비고 |
|---|----------|----------|------|------|
| 1 | ObservabilityEventWorker | O11y API → 임시 테이블 적재 | [x] | API 방식 구현 완료 |
| 2 | EventWorkerFactory | EST030 등록 + combine 메서드 | [x] | 완료 |
| 3 | EventBatchMapper | insertTempEventObs + combineEventForObs | [x] | 완료 |
| 4 | p_combine_event_obs | Infra/Service/Platform 분기 프로시저 | [x] | 완료 (prefix 매칭 버그 있음 → C1) |
| 5 | MaintenanceAlarmServiceMapper.xml | 서비스 인벤토리 UNION 적용 | [ ] | 미확인 |
| 6 | ExceptionEventAlarmServiceMapper.xml | 서비스 인벤토리 UNION 적용 | [ ] | 미확인 |
| 7 | CombineEventServiceJob | combineEventForObs 호출 연결 | [x] | Factory pattern 통해 호출 |

### 6.3 Web (luppiter_web)

| # | 파일/영역 | 변경 내용 | 상태 | LUPR |
|---|----------|----------|------|------|
| 1 | 서비스/플랫폼 등록 화면 | 신규 화면 (DDL, DML) | [x] | LUPR-687 |
| 2 | sql-evt.xml | 이벤트 조회 — source, dashboard_url + UNION ALL | [x] | LUPR-690,699 |
| 3 | sql-dashboard.xml | 대시보드 — 서비스 인벤토리 UNION (7개 쿼리) | [x] | LUPR-699 |
| 4 | sql-evt-excp.xml | 예외 — 타입 선택 팝업, Service/Platform 분기 | [x] | LUPR-683 |
| 5 | sql-evt-cmm.xml | 예외/메인터넌스 공통 장비 조회 UNION | [x] | LUPR-699 |
| 6 | sql-icd.xml | 인시던트 검색 조건 UNION (2개 쿼리) | [x] | LUPR-699 |
| 7 | 메인터넌스 화면 | 타입 선택 팝업, 서비스 메인터넌스 | [x] | LUPR-684 |
| 8 | 관제 삭제 화면 | 탭 분리: Zabbix/Zenius/O11y | [x] | LUPR-692 |
| 9 | 코드리뷰 수정 | CRITICAL 3 + HIGH 3 + MEDIUM 4 | [x] | 레퍼런스 커밋 |

---

## 7. 다음 작업 (TODO)

### 7.1 통합테스트 시나리오 수정 (07-integration-test.md)

- [x] C1: **결정 — 방안A** 프로시저 LIKE prefix 매칭. 개발사에 수정 요청
- [x] C2: **결정 — Mock 데이터 수정**. 설계대로 critical/fatal만. warning→critical 변경 완료
- [x] C3: 검증 SQL `event_id` → `obs_event_id` 수정 완료
- [x] C4: 검증 SQL `status='resolved'` → `zabbix_state='해소'` 수정 완료
- [x] H1: `processed_yn` → DELETE 방식 반영 완료
- [x] H2,H3: `control_area` → `gubun`, 대소문자 수정 완료
- [x] H4: Mock 서버 생성 완료 (workspace/o11y-mock/mock_server.py)
  - Worker API 계약 일치: since_seq, events[], last_seq, seq 필드
  - event_level: 전건 critical/fatal (C2 결정 반영)
  - 기존 test-o11y-mock/ 대비 변경: cursor→seq, items→events, warning→critical
- [x] H5: system_code `ES0010` 통일 완료
  - 근거: 06-scheduler-api-migration.md (설계 확정문서)
  - implementation-guide.md 3건 수정 (OBS001→ES0010)

### 7.2 개발사 피드백 전달

- [ ] 프로시저 prefix 매칭 버그 (C1) — 최우선
- [ ] 코드리뷰 CRITICAL 3건 (C2,C3,C4 from §5.1)
- [ ] 코드리뷰 HIGH 3건
- [x] LUPR-683 diff 리뷰 — Jira 댓글 174787 (C1, H2, M2)
- [x] LUPR-684 diff 리뷰 — Jira 댓글 174817 (C3, H5, M1)
- [x] LUPR-692 diff 리뷰 — Jira 댓글 174837 (C3, H2)

### 7.3 Scheduler UNION ALL 미확인 항목

- [ ] MaintenanceAlarmServiceMapper.xml 확인
- [ ] ExceptionEventAlarmServiceMapper.xml 확인

---

## 8. 리뷰 시 확인 포인트

### 코드 리뷰 체크리스트

- [x] UNION ALL 패턴이 04-functional-spec.md 9.7절 패턴과 일치하는가
- [x] 서비스 인벤토리 컬럼 매핑이 04-functional-spec.md 9.6절과 일치하는가
- [x] 예외/메인터넌스 신규 테이블 FK 정합성
- [x] obs_event_id가 이벤트 pairing (firing ↔ resolved)에 올바르게 사용되는가
- [ ] trigger_id varchar 호환 처리가 기존 Zabbix 프로시저에 영향 없는가 — 미결 (§3.2)
- [x] 공통코드 CONTROL_AREA에 Service/Platform 추가되었는가
- [ ] c02_zone_type_mapping에 O11y zone 값 등록되었는가 — 확인 필요

---

## 9. 관련 문서

| 문서 | 용도 |
|------|------|
| 01-design.md | 전체 설계 |
| 02-ddl.sql | DDL 스크립트 |
| 04-functional-spec.md | 기능별 상세 + UNION 패턴 + 영향도 |
| 05-api-spec-maintenance.md | 메인터넌스 API 스펙 |
| 06-scheduler-api-migration.md | Scheduler DB→API 전환 |
| 07-integration-test.md | 통합테스트 시나리오 |
| Confluence 1549338244 | O11y View Table 원장 (v30) |
| Confluence 1560215751 | 요구사항 정의 (v22) |
