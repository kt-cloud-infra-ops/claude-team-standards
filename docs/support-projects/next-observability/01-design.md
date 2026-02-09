# Observability 연동 설계

## 개요

NEXT에서 운영중인 Infra/Platform 이벤트 관제를 Luppiter로 통합

- **프로젝트**: luppiter_scheduler + luppiter_web
- **연동 방식**: DB 연동 (seq 기반 증분)
- **일정**: 개발 2/13, 검증 2/27

---

## 1. 요구사항

### 1.1 공통
- 업무 프로세스는 기존 업무프로세스에 준해 관리 (예: 호스트 등록 → ITSM)
- 기존 데이터에 준하는 이벤트 연동 및 데이터 수집 (권한체계 포함)

### 1.2 연동 데이터

**이벤트 타입**:

| 타입 | Key | 관제영역 |
|------|-----|---------|
| Infra (CSW, HW, NW, VM) | IP | CSW, HW, NW, VM |
| Service | 표준서비스 + 존 | Service |
| Platform | 표준서비스 + 존 | Platform |

**처리 조건**:
- Infra: inventory_master에 등록된 대상만 처리
- Service/Platform: cmon_service_inventory_master에 등록된 대상만 처리

**연동 데이터 부가정보**:
- Infra는 인벤토리 값과 매핑
- Service/Platform 계위는 유피테르에서 추가해 일원화 관리
- 서비스명/플랫폼명과 리전존을 키로 관리
- 미등록 이벤트는 별도 Slack 채널로 알림

### 1.3 서비스/플랫폼 관리 화면

**등록**:
- 서비스/플랫폼, namespace, 리전(존), 표준서비스 입력
- 호스트그룹 자동생성

**삭제**:
- 목록에서 서비스/플랫폼 정보 삭제
- 삭제는 기존 프로세스처럼 별도 요청

### 1.4 계위 관리 화면
- 서비스/플랫폼에 계위를 관리하기 위한 추가/수정
- 삭제는 별도 데이터 변경 요청
- 호스트그룹은 자동생성

### 1.5 예외/메인터넌스 기능
- infra, service, platform 타입별 화면 분기
- **예외**: 등록/삭제 등
- **메인터넌스**: 등록, 삭제, 부분종료, 종료, 수정 등
- 대상 목록은 인벤토리 DB에서 조회 (기존 Zabbix API → 인벤토리 변경)

---

## 2. 연동 범위 및 구조

### 2.1 연동 시스템

| 연동 시스템 | Event 대상 | 연동 방법 |
|------------|-----------|----------|
| Observability Platform | Infra(CSW/HW/VM), Platform, Service | 1차: DB Table, 2차: API Hook |
| Zenius | NW | DB Table |

### 2.2 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         Observability DB                                 │
│                    (단일 테이블, 단일 seq)                                │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼ seq 기반 증분 연동
┌─────────────────────────────────────────────────────────────────────────┐
│                   luppiter_scheduler                                     │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │ ObservabilityEventWorker (EST030) - 단일 Worker                  │    │
│  │    → X01_IF_EVENT_OBS (임시 테이블)                              │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼ 프로시저
┌─────────────────────────────────────────────────────────────────────────┐
│                         프로시저 분기 처리                                │
│  ┌──────────────────┬──────────────────┬──────────────────┐            │
│  │      Infra       │     Service      │    Platform      │            │
│  │  (CSW,HW,NW,VM)  │                  │                  │            │
│  ├──────────────────┼──────────────────┴──────────────────┤            │
│  │  key: target_ip  │  key: target_name + region          │            │
│  │  매칭: inventory │  매칭: cmon_service_inventory_master │            │
│  │       _master    │                                     │            │
│  └──────────────────┴─────────────────────────────────────┘            │
│                          │                    │                         │
│                    매칭 성공              매칭 실패                      │
│                          ▼                    ▼                         │
│               cmon_event_info         Slack 알림만                      │
│                  (통합 저장)      (#luppiter-unregistered-events)       │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Observability View Table 스키마

### 3.1 컬럼 정의

| 컬럼명 | 타입 | Not Null | 설명 | 샘플 (Infra) | 샘플 (Service) |
|--------|------|----------|------|-------------|----------------|
| seq | int8 | Y | 이벤트 시퀀스 (연동 기준) | 1 | 1 |
| event_id | varchar(30) | Y | 이벤트 ID (Fingerprint) | a3b1c5d9e2f4 | a3b1c5d9e2f4 |
| type | varchar(30) | N | 이벤트 타입 | infra | service |
| status | enum | Y | 이벤트 상태 (firing/resolved) | firing | firing |
| region | varchar(30) | N | 리전 구분 | DX-G-GB | DX-G-SE |
| zone | varchar(30) | N | 존 구분 | DX-G-GB-A | DX-G-SE-A |
| occu_time | timestamp | N | 발생 시간 | 2026-01-09T04:12:33Z | 2026-01-09T04:12:33Z |
| target_ip | varchar(20) | N | 이벤트 발생 IP (**Infra 필수**) | 10.2.14.255 | - |
| target_name | varchar(100) | N | 서비스/플랫폼명 (**Service/Platform 필수**) | - | next-iam-service-abcd1234 |
| target_contents | varchar(1000) | Y | 이벤트 내용 | [HW6003] CPU 사용량 | [HW6003] CPU 사용량 |
| event_level | enum | N | 이벤트 등급 (critical/fatal) | critical | fatal |
| trigger_id | int8 | Y | 트리거 ID (Rule UID) | 7264891938475629912 | 7264891938475629912 |
| r_time | timestamp | N | 해소 시간 | 2026-01-09T04:22:10Z | 2026-01-09T04:22:10Z |
| stdnm | varchar(50) | N | 표준서비스명 | NEXT-Infra-Storage-DX-G-GB | NEXT-vpc-DX-G-SE |
| source | enum | N | Alert 발생 주체 | mimir | loki |
| dashboard_url | varchar(2048) | N | Dashboard URL | https://... | https://... |
| dimensions | JSONB | N | 추가 정보 식별자 | {...} | {...} |

### 3.2 dimensions 샘플

```json
{
  "region": "seoul-1",
  "cluster": "next-prod-01",
  "namespace": "obs",
  "resource_type": "deployment",
  "resource_name": "grafana"
}
```

---

## 4. 이벤트 매핑 상세

### 4.1 Infra 매핑

| Observability 컬럼 | inventory_master 컬럼 | cmon_event_info 컬럼 | 화면 표시명 |
|-------------------|----------------------|---------------------|------------|
| source | - | source | 연동시스템 |
| target_ip | zabbix_ip | target_ip | 이벤트 수집 IP |
| - | host_nm | hostname | 호스트명 |
| - | mgmt_ip | mgmt_ip | MGMT IP |
| - | ipmi_ip | ipmi_ip | IPMI IP |
| - | equnr | equ_barcode | 설비바코드 |
| - | (조합) | - | 장비위치 |
| - | l1_layer_cd | l1_nm | 분류(L1) |
| - | l2_layer_cd | l2_nm | 도메인(L2) |
| - | l3_layer_cd | l3_nm | 표준서비스(L3) |
| - | zone | zone | Zone(L4) |
| - | e_std_nm | estdnm | 단위서비스명 |
| - | control_area | gubun | 관제영역 |
| - | host_group_nm | host_group_nm | 호스트그룹명 |
| target_contents | - | target_contents | 이벤트 제목 |
| event_level | - | event_level | 이벤트 등급 |
| occu_time | - | occu_time | 발생시간 |
| r_time | - | r_time | 해소시간 |
| status | - | event_state | 이벤트 상태 |

### 4.2 Service/Platform 매핑

| Observability 컬럼 | service_inventory 컬럼 | cmon_event_info 컬럼 | 화면 표시명 |
|-------------------|----------------------|---------------------|------------|
| source | - | source | 연동시스템 |
| target_name | service_nm | hostname | 서비스명 (+dimensions 하이퍼링크) |
| - | l1_layer_cd | l1_nm | 분류(L1) |
| - | l2_layer_cd | l2_nm | 도메인(L2) |
| stdnm | l3_layer_cd | l3_nm | 표준서비스(L3) |
| region | zone | zone | Zone(L4) |
| - | - | gubun | 관제영역 (Service/Platform) |
| - | host_group_nm | host_group_nm | 호스트그룹명 |
| target_contents | - | target_contents | 이벤트 제목 (+dashboard_url 하이퍼링크) |
| event_level | - | event_level | 이벤트 등급 |
| occu_time | - | occu_time | 발생시간 |
| r_time | - | r_time | 해소시간 |
| status | - | event_state | 이벤트 상태 |
| dashboard_url | - | dashboard_url | Dashboard URL |
| dimensions | - | dimensions | 추가 정보 |

---

## 5. 호스트그룹 샘플

### 5.1 자동생성 규칙

**형식**: `{L1}-{L3}-{L4}-{관제영역}`

### 5.2 Infra 샘플

| L1 (분류) | L2 (도메인) | L3 (표준서비스) | L4 (Zone) | 관제영역 | 호스트그룹명 |
|----------|------------|----------------|-----------|---------|-------------|
| NEXT_공통 | ktc_NEXT_공공_인프라 | NEXT-인프라-서버-DX-G-GB | DX-G-GB | HW | NEXT_공통-NEXT-인프라-서버-DX-G-GB-DX-G-GB-HW |
| NEXT_공통 | ktc_NEXT_공공_인프라 | NEXT-인프라-서버-DX-G-GB | DX-G-GB | CSW | NEXT_공통-NEXT-인프라-서버-DX-G-GB-DX-G-GB-CSW |
| NEXT_공통 | ktc_NEXT_공공_인프라 | NEXT-인프라-네트워크-DX-G-GB | DX-G-GB | NW | NEXT_공통-NEXT-인프라-네트워크-DX-G-GB-DX-G-GB-NW |
| NEXT_공통 | ktc_NEXT_공공_인프라 | NEXT-인프라-서버-DX-G-SE | DX-G-SE | VM | NEXT_공통-NEXT-인프라-서버-DX-G-SE-DX-G-SE-VM |

### 5.3 Service 샘플

| L1 (분류) | L2 (도메인) | L3 (표준서비스) | L4 (Zone) | 관제영역 | 서비스명 | 호스트그룹명 |
|----------|------------|----------------|-----------|---------|---------|-------------|
| NEXT_공통 | ktc_NEXT_공공_서비스 | NEXT-IAM-DX-G-SE | DX-G-SE | Service | NEXT-IAM | NEXT_공통-NEXT-IAM-DX-G-SE-DX-G-SE-Service |
| NEXT_공통 | ktc_NEXT_공공_서비스 | NEXT-VPC-DX-G-GB | DX-G-GB | Service | NEXT-VPC | NEXT_공통-NEXT-VPC-DX-G-GB-DX-G-GB-Service |
| NEXT_공통 | ktc_NEXT_공공_서비스 | NEXT-Billing-DX-G-SE | DX-G-SE | Service | NEXT-Billing | NEXT_공통-NEXT-Billing-DX-G-SE-DX-G-SE-Service |

### 5.4 Platform 샘플

| L1 (분류) | L2 (도메인) | L3 (표준서비스) | L4 (Zone) | 관제영역 | 서비스명 | 호스트그룹명 |
|----------|------------|----------------|-----------|---------|---------|-------------|
| NEXT_공통 | ktc_NEXT_공공_플랫폼 | NEXT-Observability-DX-G-GB | DX-G-GB | Platform | NEXT-Observability | NEXT_공통-NEXT-Observability-DX-G-GB-DX-G-GB-Platform |
| NEXT_공통 | ktc_NEXT_공공_플랫폼 | NEXT-K8S-DX-G-SE | DX-G-SE | Platform | NEXT-K8S | NEXT_공통-NEXT-K8S-DX-G-SE-DX-G-SE-Platform |
| NEXT_공통 | ktc_NEXT_공공_플랫폼 | NEXT-CICD-DX-G-GB | DX-G-GB | Platform | NEXT-CICD | NEXT_공통-NEXT-CICD-DX-G-GB-DX-G-GB-Platform |

---

## 6. 설계 결정 사항

### 6.1 Worker 구조
- **결정**: 단일 ObservabilityEventWorker (EST030)
- 프로시저에서 Infra/Service/Platform 타입별 분기 처리
- 이유: 단일 테이블, 단일 seq, 동일한 스케줄링 주기

```
EventWorkerFactory
├── EST010 → ZabbixEventWorker (v5)
├── EST011 → ZabbixEventWorker (v7)
├── EST020 → ZeniusEventWorker
└── EST030 → ObservabilityEventWorker (신규)
```

### 6.2 키 매핑 전략

| 타입 | 키 | 매칭 테이블 | 매칭 컬럼 |
|------|-----|------------|----------|
| Infra (CSW,HW,NW,VM) | target_ip | inventory_master | zabbix_ip |
| Service | target_name + region | cmon_service_inventory_master | service_nm + region |
| Platform | target_name + region | cmon_service_inventory_master | service_nm + region |

### 6.3 Service/Platform 등록 테이블
- **결정**: 신규 테이블 생성 (cmon_service_inventory_master)
- 기존 inventory_master와 동일한 패턴
- 등록된 대상만 호스트그룹 자동생성 및 이벤트 처리

### 6.4 계위 구조
- **결정**: Infra와 동일한 L1~L4 코드 구조 사용
- 기존 cmon_layer_code_info 활용
- L2 도메인: `_인프라`, `_서비스`, `_플랫폼` 구분
- L3 표준서비스: 사전 등록된 코드 사용

### 6.5 예외/메인터넌스 테이블 확장
- **결정**: 별도 테이블 분리

```
기존 유지:
├── CMON_EXCEPTION_EVENT              (마스터 - 공통)
├── CMON_EXCEPTION_EVENT_DETAIL       (Infra용)
└── CMON_EXCEPTION_EVENT_HISTORY      (이력 - 공통)

신규 추가:
├── CMON_EXCEPTION_SERVICE_DETAIL     (Service/Platform용)
└── CMON_MAINTENANCE_SERVICE_DETAIL   (Service/Platform용)
```

### 6.8 타입 선택 UI
- **결정**: 버튼 클릭 → 선택 팝업 방식

**선택 팝업 옵션**:
| 타입 | 연동 시스템 | 비고 |
|------|------------|------|
| Infra | Zabbix, Zenius, Observability | 다수 시스템 연동 |
| Service | Observability | 단일 시스템 |
| Platform | Observability | 단일 시스템 |

**타입별 표시 컬럼**:

| 컬럼 | Infra | Service/Platform | 비고 |
|------|:-----:|:----------------:|------|
| 연동시스템 (source) | O | O | |
| 호스트명/서비스명 | O | O | |
| 이벤트 제목 | O | O | |
| 이벤트 등급 | O | O | |
| 발생시간 | O | O | |
| 해소시간 | O | O | |
| 분류(L1) | O | O | |
| 도메인(L2) | O | O | |
| 표준서비스(L3) | O | O | |
| Zone(L4) | O | O | |
| 관제영역 | O | O | |
| 호스트그룹명 | O | O | |
| 이벤트 수집 IP | O | - | Infra 전용 |
| MGMT IP | O | - | Infra 전용 |
| IPMI IP | O | - | Infra 전용 |
| 설비바코드 | O | - | Infra 전용 |
| 장비위치 | O | - | Infra 전용 |
| Dashboard URL | - | O | Service/Platform 전용 |
| Dimensions | - | O | Service/Platform 전용 |

### 6.6 이벤트 통합 저장
- **결정**: cmon_event_info에 통합 + 컬럼 추가
- 추가 컬럼: source, type, dashboard_url, dimensions

### 6.7 미등록 서비스 알림
- **채널**: Slack (#luppiter-unregistered-events)
- **조건**: Service/Platform 이벤트 중 매칭 실패
- **저장**: cmon_event_info에 저장 안함
- **내용**: 이벤트 상세 전체

---

## 7. UI 변경 요약

| 화면 | 변경 내용 |
|------|----------|
| 서비스/플랫폼 등록 | 신규 화면 (L1~L4 선택 → 호스트그룹 자동생성) |
| 예외 등록 | **타입 선택 버튼** → 팝업에서 Infra/Service/Platform 선택 |
| 메인터넌스 등록 | **타입 선택 버튼** → 팝업에서 Infra/Service/Platform 선택 |
| 관제 삭제 | 탭 분리: Zabbix / Observability |
| 이벤트 목록 | source 컬럼 추가, 하이퍼링크 (dashboard_url, dimensions) |

### 7.1 타입 선택 팝업 상세

**버튼 레이블**: "타입 선택" 또는 적절한 명칭

**팝업 옵션 표기**:
```
┌─────────────────────────────────────┐
│         타입을 선택하세요            │
├─────────────────────────────────────┤
│ ○ Infra (Zabbix, Zenius, Observability) │
│ ○ Service (Observability)           │
│ ○ Platform (Observability)          │
├─────────────────────────────────────┤
│        [취소]      [선택]           │
└─────────────────────────────────────┘
```

**선택 후 동작**:
- 선택한 타입에 해당하는 컬럼만 테이블에 표시
- Infra: 전체 컬럼 (IP, 장비위치, 설비바코드 등 포함)
- Service/Platform: Infra 컬럼 중 해당 없는 항목 제외 (MGMT IP, IPMI IP, 설비바코드, 장비위치 등)

---

## 8. 테이블 목록

### 8.1 신규 생성

| 테이블 | 용도 |
|--------|------|
| cmon_service_inventory_master | Service/Platform 등록 관리 |
| cmon_exception_service_detail | 예외 상세 (Service/Platform용) |
| cmon_maintenance_service_detail | 메인터넌스 상세 (Service/Platform용) |
| x01_if_event_obs | Observability 임시 연동 테이블 |

### 8.2 컬럼 추가

| 테이블 | 추가 컬럼 |
|--------|----------|
| cmon_event_info | source, type, dashboard_url, dimensions |

---

## 9. Action Plan

### 9.1 개발 항목

| 분류 | Action Item | LUPR | 상태 |
|------|-------------|------|------|
| 개발 | 서비스/플랫폼 등록 화면 (DDL, DML) | LUPR-687 | ✅ 개발완료 |
| 개발 | 이벤트 관리 | LUPR-690 | 개발 |
| 개발 | 이벤트 예외 관리 | LUPR-683 | 개발 |
| 개발 | 메인터넌스 관리 | LUPR-684 | 개발 |
| 개발 | 관제 삭제 | LUPR-692 | 개발 |
| 개발 | Observability Event Scheduler | LUPR-686 | 개발 |
| 개발 | 전체 메뉴 서비스 인벤토리 적용 - WEB | LUPR-699 | 해야 할 일 |
| 개발 | 전체 메뉴 서비스 인벤토리 적용 - Scheduler | LUPR-700 | 해야 할 일 |
| 점검 | 기존 시스템 cross-cutting 사전 점검 | TECHIOPS26-271 | 해야 할 일 |

### 9.2 일정

| 단계 | 일정 | 상태 |
|------|------|------|
| 유피테르 개발 (Observability) | ~2월 2주차 (2/13) | 진행 중 |
| 유피테르 검증 (Observability) | ~2월 4주차 (2/27) | 진행예정 |
| Zenius 샘플링 연동 | 2월 4주차 | 진행예정 |

---

## 10. 고려사항

- Observability Event 연동에 대한 수용 범위에 따라 개발 범위가 변경될 수 있음
- 현재 계위(L1~L4)를 유지할 경우: 변경 사항 없음
- 계위 변경 시: DB/Backend/Frontend 광범위 변경
- **기존 시스템 영향도**: 서비스 인벤토리 추가에 따른 cross-cutting 항목 별도 관리 (TECHIOPS26-271). 상세는 `04-functional-spec.md` 9장 및 협력사 공유 가이드 참고

---

## 11. 참고 문서

- 요구사항: https://ktcloud.atlassian.net/wiki/spaces/SREP/pages/1560215751/Next
- DB 스키마: https://ktcloud.atlassian.net/wiki/x/hAZZX
- DDL: `docs/o11y/02-ddl.sql`
