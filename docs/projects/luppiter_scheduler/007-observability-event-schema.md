# 학습: Observability 이벤트 스키마 및 매핑

## 날짜
2026-01-19

## 프로젝트
luppiter_scheduler, luppiter-web (Observability 연동)

---

## Observability 연동 View Table 스키마

| 컬럼명 | 타입 | Not Null | 설명 | 비고 |
|--------|------|----------|------|------|
| seq | int8 | Y | 이벤트 시퀀스 (연동 기준) | |
| event_id | varchar(30) | Y | 이벤트 ID (Fingerprint) | |
| type | varchar(30) | N | 이벤트 타입 | infra, platform, service |
| status | enum | Y | 이벤트 상태 | firing, resolved |
| region | varchar(30) | N | 리전 구분 | DX-G-GB, DX-G-SE |
| zone | varchar(30) | N | 존 구분 | DX-G-GB-A 등 |
| occu_time | timestamp | N | 발생 시간 | |
| target_ip | varchar(20) | N | 이벤트 발생 IP | **Infra 필수** |
| target_name | varchar(30) | N | 서비스/플랫폼명 | **Service/Platform 필수** |
| target_contents | varchar(1000) | Y | 이벤트 내용 | |
| event_level | enum | N | 이벤트 등급 | critical, fatal |
| trigger_id | int8 | Y | 트리거 ID (Rule UID) | |
| r_time | timestamp | N | 해소 시간 | |
| stdnm | varchar(50) | N | 표준서비스명 | |
| source | enum | N | Alert 발생 주체 | grafana, mimir, loki |
| dashboard_url | varchar(2048) | N | Dashboard URL | |
| dimensions | JSONB | N | 추가 정보 식별자 | |

---

## 키 매핑 전략

### Infra (CSW, HW, NW, VM)
```
Key: target_ip
Mapping: inventory_master.zabbix_ip
```

### Service / Platform
```
Key: target_name + region (복합키)
Mapping: cmon_service_inventory_master.service_nm + region
```

---

## 이벤트 타입별 매핑 컬럼

### Infra 매핑

| Observability | inventory_master | cmon_event_info | 화면 표시 |
|---------------|------------------|-----------------|----------|
| source | - | source | 연동시스템 |
| target_ip | zabbix_ip | target_ip | 이벤트 수집 IP |
| - | host_nm | hostname | 호스트명 |
| - | mgmt_ip | mgmt_ip | MGMT IP |
| - | l1_layer_cd | l1_nm | 분류(L1) |
| - | l2_layer_cd | l2_nm | 도메인(L2) |
| - | l3_layer_cd | l3_nm | 표준서비스(L3) |
| - | zone | zone | Zone(L4) |
| - | control_area | gubun | 관제영역 |
| target_contents | - | target_contents | 이벤트 제목 |
| event_level | - | event_level | 이벤트 등급 |
| occu_time | - | occu_time | 발생시간 |
| r_time | - | r_time | 해소시간 |
| status | - | event_state | 이벤트 상태 |

### Service/Platform 매핑

| Observability | service_inventory | cmon_event_info | 화면 표시 |
|---------------|-------------------|-----------------|----------|
| source | - | source | 연동시스템 |
| target_name | service_nm | hostname | 서비스명 |
| - | l1_layer_cd | l1_nm | 분류(L1) |
| - | l2_layer_cd | l2_nm | 도메인(L2) |
| stdnm | l3_layer_cd | l3_nm | 표준서비스(L3) |
| region | zone | zone | Zone(L4) |
| - | - | gubun | 관제영역 (Service/Platform) |
| target_contents | - | target_contents | 이벤트 제목 |
| event_level | - | event_level | 이벤트 등급 |
| dashboard_url | - | dashboard_url | Dashboard 링크 |
| dimensions | - | dimensions | 추가 정보 |

---

## 호스트그룹 자동생성 규칙

**형식**: `{L1}-{L3}-{L4}-{관제영역}`

### 예시

| 타입 | L1 | L3 | L4 | 관제영역 | 호스트그룹명 |
|------|-----|-----|-----|---------|-------------|
| Infra | NEXT_공통 | NEXT-인프라-서버-DX-G-GB | DX-G-GB | HW | NEXT_공통-NEXT-인프라-서버-DX-G-GB-DX-G-GB-HW |
| Service | NEXT_공통 | NEXT-IAM-DX-G-SE | DX-G-SE | Service | NEXT_공통-NEXT-IAM-DX-G-SE-DX-G-SE-Service |
| Platform | NEXT_공통 | NEXT-Observability-DX-G-GB | DX-G-GB | Platform | NEXT_공통-NEXT-Observability-DX-G-GB-DX-G-GB-Platform |

---

## dimensions 샘플 구조

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

## 관련 ADR
- `docs/decisions/003-observability-integration-design.md`
