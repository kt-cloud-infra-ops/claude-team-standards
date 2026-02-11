---
tags:
  - type/spec
  - service/luppiter
  - service/luppiter/o11y
  - audience/team
---

> 상위: [next-observability](README.md) · [docs](../../README.md)

# O11y 메인터넌스/예외 API 스펙 협의

> 작성일: 2026-02-03
> 참고: 01-design.md, 04-functional-spec.md

---

## 1. 개요

### 1.1 배경

Luppiter에서 O11y(LOKI 기반) 연동 시 메인터넌스/예외 기능 구현을 위한 API 스펙 협의 문서입니다.

### 1.2 연동 방식 비교

| 구분 | Zabbix | O11y (LOKI) |
|------|--------|-------------|
| **예외** | DB 자체 관리 | DB 자체 관리 (API 불필요) |
| **메인터넌스** | Zabbix API 연동 | **O11y API 연동 필요** |

> **예외**: Luppiter DB에서 자체 관리 → API 불필요  
> **메인터넌스**: 소스 시스템(O11y)에서 알림 중단 처리 필요 → API 필요

### 1.3 요청 사항

- 메인터넌스 API 4종 제공 요청 (생성/수정/종료/조회)
- 기존 Zabbix 연동 패턴과 동일한 구조로 개발 예정

---

## 2. 메인터넌스 API 스펙

### 2.1 메인터넌스 생성 (Create)

**요청**
```http
POST /api/v1/maintenance/create
Content-Type: application/json
```

```json
{
  "title": "메인터넌스 명",
  "start_date": "2026-02-15 10:00",
  "end_date": "2026-02-15 18:00",
  "targets": [
    {
      "type": "infra",
      "target_ip": "10.2.14.55",
      "region": "DX-G-GB"
    },
    {
      "type": "service",
      "target_name": "next-iam-service",
      "region": "DX-G-SE"
    },
    {
      "type": "platform",
      "target_name": "next-observability",
      "region": "DX-G-GB"
    }
  ]
}
```

**파라미터**

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `title` | String | O | 메인터넌스 명 |
| `start_date` | String | O | 시작 시간 (yyyy-MM-dd HH:mm) |
| `end_date` | String | O | 종료 시간 (yyyy-MM-dd HH:mm) |
| `targets` | Array | O | 대상 목록 |
| `targets[].type` | String | O | infra / service / platform |
| `targets[].target_ip` | String | △ | IP (Infra 필수) |
| `targets[].target_name` | String | △ | 서비스명 (Service/Platform 필수) |
| `targets[].region` | String | O | 리전 구분 |

**응답**
```json
{
  "flag": true,
  "message": "",
  "result": {
    "maintenance_id": "silence-12345",
    "created_at": "2026-02-15T10:00:00Z"
  }
}
```

---

### 2.2 메인터넌스 수정 (Update)

**요청**
```http
PUT /api/v1/maintenance/update
Content-Type: application/json
```

```json
{
  "maintenance_id": "silence-12345",
  "title": "메인터넌스 명 (수정)",
  "start_date": "2026-02-15 10:00",
  "end_date": "2026-02-15 20:00",
  "targets": [
    {
      "target_ip": "10.2.14.55",
      "region": "DX-G-GB",
      "action": "A"
    },
    {
      "target_name": "next-iam-service",
      "region": "DX-G-SE",
      "action": "R"
    }
  ]
}
```

**파라미터**

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `maintenance_id` | String | O | 메인터넌스 ID |
| `title` | String | △ | 메인터넌스 명 (변경 시) |
| `start_date` | String | △ | 시작 시간 (변경 시) |
| `end_date` | String | △ | 종료 시간 (변경 시) |
| `targets` | Array | O | 대상 목록 |
| `targets[].action` | String | O | **A**: 추가, **R**: 삭제 |

> **참고**: 기존 대상 유지(N)는 전송 불필요 - 변경분만 전송

**응답**
```json
{
  "flag": true,
  "message": "",
  "result": {
    "maintenance_id": "silence-12345",
    "updated_at": "2026-02-15T12:00:00Z"
  }
}
```

---

### 2.3 메인터넌스 종료/만료 (Expire)

**요청**
```http
POST /api/v1/maintenance/expire
Content-Type: application/json
```

```json
{
  "maintenance_id": "silence-12345"
}
```

**파라미터**

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `maintenance_id` | String | O | 메인터넌스 ID |

**응답**
```json
{
  "flag": true,
  "message": "",
  "result": {
    "maintenance_id": "silence-12345",
    "status": "expired",
    "expired_at": "2026-02-15T14:00:00Z"
  }
}
```

---

### 2.4 메인터넌스 조회 (Get)

**요청**
```http
POST /api/v1/maintenance/get
Content-Type: application/json
```

```json
{
  "maintenance_ids": ["silence-12345", "silence-12346"]
}
```

**파라미터**

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| `maintenance_ids` | Array | O | 메인터넌스 ID 목록 |

**응답**
```json
{
  "flag": true,
  "message": "",
  "result": {
    "maintenances": [
      {
        "maintenance_id": "silence-12345",
        "title": "메인터넌스 명",
        "status": "active",
        "active_since": 1739523600,
        "active_till": 1739552400,
        "targets": [
          {
            "type": "infra",
            "target_ip": "10.2.14.55",
            "region": "DX-G-GB"
          }
        ]
      }
    ]
  }
}
```

---

## 3. 공통 사항

### 3.1 응답 형식

**성공**
```json
{
  "flag": true,
  "message": "",
  "result": { ... }
}
```

**실패**
```json
{
  "flag": false,
  "message": "에러 메시지",
  "result": null
}
```

### 3.2 매칭 키

| 타입 | 매칭 키 | 예시 |
|------|---------|------|
| Infra | `target_ip` | `10.2.14.55` |
| Service | `target_name` + `region` | `next-iam-service` + `DX-G-SE` |
| Platform | `target_name` + `region` | `next-observability` + `DX-G-GB` |

### 3.3 인증

- API 인증 방식 협의 필요 (API Key, OAuth 등)
- Luppiter에서 인증 정보 저장 테이블: `cmon_obs_info` (신규 생성 예정)

---

## 4. 예외 관리 (참고)

예외는 **API 연동 불필요** - Luppiter DB에서 자체 관리합니다.

### 4.1 처리 방식

```
[이벤트 수집] → [예외 테이블 조회] → [예외 대상 필터링] → [이벤트 저장]
```

### 4.2 관련 테이블

| 테이블 | 용도 |
|--------|------|
| `cmon_exception_event` | 예외 마스터 |
| `cmon_exception_event_detail` | Infra 예외 상세 |
| `cmon_exception_service_detail` | Service/Platform 예외 상세 (신규) |

---

## 5. Grafana Silence API 참고

LOKI/Grafana 환경에서 내부적으로 Grafana Alerting Silence를 사용하는 경우 참고:

```http
# Silence 생성
POST /api/alertmanager/grafana/api/v2/silences
{
  "matchers": [
    { "name": "target_ip", "value": "10.2.14.55", "isRegex": false }
  ],
  "startsAt": "2026-02-15T10:00:00Z",
  "endsAt": "2026-02-15T18:00:00Z",
  "createdBy": "luppiter",
  "comment": "메인터넌스 명"
}

# Silence 조회
GET /api/alertmanager/grafana/api/v2/silences

# Silence 삭제
DELETE /api/alertmanager/grafana/api/v2/silence/{silenceID}
```

위 API를 래핑하여 Luppiter용 API로 제공해 주시면 됩니다.

---

## 6. 협의 필요 사항

| 항목 | 내용 | 상태 |
|------|------|------|
| API Endpoint | 실제 URL 확정 | 협의 필요 |
| 인증 방식 | API Key / OAuth / Basic Auth | 협의 필요 |
| 타임존 | UTC / KST | 협의 필요 |
| 에러 코드 | 상세 에러 코드 정의 | 협의 필요 |
| Rate Limit | API 호출 제한 | 협의 필요 |

---

## 7. 일정

| 단계 | 일정 | 비고 |
|------|------|------|
| API 스펙 협의 | 2월 1주차 | 현재 |
| O11y API 개발 | 2월 2주차 | O11y 팀 |
| Luppiter 연동 개발 | 2월 2주차 (2/13) | Luppiter 팀 |
| 통합 테스트 | 2월 3~4주차 | 양측 |
| 검증 완료 | 2월 4주차 (2/27) | - |

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
|------|------|----------|--------|
| 2026-02-03 | 1.0 | 초안 작성 | - |
