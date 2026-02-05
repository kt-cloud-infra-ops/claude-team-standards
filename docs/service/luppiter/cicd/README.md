# Luppiter CI/CD 파이프라인

## 파일 목록

| 파일 | 용도 | 실행 주기 |
|------|------|----------|
| `stg-db-sync.groovy` | 스테이징 DB 동기화 | 필요시 (월 1회 권장) |
| `stg-data/stg-data.sql` | STG 전용 데이터 | DB 동기화 시 |

---

## 스테이징 DB 동기화

### 흐름

```
운영 백업 Git에서 가져오기
    ↓
스테이징 DB에 복원
    ↓
STG 전용 데이터 INSERT (stg-data.sql)
```

### 소요 시간

30분 ~ 2시간 (운영 백업 파일 약 2GB)

### STG 데이터 관리

`stg-data/stg-data.sql` 파일에서 관리:

| 데이터 | 건수 |
|--------|------|
| STG 계위 | 7건 |
| STG 인벤토리 | 16건 |
| ES9* 배치 설정 | 3건 |
| ES9* Zabbix 정보 | 2건 |
| STG 권한그룹 | 동적 매핑 |

### 동기화 전략

| 테이블 | 전략 |
|--------|------|
| `cmon_layer_code_info` | 운영 복원 → STG 계위 INSERT |
| `inventory_master` | 운영 복원 → STG 인벤토리 INSERT |
| `c01_batch_event` | 운영 복원 → ES9* INSERT |
| `c01_zabbix_info` | 운영 복원 → ES9* INSERT |
| `cmon_group*` | 운영 복원 → STG 그룹 생성 + 전체 사용자 매핑 |

---

## 환경 정보

### DB 서버

| 환경 | IP | DB |
|------|-----|-----|
| 운영 | 10.2.14.105 | ktcmon |
| 스테이징 | 10.4.224.97 | ktcmon |

### 백업 저장소

- Git: `git@10.217.192.26:all/backup.git`
- 폴더: `luppiter_m1-jpt-prd-mon-d01_10.2.14.105/`

---

## 주의사항

1. **STG_DB_PWD 환경변수 필요** - Jenkins Credentials에 등록
2. **STG 데이터 변경 시** - `stg-data.sql` 수정 후 Git 커밋

---

**최종 업데이트**: 2026-02-03
