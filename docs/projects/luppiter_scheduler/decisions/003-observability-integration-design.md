# ADR-003: Observability 이벤트 연동 설계

## 상태
진행중 (브레인스토밍 완료, 개발 전)

## 날짜
2026-01-19

## 컨텍스트
- NEXT에서 운영중인 Infra/Platform 이벤트 관제를 Luppiter로 통합
- 기존 Zabbix/Zenius 연동과 동일한 패턴(seq 기반 DB 연동) 적용
- 이벤트 타입: Infra(CSW, HW, NW, VM), Service, Platform

## 결정 사항

### 1. Worker 구조
**결정**: 단일 ObservabilityEventWorker (EST030)
- 프로시저에서 Infra/Service/Platform 타입별 분기 처리
- 이유: 단일 테이블, 단일 seq, 동일한 스케줄링 주기

```
EventWorkerFactory
├── EST010 → ZabbixEventWorker (v5)
├── EST011 → ZabbixEventWorker (v7)
├── EST020 → ZeniusEventWorker
└── EST030 → ObservabilityEventWorker (신규)
```

### 2. 키 매핑 전략
**결정**: 타입별 다른 키 사용
| 타입 | 키 | 매칭 대상 |
|------|-----|----------|
| Infra (CSW, HW, NW, VM) | target_ip | inventory_master |
| Service | target_name + region | cmon_service_inventory_master |
| Platform | target_name + region | cmon_service_inventory_master |

### 3. Service/Platform 등록 테이블
**결정**: 신규 테이블 생성 (cmon_service_inventory_master)
- 기존 inventory_master와 동일한 패턴
- 등록된 대상만 호스트그룹 자동생성 및 이벤트 처리

```sql
CREATE TABLE cmon_service_inventory_master (
    svc_inv_seq         SERIAL PRIMARY KEY,
    service_nm          VARCHAR(100) NOT NULL,  -- target_name 매칭
    region              VARCHAR(30) NOT NULL,   -- region 매칭
    svc_type            VARCHAR(20) NOT NULL,   -- 'service' | 'platform'
    l1_layer_cd         VARCHAR(50),
    l2_layer_cd         VARCHAR(50),
    l3_layer_cd         VARCHAR(50),            -- 표준서비스
    zone                VARCHAR(30),            -- L4
    host_group_nm       VARCHAR(200),           -- 자동생성
    use_yn              CHAR(1) DEFAULT 'Y',
    cretr_id            VARCHAR(50),
    cret_dt             TIMESTAMP DEFAULT NOW(),
    UNIQUE (service_nm, region)
);
```

### 4. 계위 구조
**결정**: Infra와 동일한 L1~L4 코드 구조 사용
- 기존 cmon_layer_code_info 활용
- L2 도메인: `_인프라`, `_서비스`, `_플랫폼` 구분
- L3 표준서비스: 사전 등록된 코드 사용

### 5. 예외/메인터넌스 테이블 확장
**결정**: 별도 테이블 분리 (옵션 B)
```
기존 유지:
├── CMON_EXCEPTION_EVENT              (마스터 - 공통)
├── CMON_EXCEPTION_EVENT_DETAIL       (Infra용)
└── CMON_EXCEPTION_EVENT_HISTORY      (이력 - 공통)

신규 추가:
└── CMON_EXCEPTION_SERVICE_DETAIL     (Service/Platform용)
```

### 5-1. 타입 선택 UI (2026-01-21 추가)
**결정**: 버튼 클릭 → 선택 팝업 방식 (탭 분리 → 변경)

**선택 팝업 옵션**:
| 타입 | 연동 시스템 |
|------|------------|
| Infra | Zabbix, Zenius, Observability |
| Service | Observability |
| Platform | Observability |

**타입별 컬럼 표시**:
- Infra: 전체 컬럼 (IP, 장비위치, 설비바코드 등)
- Service/Platform: Infra 전용 컬럼 제외 (MGMT IP, IPMI IP, 설비바코드, 장비위치)

### 6. 이벤트 통합 저장
**결정**: cmon_event_info에 통합 + 컬럼 추가
```sql
ALTER TABLE cmon_event_info ADD COLUMN source VARCHAR(20);        -- zabbix|zenius|grafana|mimir|loki
ALTER TABLE cmon_event_info ADD COLUMN dashboard_url VARCHAR(2048);
ALTER TABLE cmon_event_info ADD COLUMN dimensions JSONB;
```

### 7. 미등록 서비스 알림 (미결정)
- 다음 세션에서 결정 필요
- Slack 채널명, 알림 내용, 저장 여부

## 연동 데이터 흐름

```
Observability DB
    ↓ (seq 기반 증분 연동)
ObservabilityEventWorker (EST030)
    ↓
X01_IF_EVENT_OBS (임시 테이블)
    ↓ (프로시저)
cmon_event_info (통합 이벤트 테이블)
    ↓
├── Infra: inventory_master 매칭 (IP)
└── Service/Platform: cmon_service_inventory_master 매칭 (name+region)
```

## 일정
- 개발 완료: 2026년 2월 2주차 (2월 13일)
- 검증 완료: 2026년 2월 4주차 (2월 27일)

## 참고
- 요구사항: https://ktcloud.atlassian.net/wiki/spaces/SREP/pages/1560215751/Next
- DB 스키마: https://ktcloud.atlassian.net/wiki/x/hAZZX
