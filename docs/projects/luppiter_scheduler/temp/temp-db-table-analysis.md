# Luppiter 데이터베이스 테이블 사용 현황 분석

## 분석일
2026-01-22

## 대상 프로젝트
- luppiter_web
- luppiter_scheduler

---

## 요약

| 구분 | 개수 | 비율 |
|------|------|------|
| **사용** | 54개 | 69% |
| **미사용** | 24개 | 31% |
| **총계** | 78개 | 100% |

---

## 사용 테이블 (54개)

| 테이블명 | Web | Scheduler | 주요 용도 |
|----------|:---:|:---------:|----------|
| c00_common_code | ✅ | ✅ | 공통코드 |
| c00_system_properties | ✅ | ✅ | 시스템 설정 |
| c01_batch_common | | ✅ | 배치 공통 |
| c01_batch_event | ✅ | ✅ | 배치 이벤트 |
| c01_batch_shed_lock | | ✅ | 배치 락 |
| c01_dbconn_info | | ✅ | DB 연결정보 |
| c01_event_function_mapping | ✅ | | 이벤트 함수 매핑 |
| c01_zabbix_info | ✅ | ✅ | Zabbix 정보 |
| c02_zone_type_mapping | ✅ | | Zone 타입 매핑 |
| cmon_agent_info | ✅ | | 에이전트 정보 |
| cmon_custom_column | ✅ | | 커스텀 컬럼 |
| cmon_daily_chart | ✅ | | 일별 차트 |
| cmon_event_exception | ✅ | | 이벤트 예외 |
| cmon_event_info | ✅ | ✅ | **핵심 이벤트** |
| cmon_event_resp_manage_info | ✅ | | 이벤트 대응관리 |
| cmon_exception_event | ✅ | | 예외 이벤트 |
| cmon_exception_event_detail | ✅ | | 예외 이벤트 상세 |
| cmon_exception_event_history | ✅ | | 예외 이벤트 이력 |
| cmon_exception_event_mail | ✅ | ✅ | 예외 이벤트 메일 |
| cmon_group | ✅ | | 그룹 |
| cmon_group_layer | ✅ | | 그룹 레이어 |
| cmon_group_layer_history | ✅ | | 그룹 레이어 이력 |
| cmon_group_user | ✅ | | 그룹 사용자 |
| cmon_group_user_history | ✅ | | 그룹 사용자 이력 |
| cmon_idc_list | ✅ | | IDC 목록 |
| cmon_incident_event_info | ✅ | | 인시던트 이벤트 |
| cmon_incident_info | ✅ | | 인시던트 정보 |
| cmon_incident_proc | ✅ | | 인시던트 처리 |
| cmon_layer_code_info | ✅ | | 레이어 코드 |
| cmon_maintenance_detail | ✅ | ✅ | 메인터넌스 상세 |
| cmon_maintenance_history | ✅ | ✅ | 메인터넌스 이력 |
| cmon_maintenance_mail | ✅ | ✅ | 메인터넌스 메일 |
| cmon_maintenance_main | ✅ | ✅ | 메인터넌스 메인 |
| cmon_maintenance_mapping | ✅ | ✅ | 메인터넌스 매핑 |
| cmon_refine_event | ✅ | | 정제 이벤트 |
| cmon_refine_event_detail | ✅ | | 정제 이벤트 상세 |
| cmon_resp_manage_info | ✅ | | 대응관리 정보 |
| cmon_resp_manage_info_history | ✅ | | 대응관리 이력 |
| cmon_user | ✅ | ✅ | 사용자 |
| cmon_zabbix_info | ✅ | ✅ | Zabbix 연동 |
| group_code_info | ✅ | | 그룹 코드 |
| inventory_master | ✅ | | **인벤토리 마스터** |
| inventory_master_history | ✅ | | 인벤토리 이력 |
| inventory_master_sub | ✅ | | 인벤토리 서브 |
| p03_host_manage_detail | ✅ | ✅ | 호스트 관리 상세 |
| p03_host_manage_hist | | ✅ | 호스트 관리 이력 |
| p03_host_manage_mst | ✅ | ✅ | 호스트 관리 마스터 |
| p03_host_manage_template | ✅ | | 호스트 관리 템플릿 |
| p04_alarm_service_mapping | ✅ | ✅ | 알람 서비스 매핑 |
| x00_batch_event_log | | ✅ | 배치 이벤트 로그 |
| x00_batch_log | | ✅ | 배치 로그 |
| x01_if_event_data | ✅ | ✅ | 이벤트 연동 |
| x01_if_event_zenius | | ✅ | Zenius 이벤트 연동 |

---

## 미사용 테이블 (24개)

| 테이블명 | 추정 용도 | 비고 |
|----------|----------|------|
| agent_message | 에이전트 메시지 | 미구현/폐기 |
| cmon_agent_target_list | 에이전트 타겟 | 미구현/폐기 |
| cmon_event_group | 이벤트 그룹 | 미구현/폐기 |
| cmon_incident_contact | 인시던트 연락처 | 미구현/폐기 |
| cmon_login_log | 로그인 로그 | 미구현/폐기 |
| cmon_refine_event_history | 정제 이벤트 이력 | 미구현/폐기 |
| cmon_resp_lv_info | 대응 레벨 정보 | 미구현/폐기 |
| cmon_user_sessions | 사용자 세션 | 미구현/폐기 |
| dcim_cabinet_info_inbot | DCIM 캐비닛 | DCIM 연동 미사용 |
| dcim_device_info_inbot | DCIM 장비 | DCIM 연동 미사용 |
| event_received_message | 수신 메시지 | 미구현/폐기 |
| inventory_dcim_cabinet | 인벤토리 DCIM | DCIM 연동 미사용 |
| inventory_dcim_device | 인벤토리 DCIM | DCIM 연동 미사용 |
| inventory_itam | 인벤토리 ITAM | ITAM 연동 미사용 |
| inventory_master_excel | 엑셀 업로드용 | 일회성/임시 |
| inventory_master_form | 폼 데이터용 | 일회성/임시 |
| itsm_infra_change | ITSM 인프라 변경 | ITSM 연동 미사용 |
| itsm_tam_change | ITSM TAM 변경 | ITSM 연동 미사용 |
| message_send_log | 메시지 발송 로그 | 미구현/폐기 |
| p03_host_remove_detail | 호스트 삭제 상세 | 미구현/폐기 |
| p03_host_remove_hist | 호스트 삭제 이력 | 미구현/폐기 |
| p03_host_remove_mst | 호스트 삭제 마스터 | 미구현/폐기 |
| p04_slack_event_targets | Slack 이벤트 | 미구현/폐기 |
| sms_send_message | SMS 발송 | 미구현/폐기 |

---

## 미사용 테이블 분류

| 분류 | 테이블 수 | 테이블 |
|------|----------|--------|
| DCIM/ITAM 연동 | 5개 | dcim_*, inventory_dcim_*, inventory_itam |
| ITSM 연동 | 2개 | itsm_* |
| 호스트 삭제 | 3개 | p03_host_remove_* |
| 메시지/알림 | 4개 | *_message, sms_*, p04_slack_* |
| 기타 폐기 | 10개 | cmon_login_log, cmon_user_sessions 등 |

---

## DROP TABLE 리스크 분석

### 리스크 매트릭스

| 리스크 | 영향도 | 대응 |
|--------|--------|------|
| FK 참조 | 🔴 높음 | DROP 실패 또는 연쇄 삭제 |
| View/Procedure 참조 | 🔴 높음 | 오류 발생 |
| 외부 시스템 참조 | 🟡 중간 | 연동 오류 |
| 데이터 복구 필요 | 🟡 중간 | 백업 필수 |
| 용량 | 🟢 낮음 | 500MB 미만 - 무시 가능 |

### 테이블별 리스크 분류

#### 🟢 낮은 리스크 (즉시 삭제 가능) - 14개

| 테이블 | 이유 |
|--------|------|
| inventory_master_excel | 임시 업로드용, 일회성 |
| inventory_master_form | 임시 폼 데이터, 일회성 |
| cmon_refine_event_history | 이력 테이블, 참조 없음 |
| cmon_login_log | 로그 테이블, 참조 없음 |
| cmon_user_sessions | 세션 테이블, 참조 없음 |
| event_received_message | 메시지 로그, 참조 없음 |
| message_send_log | 발송 로그, 참조 없음 |
| sms_send_message | SMS 로그, 참조 없음 |
| agent_message | 메시지 로그, 참조 없음 |
| cmon_agent_target_list | 단독 테이블 |
| cmon_event_group | 단독 테이블 |
| cmon_resp_lv_info | 단독 테이블 |
| p04_slack_event_targets | 단독 테이블 |
| cmon_incident_contact | 단독 테이블 |

#### 🟡 중간 리스크 (확인 후 삭제) - 7개

| 테이블 | 리스크 | 확인 필요 |
|--------|--------|----------|
| dcim_cabinet_info_inbot | 외부 연동 | DCIM 시스템 연동 여부 |
| dcim_device_info_inbot | 외부 연동 | DCIM 시스템 연동 여부 |
| inventory_dcim_cabinet | 외부 연동 | DCIM 시스템 연동 여부 |
| inventory_dcim_device | 외부 연동 | DCIM 시스템 연동 여부 |
| inventory_itam | 외부 연동 | ITAM 시스템 연동 여부 |
| itsm_infra_change | 외부 연동 | ITSM 시스템 연동 여부 |
| itsm_tam_change | 외부 연동 | ITSM 시스템 연동 여부 |

#### 🟠 주의 필요 (FK 확인 필수) - 3개

| 테이블 | 리스크 | 확인 필요 |
|--------|--------|----------|
| p03_host_remove_mst | FK 가능성 | detail, hist 테이블과 관계 |
| p03_host_remove_detail | FK 가능성 | mst 테이블 참조 |
| p03_host_remove_hist | FK 가능성 | mst 테이블 참조 |

---

## 삭제 전 확인 스크립트

### FK 참조 확인

```sql
SELECT
    tc.table_name AS child_table,
    kcu.column_name AS fk_column,
    ccu.table_name AS parent_table
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
AND ccu.table_name IN (
    'agent_message', 'cmon_agent_target_list', 'cmon_event_group',
    'cmon_incident_contact', 'cmon_login_log', 'cmon_refine_event_history',
    'cmon_resp_lv_info', 'cmon_user_sessions', 'dcim_cabinet_info_inbot',
    'dcim_device_info_inbot', 'event_received_message', 'inventory_dcim_cabinet',
    'inventory_dcim_device', 'inventory_itam', 'inventory_master_excel',
    'inventory_master_form', 'itsm_infra_change', 'itsm_tam_change',
    'message_send_log', 'p03_host_remove_detail', 'p03_host_remove_hist',
    'p03_host_remove_mst', 'p04_slack_event_targets', 'sms_send_message'
);
```

### View 참조 확인

```sql
SELECT DISTINCT v.table_name AS view_name, d.table_name AS referenced_table
FROM information_schema.views v
JOIN information_schema.view_table_usage d ON v.table_name = d.view_name
WHERE d.table_name IN (
    'agent_message', 'cmon_agent_target_list', 'cmon_event_group',
    'cmon_incident_contact', 'cmon_login_log', 'cmon_refine_event_history',
    'cmon_resp_lv_info', 'cmon_user_sessions', 'dcim_cabinet_info_inbot',
    'dcim_device_info_inbot', 'event_received_message', 'inventory_dcim_cabinet',
    'inventory_dcim_device', 'inventory_itam', 'inventory_master_excel',
    'inventory_master_form', 'itsm_infra_change', 'itsm_tam_change',
    'message_send_log', 'p03_host_remove_detail', 'p03_host_remove_hist',
    'p03_host_remove_mst', 'p04_slack_event_targets', 'sms_send_message'
);
```

---

## 권장 삭제 절차

### Phase 1: 낮은 리스크 (14개)

```sql
BEGIN;

DROP TABLE IF EXISTS inventory_master_excel;
DROP TABLE IF EXISTS inventory_master_form;
DROP TABLE IF EXISTS cmon_refine_event_history;
DROP TABLE IF EXISTS cmon_login_log;
DROP TABLE IF EXISTS cmon_user_sessions;
DROP TABLE IF EXISTS event_received_message;
DROP TABLE IF EXISTS message_send_log;
DROP TABLE IF EXISTS sms_send_message;
DROP TABLE IF EXISTS agent_message;
DROP TABLE IF EXISTS cmon_agent_target_list;
DROP TABLE IF EXISTS cmon_event_group;
DROP TABLE IF EXISTS cmon_resp_lv_info;
DROP TABLE IF EXISTS p04_slack_event_targets;
DROP TABLE IF EXISTS cmon_incident_contact;

-- 확인 후 COMMIT 또는 ROLLBACK
-- COMMIT;
```

### Phase 2: 중간 리스크 - 외부 연동 확인 후 (7개)

```sql
BEGIN;

DROP TABLE IF EXISTS dcim_cabinet_info_inbot;
DROP TABLE IF EXISTS dcim_device_info_inbot;
DROP TABLE IF EXISTS inventory_dcim_cabinet;
DROP TABLE IF EXISTS inventory_dcim_device;
DROP TABLE IF EXISTS inventory_itam;
DROP TABLE IF EXISTS itsm_infra_change;
DROP TABLE IF EXISTS itsm_tam_change;

-- COMMIT;
```

### Phase 3: FK 확인 후 (3개) - 순서 중요

```sql
BEGIN;

DROP TABLE IF EXISTS p03_host_remove_hist;    -- 자식 먼저
DROP TABLE IF EXISTS p03_host_remove_detail;  -- 자식 먼저
DROP TABLE IF EXISTS p03_host_remove_mst;     -- 부모 마지막

-- COMMIT;
```

---

## 결론

| 구분 | 개수 | 액션 |
|------|------|------|
| 🟢 즉시 삭제 | 14개 | 백업 후 바로 DROP |
| 🟡 확인 후 삭제 | 7개 | 외부 시스템 담당자 확인 |
| 🟠 FK 확인 | 3개 | 위 스크립트로 확인 후 순서대로 |

**총 리스크**: 🟢 **낮음** (용량 적고, 코드 참조 없음, 백업하면 복구 가능)
