-- ============================================================
-- Observability 연동 DDL
-- 작성일: 2026-01-20
-- ============================================================

-- ============================================================
-- 1. cmon_service_inventory_master
-- 용도: Service/Platform 등록 관리 (Observability 이벤트 매칭용)
-- ============================================================

CREATE TABLE cmon_service_inventory_master (
    svc_inv_seq         SERIAL PRIMARY KEY,
    service_nm          VARCHAR(100) NOT NULL,      -- Observability target_name과 매칭
    region              VARCHAR(30) NOT NULL,       -- Observability region과 매칭
    svc_type            VARCHAR(20) NOT NULL,       -- 'service' | 'platform'
    l1_layer_cd         VARCHAR(50),                -- 분류
    l2_layer_cd         VARCHAR(50),                -- 도메인
    l3_layer_cd         VARCHAR(50),                -- 표준서비스
    zone                VARCHAR(30),                -- L4 (Zone)
    host_group_nm       VARCHAR(200),               -- 호스트그룹 (자동생성)
    use_yn              CHAR(1) DEFAULT 'Y',
    cretr_id            VARCHAR(50),
    cret_dt             TIMESTAMP DEFAULT NOW(),
    CONSTRAINT uk_service_inven관제 tory UNIQUE (service_nm, region)
);

CREATE INDEX idx_svc_inv_service_nm ON cmon_service_inventory_master(service_nm);
CREATE INDEX idx_svc_inv_region ON cmon_service_inventory_master(region);
CREATE INDEX idx_svc_inv_svc_type ON cmon_service_inventory_master(svc_type);
CREATE INDEX idx_svc_inv_use_yn ON cmon_service_inventory_master(use_yn);

COMMENT ON TABLE cmon_service_inventory_master IS 'Service/Platform 인벤토리 마스터';
COMMENT ON COLUMN cmon_service_inventory_master.svc_inv_seq IS '일련번호';
COMMENT ON COLUMN cmon_service_inventory_master.service_nm IS '서비스/플랫폼명 (Observability target_name)';
COMMENT ON COLUMN cmon_service_inventory_master.region IS '리전 (Observability region)';
COMMENT ON COLUMN cmon_service_inventory_master.svc_type IS '타입 (service/platform)';
COMMENT ON COLUMN cmon_service_inventory_master.host_group_nm IS '호스트그룹명 (자동생성)';


-- ============================================================
-- 2. cmon_exception_service_detail
-- 용도: Service/Platform 예외 등록 시 대상 정보 저장
-- ============================================================

CREATE TABLE cmon_exception_service_detail (
    excp_seq            INTEGER NOT NULL,           -- FK → CMON_EXCEPTION_EVENT
    svc_type            VARCHAR(20) NOT NULL,       -- 'service' | 'platform'
    service_nm          VARCHAR(100),
    region              VARCHAR(30),
    evt_code            VARCHAR(50),
    evt_name            VARCHAR(200),
    trigger_id          BIGINT,
    delete_yn           CHAR(1) DEFAULT 'N',
    cretr_id            VARCHAR(50),
    cret_dt             TIMESTAMP DEFAULT NOW(),
    CONSTRAINT fk_excp_service_detail
        FOREIGN KEY (excp_seq) REFERENCES cmon_exception_event(excp_seq)
);

CREATE INDEX idx_excp_svc_detail_seq ON cmon_exception_service_detail(excp_seq);
CREATE INDEX idx_excp_svc_detail_service ON cmon_exception_service_detail(service_nm, region);
CREATE INDEX idx_excp_svc_detail_delete ON cmon_exception_service_detail(delete_yn);

COMMENT ON TABLE cmon_exception_service_detail IS '예외 이벤트 상세 - Service/Platform용';


-- ============================================================
-- 3. cmon_maintenance_service_detail
-- 용도: Service/Platform 메인터넌스 등록 시 대상 정보 저장
-- ============================================================

CREATE TABLE cmon_maintenance_service_detail (
    seq                 INTEGER NOT NULL,           -- FK → cmon_maintenance_main.seq
    svc_type            VARCHAR(20) NOT NULL,       -- 'service' | 'platform'
    service_nm          VARCHAR(100),
    region              VARCHAR(30),
    evt_code            VARCHAR(50),
    evt_name            VARCHAR(200),
    trigger_id          BIGINT,
    device_status       VARCHAR(20),                -- 활성 | 대기중 | 종료
    delete_yn           CHAR(1) DEFAULT 'N',
    cretr_id            VARCHAR(50),
    cret_dt             TIMESTAMP DEFAULT NOW(),
    amdr_id             VARCHAR(50),
    amd_dt              TIMESTAMP,
    CONSTRAINT fk_maint_service_detail
        FOREIGN KEY (seq) REFERENCES cmon_maintenance_main(seq)
);

CREATE INDEX idx_maint_svc_detail_seq ON cmon_maintenance_service_detail(seq);
CREATE INDEX idx_maint_svc_detail_service ON cmon_maintenance_service_detail(service_nm, region);
CREATE INDEX idx_maint_svc_detail_status ON cmon_maintenance_service_detail(device_status);

COMMENT ON TABLE cmon_maintenance_service_detail IS '메인터넌스 상세 - Service/Platform용';


-- ============================================================
-- 4. x01_if_event_obs
-- 용도: Observability DB에서 수집한 이벤트 임시 저장
-- ============================================================

CREATE TABLE x01_if_event_obs (
    seq                 BIGINT NOT NULL,            -- 시퀀스 (연동 기준)
    event_id            VARCHAR(30) NOT NULL,       -- Fingerprint
    type                VARCHAR(30),                -- infra | service | platform
    status              VARCHAR(20),                -- firing | resolved
    region              VARCHAR(30),
    zone                VARCHAR(30),
    target_ip           VARCHAR(20),                -- Infra용
    target_name         VARCHAR(100),               -- Service/Platform용
    target_contents     VARCHAR(1000),
    event_level         VARCHAR(20),                -- critical | fatal
    trigger_id          BIGINT,
    stdnm               VARCHAR(50),                -- 표준서비스명
    occu_time           TIMESTAMP,                  -- 발생 시간
    r_time              TIMESTAMP,                  -- 해소 시간
    source              VARCHAR(20),                -- grafana | mimir | loki
    dashboard_url       VARCHAR(2048),
    dimensions          JSONB,
    if_dt               TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_if_event_obs_seq ON x01_if_event_obs(seq);
CREATE INDEX idx_if_event_obs_type ON x01_if_event_obs(type);
CREATE INDEX idx_if_event_obs_target_ip ON x01_if_event_obs(target_ip);
CREATE INDEX idx_if_event_obs_target_nm ON x01_if_event_obs(target_name, region);

COMMENT ON TABLE x01_if_event_obs IS 'Observability 이벤트 임시 연동 테이블';


-- ============================================================
-- 5. cmon_event_info 컬럼 추가
-- 용도: Observability 이벤트 연동을 위한 신규 컬럼
-- ============================================================

-- source: 연동 시스템 구분
ALTER TABLE cmon_event_info
ADD COLUMN IF NOT EXISTS source VARCHAR(20);

COMMENT ON COLUMN cmon_event_info.source IS '연동시스템 (zabbix/zenius/grafana/mimir/loki)';

-- type: 이벤트 타입 구분
ALTER TABLE cmon_event_info
ADD COLUMN IF NOT EXISTS type VARCHAR(20);

COMMENT ON COLUMN cmon_event_info.type IS '이벤트타입 (infra/service/platform)';

-- dashboard_url: Alert Dashboard URL
ALTER TABLE cmon_event_info
ADD COLUMN IF NOT EXISTS dashboard_url VARCHAR(2048);

COMMENT ON COLUMN cmon_event_info.dashboard_url IS 'Alert 확인용 Dashboard URL';

-- dimensions: 추가 정보 (JSONB)
ALTER TABLE cmon_event_info
ADD COLUMN IF NOT EXISTS dimensions JSONB;

COMMENT ON COLUMN cmon_event_info.dimensions IS '추가 정보 식별자 (JSON)';

-- 인덱스
CREATE INDEX IF NOT EXISTS idx_event_info_source ON cmon_event_info(source);
CREATE INDEX IF NOT EXISTS idx_event_info_type ON cmon_event_info(type);


-- ============================================================
-- (선택) 기존 데이터 UPDATE
-- ============================================================

-- 기존 Zabbix 이벤트에 source, type 설정
-- UPDATE cmon_event_info SET source = 'zabbix', type = 'infra' WHERE source IS NULL;
