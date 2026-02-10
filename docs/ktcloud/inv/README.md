# 유피테르 인프라 인벤토리

> Source of Truth: [Confluence - 유피테르 인벤토리](https://ktcloud.atlassian.net/wiki/spaces/CL23/pages/954270329)
> 로컬 역할: Claude 참조용 읽기 전용 사본
> 최종 동기화: 2026-02-09

## 파일 목록

| 파일 | 환경 | 서버 수 | Confluence |
|------|------|---------|------------|
| [dev.md](dev.md) | DEV (개발) | 29대 | [페이지](https://ktcloud.atlassian.net/wiki/spaces/CL23/pages/954303335) |
| [stg.md](stg.md) | STG (스테이징) | 38대 | [페이지](https://ktcloud.atlassian.net/wiki/spaces/CL23/pages/953484239) |
| [prd.md](prd.md) | PRD (운영) | 195대 | [페이지](https://ktcloud.atlassian.net/wiki/spaces/CL23/pages/952010073) |

## 주요 컬럼

| 컬럼 | 설명 |
|------|------|
| hostname | 서버 호스트명 |
| 기능 | WEB, WAS, AP, DB |
| MgmtIP | 관리 IP |
| ServiceIP | 서비스 IP |
| VIP/NATIP | 가상 IP / NAT IP |
| 센터 | 목동1IDC, 천안CDC, 용산IDC 등 |
| OS | 운영체제 |
| DB | 데이터베이스 |
| CPU/MEM | vCore / GB |

## 갱신 규칙

1. **Confluence 먼저 업데이트** (Source of Truth)
2. **로컬 동기화**: 엑셀 또는 Confluence에서 가져와서 갱신
3. **헤더의 동기화일 업데이트**

### 엑셀로 갱신하기

엑셀 파일 경로를 알려주면 Claude가 파싱하여 갱신합니다:
```
"인벤토리 업데이트해줘. 엑셀: ~/Downloads/inventory_prd.xlsx"
```

## 카테고리

| 카테고리 | 설명 |
|---------|------|
| HAProxy | 로드밸런서 |
| 통합Dashboard | Luppiter 웹/WAS/DB |
| ZabbixServer | Zabbix 모니터링 서버 |
| ZabbixProxy | Zabbix 프록시 (데이터 수집) |
| Prometheus | Prometheus 모니터링 |
| NMSsyslog | NMS syslog 수집 |
| NMSZabbix | NMS Zabbix 연동 |
| HERA | HERA API Gateway/Batch/DB |
| Cloudbot | Cloudbot/COA |
