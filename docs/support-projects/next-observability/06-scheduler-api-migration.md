---
tags:
  - type/spec
  - domain/observability
  - domain/java
  - service/luppiter
  - audience/team
---

> 상위: [next-observability](README.md) · [docs](../../README.md)

# Luppiter Scheduler: O11y 연동 DB→API 변경 설계

## Context

O11y(Observability) 이벤트 수집을 1차(DB Table 직접 폴링)에서 2차(O11y API 호출)로 전환한다.
**변경 범위는 O11y 연동부분만** — Zabbix(EST010/011), Zenius(EST020)는 기존 그대로 유지.

핵심 변경:
- AS-IS: Scheduler → O11y DB (JDBC, seq 기반 증분)
- TO-BE: Scheduler → **O11y Platform API (HTTP)** → 동일 후속 흐름

후속 흐름(변경 없음): X01_IF_EVENT_OBS → p_combine_event_obs → cmon_event_info

참고: O11y는 2개 리전(SE서울, GB경북) 별도 엔드포인트로 각각 다른 system_code로 구분 (Zabbix v5/v7 패턴과 동일). API 전환 시에도 리전별 엔드포인트 유지.

---

## 변경 대상 요약

| # | 항목 | 변경유형 | 파일/위치 |
|---|------|---------|----------|
| 1 | ObservabilityEventWorker | **신규** (API 호출) | `task/builder/ObservabilityEventWorker.java` |
| 2 | EventWorkerFactory | 수정 (EST030 + combine 위임) | `task/builder/EventWorkerFactory.java` |
| 3 | EventJobWorker | 수정 (DBInfo에 `isHttp()` 헬퍼 추가) | `task/builder/EventJobWorker.java` |
| 4 | CombineEventServiceJob | 수정 (Factory 위임으로 if 제거) | `task/common/CombineEventServiceJob.java` |
| 5 | EventBatchMapper.xml | 수정 (INSERT + combine 호출 추가) | `resources/sqlmap/EventBatchMapper.xml` |
| 6 | EventBatchMapper.java | 수정 (메서드 추가) | `batch/mapper/EventBatchMapper.java` |
| 7 | p_combine_event_obs | **신규** (PL/pgSQL) | DB 프로시저 |
| 8 | X01_IF_EVENT_OBS | **DDL 실행 필요** (테이블 미생성 상태) | DB |
| 9 | C01_DBCONN_INFO + C01_BATCH_EVENT | DML INSERT (기존 구조 재활용) | DB |

---

## 1. C01_DBCONN_INFO 기존 구조 재활용

### 현행 구조

연결 정보는 `C01_BATCH_EVENT`가 아닌 **`C01_DBCONN_INFO`** 테이블에 별도 관리.
`BatchSchedulerMapper.xml`에서 `LEFT JOIN c01_dbconn_info dbi ON job.system_code = dbi.system_code`로 조인.

```
C01_BATCH_EVENT (system_code PK)
  └─ LEFT JOIN C01_DBCONN_INFO (system_code PK)
       ├── db_driver    varchar NOT NULL
       ├── db_url       varchar NOT NULL
       ├── db_user_nm   varchar NOT NULL
       └── db_user_pwd  varchar NOT NULL
```

### 방침: DDL 변경 없이 기존 컬럼 의미 확장

컬럼 리네임 시 luppiter_web 47개 파일에 영향 → **기존 컬럼을 그대로 사용**, 값만 다르게 세팅.

| 컬럼 | JDBC 용도 (기존) | HTTP 용도 (EST030) |
|------|-----------------|-------------------|
| `db_driver` | `org.postgresql.Driver` | `http` |
| `db_url` | JDBC URL | API base URL |
| `db_user_nm` | DB user | `''` (빈문자열, NOT NULL 제약) |
| `db_user_pwd` | DB password (암호화) | API Key (동일 암호화) |

```sql
-- DML: C01_DBCONN_INFO에 EST030 리전별 행 추가 (DDL 변경 없음)
INSERT INTO c01_dbconn_info (system_code, db_driver, db_url, db_user_nm, db_user_pwd, use_yn)
VALUES
  ('ES0010', 'http', '{O11y SE API URL}', '', 'ENC({API Key})', 'Y'),
  ('ES0011', 'http', '{O11y GB API URL}', '', 'ENC({API Key})', 'Y');

-- DML: C01_BATCH_EVENT에 EST030 리전별 행 추가
INSERT INTO c01_batch_event (system_code, batch_title, batch_desc, cron_exp, use_yn, event_sync_type, created_dt, created_id)
VALUES
  ('ES0010', '[O11y-SE] Observability 이벤트 수집', 'NEXT O11y 서울', '0 * * * * ?', 'N', 'EST030', now(), 'luppiter'),
  ('ES0011', '[O11y-GB] Observability 이벤트 수집', 'NEXT O11y 경북', '0 * * * * ?', 'N', 'EST030', now(), 'luppiter');
```

> system_code 채번은 기존 ES0006(Zenius) 이후 순번 기준. 실제 값은 DBA/팀 협의.

### EventJobWorker 변경 (최소)

`DBInfo` 클래스 유지. `isHttp()` 헬퍼만 추가:

```java
@Getter @Setter
public class DBInfo {
    private String driver;
    private String url;
    private String userName;
    private String password;

    // 추가: 연결 타입 판별 헬퍼
    public boolean isHttp() { return "http".equalsIgnoreCase(driver); }
    public boolean isJdbc() { return !isHttp(); }
}
```

`setJobInfo()` 매핑 **변경 없음** — 기존 `db_driver`, `db_url`, `db_user`, `db_pwd` 키 그대로 사용.

> **영향 범위**: ZabbixEventWorker, ZeniusEventWorker 수정 없음. `getDbInfo()` 호출 패턴 동일.

---

## 2. ObservabilityEventWorker (EST030) — API 호출 방식

### AS-IS (DB polling)
```
doProcess():
  1. C01_BATCH_EVENT에서 마지막 if_idx(=seq) 조회
  2. JDBC로 O11y DB 접속
  3. SELECT * FROM obs_events WHERE seq > #{if_idx}
  4. ResultSet → CSV/batch → X01_IF_EVENT_OBS INSERT
  5. C01_BATCH_EVENT.if_idx 업데이트
```

### TO-BE (API polling + has_more 페이지네이션)
```
doProcess():
  1. C01_BATCH_EVENT에서 마지막 if_idx(=seq) 조회
  2. do-while 루프:
     2a. RestTemplate으로 O11y API 호출
         GET {db_url}/events?since_seq={seq}&limit=1000
         Header: X-API-Key: {db_pwd → 복호화}
     2b. JSON 파싱 → List<Map> 변환
     2c. MyBatis batch INSERT → X01_IF_EVENT_OBS
     2d. last_seq 갱신
     2e. has_more == true면 계속, false면 종료
  3. C01_BATCH_EVENT.if_idx 업데이트 (최종 last_seq)
```

### 코드 구조
```java
public class ObservabilityEventWorker extends EventJobWorker {

    private static final int FETCH_LIMIT = 1000;

    @Override
    public void doProcess() throws Exception {
        // 1. 마지막 seq 조회
        Map<String, String> batchEventInfo = eventBatchMapper.selectBatchEventInfo(params);
        long currentSeq = Long.parseLong(batchEventInfo.get("if_idx"));

        // RestTemplate 설정 (timeout 적용)
        RestTemplate restTemplate = createRestTemplate();

        // 2. has_more 페이지네이션 루프
        boolean hasMore = true;
        while (hasMore) {
            // 2a. O11y API 호출 — 기존 DBInfo 필드 재활용
            String apiUrl = getDbInfo().getUrl()
                + "/events?since_seq={seq}&limit={limit}";
            HttpHeaders headers = new HttpHeaders();
            headers.set("X-API-Key", getDbInfo().getPassword());

            ResponseEntity<String> response = restTemplate.exchange(
                apiUrl, HttpMethod.GET,
                new HttpEntity<>(headers),
                String.class, currentSeq, FETCH_LIMIT);

            // 2b. JSON 파싱
            ObsEventResponse parsed = parseResponse(response.getBody());
            List<Map<String, Object>> events = parsed.getEvents();

            if (!events.isEmpty()) {
                // 2c. X01_IF_EVENT_OBS batch INSERT
                Map<String, Object> insertParam = new HashMap<>();
                insertParam.put("systemCode", getSystemCode());
                insertParam.put("dataList", events);
                eventBatchMapper.insertTempEventObs(insertParam);

                // 2d. seq 갱신 (방어: events max seq vs API last_seq 중 큰 값)
                long eventsMaxSeq = events.stream()
                        .mapToLong(e -> ((Number) e.get("seq")).longValue())
                        .max().orElse(currentSeq);
                long apiLastSeq = parsed.getLastSeq();
                currentSeq = Math.max(eventsMaxSeq, apiLastSeq);

                if (eventsMaxSeq != apiLastSeq) {
                    log.warn("[{}] seq 불일치: events max={}, API last_seq={}",
                            getSystemCode(), eventsMaxSeq, apiLastSeq);
                }
            }

            // 2e. has_more 체크
            hasMore = parsed.isHasMore() && !events.isEmpty();
        }

        // 3. 최종 seq 업데이트
        Map<String, String> updateParameter = new HashMap<>();
        updateParameter.put("systemCode", getSystemCode());
        updateParameter.put("batchBean", getJobName());
        updateParameter.put("if_idx", String.valueOf(currentSeq));
        updateParameter.put("if_dt", "now()");
        batchSchedulerMapper.updateBatchEventInfo(updateParameter);
    }

    private RestTemplate createRestTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(10_000);
        factory.setReadTimeout(30_000);
        return new RestTemplate(factory);
    }
}
```

### DBInfo 필드 매핑

| DBInfo 필드 | C01_DBCONN_INFO 컬럼 | EST030에서의 용도 |
|------------|---------------------|-----------------|
| `getDriver()` | `db_driver` | `"http"` (isHttp() 판별) |
| `getUrl()` | `db_url` | O11y API base URL |
| `getUserName()` | `db_user_nm` | 미사용 (빈문자열) |
| `getPassword()` | `db_user_pwd` | API Key (복호화됨) |

---

## 3. EventWorkerFactory — combine 위임 (Strategy via Enum)

기존 CombineEventServiceJob의 if-else 분기를 Factory enum에 위임:

```java
public enum EventWorkerFactory {

    EST010("EST010", () -> new ZabbixEventWorker("EST010")) {
        @Override
        public void combine(EventBatchMapper mapper, Map<String, Object> params) {
            mapper.combineEventForZabbix(params);
        }
    },
    EST011("EST011", () -> new ZabbixEventWorker("EST011")) {
        @Override
        public void combine(EventBatchMapper mapper, Map<String, Object> params) {
            mapper.combineEventForZabbix(params);
        }
    },
    EST020("EST020", () -> new ZeniusEventWorker("EST020")) {
        @Override
        public void combine(EventBatchMapper mapper, Map<String, Object> params) {
            mapper.combineEventForZenius(params);
        }
    },
    EST030("EST030", () -> new ObservabilityEventWorker("EST030")) {
        @Override
        public void combine(EventBatchMapper mapper, Map<String, Object> params) {
            mapper.combineEventForObs(params);
        }
    };

    private final String code;
    private final Supplier<EventJobWorker> supplier;

    // ... 기존 생성자/메서드 유지 ...

    // 추가: combine 전략 메서드
    public abstract void combine(EventBatchMapper mapper, Map<String, Object> params);
}
```

### CombineEventServiceJob 변경

```java
// 기존 (if-else 체인)
if (EST020) { eventBatchMapper.combineEventForZenius(combineParams); }
else        { eventBatchMapper.combineEventForZabbix(combineParams); }

// 변경 (Factory 위임 — 한 줄)
EventWorkerFactory.valueOf(eventSyncTypeCode).combine(eventBatchMapper, combineParams);
```

> 새로운 연동 시스템 추가 시 Factory enum에만 추가하면 됨. CombineEventServiceJob 수정 불필요.

---

## 4. p_combine_event_obs 프로시저 (단일 프로시저)

```
CALL p_combine_event_obs(p_system_code)

처리 흐름:
1. X01_IF_EVENT_OBS에서 미처리 데이터 조회

2. type별 분기:
   ├─ Infra (CSW/HW/NW/VM):
   │   key = target_ip
   │   매칭: inventory_master.zabbix_ip
   │   → 매칭 성공: cmon_event_info INSERT/UPDATE (인벤토리 부가정보 JOIN)
   │   → 매칭 실패: skip (기존 패턴과 동일 — 별도 마킹 없음)
   │
   └─ Service/Platform:
       key = target_name + region
       매칭: cmon_service_inventory_master (service_nm + region)
       → 매칭 성공: cmon_event_info INSERT/UPDATE (서비스인벤토리 부가정보 JOIN)
       → 매칭 실패: skip (미등록 알림 Job이 별도로 X01_IF_EVENT_OBS 직접 조회)

3. 처리 완료 데이터 플래그 업데이트

4. cmon_event_info 추가 컬럼:
   - source (mimir/loki 등)
   - type (infra/service/platform)
   - dashboard_url
   - dimensions (JSONB)
```

> **미등록 이벤트 처리**: combine 프로시저는 매칭 실패를 마킹하지 않고 skip. 미등록 알림 Job(UnregisteredEventAlarmServiceJob)이 X01_IF_EVENT_OBS에서 직접 인벤토리 미등록 건을 조회.

---

## 5. 미등록 이벤트 알림 (별도 Job)

기존 UnregisteredEventAlarmServiceJob 패턴 유지:
- X01_IF_EVENT_OBS에서 인벤토리 미등록 이벤트를 **직접 조회** (inventory_master/cmon_service_inventory_master LEFT JOIN → NULL)
- RestClientService → luppiter_web API → Slack (#luppiter-unregistered-events)
- **combine 프로시저와 완전 분리**: 별도 스케줄, 별도 쿼리

이 부분은 LUPR-698/702로 구현 진행 중.

---

## 6. X01_IF_EVENT_OBS 테이블

01-design.md 3.1절 스키마 기준. **현재 DB에 테이블 미생성 상태 — DDL 실행 필요.**

API 응답 JSON이 이 컬럼에 1:1 매핑되므로 스키마 변경은 없음.

---

## 7. O11y 이벤트 수집 API 스펙 (협의 완료)

- **엔드포인트**: Jira 티켓 댓글 참조
- **인증**: API Key (X-API-Key 헤더)
- **Rate Limit**: 별도 제한 없음 → 스케줄러 자체 처리시간 기반 조절
- **페이지네이션**: `has_more` 필드 기반 루프 (true면 last_seq로 재요청)

```http
GET {endpoint}/events?since_seq={seq}&limit={limit}
Header: X-API-Key: {api-key}

Response:
{
  "flag": true,
  "result": {
    "events": [
      {
        "seq": 12345,
        "event_id": "a3b1c5d9e2f4",
        "type": "infra",
        "status": "firing",
        "region": "DX-G-GB",
        "zone": "DX-G-GB-A",
        "occu_time": "2026-01-09T04:12:33Z",
        "target_ip": "10.2.14.255",
        "target_name": null,
        "target_contents": "[HW6003] CPU 사용량",
        "event_level": "critical",
        "trigger_id": 7264891938475629912,
        "r_time": null,
        "stdnm": "NEXT-Infra-Storage-DX-G-GB",
        "source": "mimir",
        "dashboard_url": "https://...",
        "dimensions": { ... }
      }
    ],
    "has_more": true,
    "last_seq": 12400
  }
}
```

### Worker 페이지네이션 처리

```
has_more=true  → last_seq로 since_seq 갱신 후 재요청
has_more=false → 루프 종료, 최종 last_seq를 C01_BATCH_EVENT에 저장
```

---

## 수정 파일 목록 (경로)

```
luppiter_scheduler/src/main/java/com/ktc/luppiter/batch/task/builder/
├── ObservabilityEventWorker.java     # 신규 (API 호출 + has_more 루프)
├── EventWorkerFactory.java           # 수정 (EST030 + combine 위임)
└── EventJobWorker.java               # 수정 (DBInfo에 isHttp()/isJdbc() 추가만)

luppiter_scheduler/src/main/java/com/ktc/luppiter/batch/task/common/
└── CombineEventServiceJob.java       # 수정 (if-else → Factory.combine() 한 줄)

luppiter_scheduler/src/main/java/com/ktc/luppiter/batch/mapper/
└── EventBatchMapper.java             # 수정 (insertTempEventObs, combineEventForObs 추가)

luppiter_scheduler/src/main/resources/
└── sqlmap/EventBatchMapper.xml       # 수정 (INSERT + CALL 추가)

DB:
├── X01_IF_EVENT_OBS                  # DDL (테이블 생성 — 01-design.md 3.1절)
├── C01_DBCONN_INFO                   # DML INSERT (EST030 리전별 행)
├── C01_BATCH_EVENT                   # DML INSERT (EST030 리전별 행)
└── p_combine_event_obs               # 신규 PL/pgSQL 프로시저
```

**기존 파일 영향 없음**:
- `ZabbixEventWorker.java` — 변경 없음
- `ZeniusEventWorker.java` — 변경 없음
- `BatchSchedulerMapper.xml` — 변경 없음 (SQL alias 유지)
- `luppiter_web` — 변경 없음 (DDL 없으므로)

---

## 기존 소스 영향도 분석

### 영향 없음 (자동 처리되는 컴포넌트)

| 파일 | 이유 |
|------|------|
| `CustomScheduledTaskManager` | DB 쿼리 루프 기반 — EST030 행 INSERT만으로 자동 인식 |
| `CustomScheduledTaskRegistrar` | `EventWorkerFactory.fromCode()` 호출 — enum 추가만으로 동작 |
| `SchedulerConfig` | ThreadPool=20 고정, 변경 불필요 |
| `TaskDBConnection` | ObservabilityEventWorker에서 사용 안 함 (API 방식) |
| `ZabbixEventWorker` | EST010/011 전용, EST030과 무관 |
| `ZeniusEventWorker` | EST020 전용, EST030과 무관 |
| `BatchSchedulerMapper.xml` | 기존 LEFT JOIN 쿼리 그대로 EST030 행도 조회됨 |
| ShedLock | system_code 기반 자동 생성 |
| `luppiter_web` 전체 | DDL 변경 없으므로 영향 없음 |

### EventWorkerFactory abstract combine() 추가 영향

현재 Factory에는 abstract 메서드 없음 (Supplier 패턴만). 설계대로 `abstract combine()` 추가 시 **기존 3개 enum 전부 @Override 필요**:

| enum | combine 구현 | 기존 동작 |
|------|-------------|----------|
| EST010 | `mapper.combineEventForZabbix(params)` | 변경 없음 (기존 else 분기와 동일) |
| EST011 | `mapper.combineEventForZabbix(params)` | 변경 없음 |
| EST020 | `mapper.combineEventForZenius(params)` | 변경 없음 (기존 if 분기와 동일) |
| EST030 | `mapper.combineEventForObs(params)` | 신규 |

→ 코드 구조 변경이지만, 각 enum의 combine 로직은 기존 CombineEventServiceJob의 if-else에서 그대로 옮기는 것. 회귀 테스트로 검증.

### X01_IF_EVENT_OBS DDL 보완 필요

`02-ddl.sql`의 현재 DDL에 `system_code` 컬럼 없음. 기존 패턴(`X01_IF_EVENT_DATA`, `X01_IF_EVENT_ZENIUS`) 모두 `system_code` 포함.
→ `system_code VARCHAR(10)` 추가 필요 (p_combine_event_obs에서 system_code 기반 필터링)

### 사전 등록 확인 (완료)

| 항목 | 상태 |
|------|------|
| `c00_common_code` EST030='NEXT' | 등록 완료 |
| `c01_batch_event` EST030 행 | **미등록 — DML 필요** |
| `c01_dbconn_info` EST030 행 | **미등록 — DML 필요** |
| `x01_if_event_obs` 테이블 | **미생성 — DDL 필요** |
| RestTemplate 의존성 | 사용 가능 (SlackMessageSender 등에서 이미 사용 중) |

---

## 검증 방법

1. **단위 테스트**: ObservabilityEventWorker — MockRestServiceServer로 O11y API 응답 모킹 (has_more 시나리오 포함)
2. **통합 테스트**: X01_IF_EVENT_OBS 적재 → p_combine_event_obs 실행 → cmon_event_info 확인
3. **E2E**: 실제 O11y API 연동 → 이벤트 수집 → 화면 조회
4. **미등록 알림**: 매칭 실패 이벤트 → Slack 수신 확인
5. **회귀 테스트**: EventWorkerFactory 구조 변경 후 EST010/011/020 combine 정상 동작 확인

---

## 관련 문서

- [06-01-implementation-guide.md](06-01-implementation-guide.md) — 상세 개발 가이드 (복붙 수준)

---

**최종 업데이트**: 2026-02-10
