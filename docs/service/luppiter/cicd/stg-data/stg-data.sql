-- ============================================
-- STG 전용 데이터 INSERT 스크립트
-- 운영 DB 복원 후 실행
-- ============================================

-- 1. STG 계위 (7건)
-- ============================================
DELETE FROM cmon_layer_code_info WHERE layer_cd LIKE 'STG%';

INSERT INTO cmon_layer_code_info (layer_cd, layer_nm, p_layer_cd, layer, delete_yn, cret_dt, cretr_id) VALUES
('STG', 'STG', NULL, 1, 'N', NOW(), 'SYSTEM'),
('STG2', 'STG2', 'STG', 2, 'N', NOW(), 'SYSTEM'),
('STG3', 'STG3', 'STG2', 3, 'N', NOW(), 'SYSTEM'),
('STG3_STG_zone', 'STG_zone', 'STG3', 4, 'N', NOW(), 'SYSTEM'),
('STG3_STG_zone_CSW', 'STG_STG3_STG_zone_CSW', 'STG3_STG_zone', 5, 'N', NOW(), 'SYSTEM'),
('STG3_STG_zone_HW', 'STG_STG3_STG_zone_HW', 'STG3_STG_zone', 5, 'N', NOW(), 'SYSTEM'),
('STG3_STG_zone_HW_AP', 'STG_STG3_STG_zone_HW_AP', 'STG3_STG_zone', 5, 'N', NOW(), 'SYSTEM');

-- 2. STG 인벤토리 (16건)
-- ============================================
DELETE FROM inventory_master
WHERE host_group_nm LIKE '%STG%'
   OR l1_layer_cd = 'STG'
   OR l2_layer_cd LIKE 'STG%'
   OR l3_layer_cd LIKE 'STG%';

INSERT INTO inventory_master (host_nm, zabbix_ip, zone, host_group_id, control_area, host_group_nm, l1_layer_cd, l2_layer_cd, l3_layer_cd, system_code, created_dt) VALUES
('202502_TEST_STG_host_03', '192.168.32.103', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_10', '192.168.32.110', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_11', '192.168.32.111', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_11', '192.168.33.111', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_12', '192.168.32.112', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_12', '192.168.33.112', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_13', '192.168.32.113', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_13', '192.168.33.113', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_14', '192.168.32.114', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_14', '192.168.33.114', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_15', '192.168.32.115', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_15', '192.168.33.115', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_18', '192.168.32.18', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_19', '192.168.32.119', '삭제대상', 213, 'CSW', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_19', '192.168.32.219', '삭제대상', 213, 'CSW', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW()),
('202502_TEST_STG_host_20', '192.168.32.120', '삭제대상', 213, 'STG', '삭제대상_삭제대상_삭제대상_STG', 'LZ', 'LZZ', 'JPT9999', 'ES9002', NOW());

-- 3. ES9* 배치 설정 (3건)
-- ============================================
DELETE FROM c01_batch_event WHERE system_code LIKE 'ES9%';

INSERT INTO c01_batch_event (system_code, batch_title, batch_desc, cron_exp, use_yn, system_ip, event_sync_type, created_dt, created_id) VALUES
('ES9001', '[DEV] Zabbix 이벤트 수집', 'Zabbix v5.x', '0 * * * * ?', 'N', '10.2.14.54', 'EST010', NOW(), 'SYSTEM'),
('ES9002', '[STG] Zabbix 이벤트 수집', 'Zabbix v5.x', '0 * * * * ?', 'Y', '10.4.224.93', 'EST010', NOW(), 'SYSTEM'),
('ES9004', '[STG-URL] Zabbix 이벤트 수집', 'Zabbix v7.x', '0 * * * * ?', 'N', '10.2.14.199', 'EST010', NOW(), 'SYSTEM');

-- 4. ES9* Zabbix 정보 (2건)
-- ============================================
DELETE FROM c01_zabbix_info WHERE system_code LIKE 'ES9%';

INSERT INTO c01_zabbix_info (system_code, zabbix_domain, zabbix_version, api_uri, api_id, api_pwd, agent_ip, use_yn, cret_dt, cretr_id) VALUES
('ES9001', 'https://dev-zabbix.ktcloud.com/zabbix', '5.0', '/api_jsonrpc.php', 'luppiter', 'B0s08Pqvi8rGPxfYu7Ddiw==', '10.2.14.54', 'N', NOW(), 'SYSTEM'),
('ES9002', 'https://stg-zabbix.ktcloud.com/zabbix', '5.0', '/api_jsonrpc.php', 'luppiter', 'B0s08Pqvi8rGPxfYu7Ddiw==', '10.4.224.93', 'Y', NOW(), 'SYSTEM');

-- 5. STG 권한그룹 (전체 사용자 매핑)
-- ============================================
INSERT INTO cmon_group (group_id, group_nm, delete_yn, cret_dt, cretr_id)
SELECT 'STG_GROUP', 'STG 테스트 그룹', 'N', NOW(), 'SYSTEM'
WHERE NOT EXISTS (SELECT 1 FROM cmon_group WHERE group_id = 'STG_GROUP');

DELETE FROM cmon_group_layer WHERE group_id = 'STG_GROUP';
DELETE FROM cmon_group_user WHERE group_id = 'STG_GROUP';

INSERT INTO cmon_group_layer (group_id, layer_cd, layer, cret_dt, cretr_id)
SELECT 'STG_GROUP', layer_cd, layer, NOW(), 'SYSTEM'
FROM cmon_layer_code_info
WHERE layer_cd LIKE 'STG%' AND layer = 5;

INSERT INTO cmon_group_user (group_id, user_id, delete_yn, cret_dt, cretr_id)
SELECT 'STG_GROUP', user_id, 'N', NOW(), 'SYSTEM'
FROM cmon_user;

-- ============================================
-- 최종 업데이트: 2026-02-03
-- ============================================
