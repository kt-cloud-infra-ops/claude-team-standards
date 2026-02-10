---
tags:
  - type/guide
  - domain/observability
  - domain/java
  - service/luppiter
  - audience/team
---

> 상위: [06-scheduler-api-migration](06-scheduler-api-migration.md) · [next-observability](README.md)

# O11y Scheduler API 전환 — 상세 개발 가이드

설계: [06-scheduler-api-migration.md](06-scheduler-api-migration.md)
이 문서의 코드를 순서대로 적용하면 동작합니다.

---

## 실행 순서

| 순서 | 작업 | 유형 |
|------|------|------|
| 1 | X01_IF_EVENT_OBS DDL | DB |
| 2 | C01_BATCH_EVENT + C01_DBCONN_INFO DML | DB |
| 3 | EventJobWorker.java 수정 | Java |
| 4 | EventWorkerFactory.java 수정 | Java |
| 5 | ObservabilityEventWorker.java 신규 | Java |
| 6 | EventBatchMapper.java 수정 | Java |
| 7 | EventBatchMapper.xml 수정 | MyBatis |
| 8 | CombineEventServiceJob.java 수정 | Java |
| 9 | p_combine_event_obs 프로시저 | DB |

---

## 1. X01_IF_EVENT_OBS DDL

> `02-ddl.sql`에서 `system_code` 컬럼 추가된 버전. DB에서 직접 실행.

```sql
-- X01_IF_EVENT_OBS 테이블 생성
CREATE TABLE x01_if_event_obs (
    system_code         VARCHAR(10) NOT NULL,       -- 시스템코드 (ES0010, ES0011 등)
    seq                 BIGINT NOT NULL,             -- 시퀀스 (연동 기준)
    event_id            VARCHAR(30) NOT NULL,        -- Fingerprint
    type                VARCHAR(30),                 -- infra | service | platform
    status              VARCHAR(20),                 -- firing | resolved
    region              VARCHAR(30),
    zone                VARCHAR(30),
    target_ip           VARCHAR(20),                 -- Infra용
    target_name         VARCHAR(100),                -- Service/Platform용
    target_contents     VARCHAR(1000),
    event_level         VARCHAR(20),                 -- critical | fatal
    trigger_id          BIGINT,
    stdnm               VARCHAR(50),                 -- 표준서비스명
    occu_time           TIMESTAMP,                   -- 발생 시간
    r_time              TIMESTAMP,                   -- 해소 시간
    source              VARCHAR(20),                 -- grafana | mimir | loki
    dashboard_url       VARCHAR(2048),
    dimensions          JSONB,
    if_dt               TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_if_event_obs_sys ON x01_if_event_obs(system_code);
CREATE INDEX idx_if_event_obs_seq ON x01_if_event_obs(seq);
CREATE INDEX idx_if_event_obs_type ON x01_if_event_obs(type);
CREATE INDEX idx_if_event_obs_target_ip ON x01_if_event_obs(target_ip);
CREATE INDEX idx_if_event_obs_target_nm ON x01_if_event_obs(target_name, region);

COMMENT ON TABLE x01_if_event_obs IS 'Observability 이벤트 임시 연동 테이블';
```

---

## 2. C01_BATCH_EVENT + C01_DBCONN_INFO DML

> system_code는 기존 ES0006(Zenius) 이후 순번. URL/API Key는 실제 값으로 교체.

```sql
-- C01_DBCONN_INFO: EST030 리전별 연결 정보
-- db_driver='http' → ObservabilityEventWorker에서 API 호출 판별용
-- db_user_nm='' → NOT NULL 제약 충족 (API에서 미사용)
-- db_user_pwd → 기존 암호화 방식(ENC)으로 API Key 암호화

INSERT INTO c01_dbconn_info
    (system_code, db_driver, db_url, db_user_nm, db_user_pwd, use_yn)
VALUES
    ('ES0010', 'http', '{O11y SE API URL}', '', 'ENC({암호화된 API Key})', 'Y'),
    ('ES0011', 'http', '{O11y GB API URL}', '', 'ENC({암호화된 API Key})', 'Y');

-- C01_BATCH_EVENT: EST030 리전별 배치 작업
-- use_yn='N' → 검증 완료 후 'Y'로 활성화

INSERT INTO c01_batch_event
    (system_code, batch_title, batch_desc, cron_exp, use_yn, event_sync_type, created_dt, created_id)
VALUES
    ('ES0010', '[O11y-SE] Observability 이벤트 수집', 'NEXT O11y 서울', '0 * * * * ?', 'N', 'EST030', now(), 'luppiter'),
    ('ES0011', '[O11y-GB] Observability 이벤트 수집', 'NEXT O11y 경북', '0 * * * * ?', 'N', 'EST030', now(), 'luppiter');
```

---

## 3. EventJobWorker.java 수정

> 파일: `src/main/java/com/ktc/luppiter/batch/task/builder/EventJobWorker.java`
> 변경: DBInfo 내부 클래스에 `isHttp()`, `isJdbc()` 메서드 추가 (2줄)

**변경 전** (110-121행):
```java
    @Getter @Setter
    public class DBInfo{
        private String userName;
        private String password;
        private String url;
        private String driver;

        public boolean isValid() {
            return !StringUtils.isEmpty(userName) && !StringUtils.isEmpty(password) &&  !StringUtils.isEmpty(url) &&  !StringUtils.isEmpty(driver);
        }

    }
```

**변경 후**:
```java
    @Getter @Setter
    public class DBInfo{
        private String userName;
        private String password;
        private String url;
        private String driver;

        public boolean isValid() {
            return !StringUtils.isEmpty(userName) && !StringUtils.isEmpty(password) &&  !StringUtils.isEmpty(url) &&  !StringUtils.isEmpty(driver);
        }

        /** 연결 타입 판별: db_driver='http'이면 API 방식 */
        public boolean isHttp() { return "http".equalsIgnoreCase(driver); }
        public boolean isJdbc() { return !isHttp(); }
    }
```

---

## 4. EventWorkerFactory.java 수정

> 파일: `src/main/java/com/ktc/luppiter/batch/task/builder/EventWorkerFactory.java`
> 변경: EST030 추가 + abstract combine() 메서드 추가 (기존 enum에 @Override 추가)

**전체 교체** (파일 전체):
```java
package com.ktc.luppiter.batch.task.builder;

import com.ktc.luppiter.batch.mapper.EventBatchMapper;

import java.util.Map;
import java.util.function.Supplier;

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

    EventWorkerFactory(String code, Supplier<EventJobWorker> supplier) {
        this.code = code;
        this.supplier = supplier;
    }

    public EventJobWorker createHandler() {
        return supplier.get();
    }

    public static EventJobWorker fromCode(String code) {
        try {
            return EventWorkerFactory.valueOf(code).createHandler();
        } catch (IllegalArgumentException e) {
            throw new UnsupportedOperationException("지원하지 않는 코드입니다: " + code);
        }
    }

    public String getCode() {
        return this.name();
    }

    /** 이벤트 타입별 combine 프로시저 호출 전략 */
    public abstract void combine(EventBatchMapper mapper, Map<String, Object> params);
}
```

---

## 5. ObservabilityEventWorker.java 신규

> 파일: `src/main/java/com/ktc/luppiter/batch/task/builder/ObservabilityEventWorker.java`
> 신규 생성

```java
package com.ktc.luppiter.batch.task.builder;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.*;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@Slf4j
public class ObservabilityEventWorker extends EventJobWorker {

    private static final int FETCH_LIMIT = 1000;
    private static final ObjectMapper objectMapper = new ObjectMapper();

    public ObservabilityEventWorker() {}

    public ObservabilityEventWorker(String eventSyncType) {
        super.setSyncTypeCode(eventSyncType);
    }

    @Override
    void doProcess() throws Exception {
        log.info("[{}] O11y API 이벤트 수집 시작", getSystemCode());

        // 1. 마지막 seq 조회
        Map<String, String> params = new HashMap<>();
        params.put("systemCode", getSystemCode());
        params.put("batchBean", getJobName());

        Map<String, String> batchEventInfo = eventBatchMapper.selectBatchEventInfo(params);
        if (batchEventInfo == null) {
            throw new Exception("배치 이벤트 정보 없음: " + getSystemCode());
        }

        long currentSeq = Long.parseLong(batchEventInfo.get("if_idx"));
        log.debug("[{}] 마지막 seq: {}", getSystemCode(), currentSeq);

        // RestTemplate 설정
        RestTemplate restTemplate = createRestTemplate();

        // 2. has_more 페이지네이션 루프
        boolean hasMore = true;
        int totalCount = 0;

        while (hasMore) {
            // 2a. O11y API 호출
            String apiUrl = getDbInfo().getUrl()
                    + "/events?since_seq={seq}&limit={limit}";

            HttpHeaders headers = new HttpHeaders();
            headers.set("X-API-Key", getDbInfo().getPassword());
            headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));

            ResponseEntity<String> response;
            try {
                response = restTemplate.exchange(
                        apiUrl, HttpMethod.GET,
                        new HttpEntity<>(headers),
                        String.class, currentSeq, FETCH_LIMIT);
            } catch (Exception e) {
                log.error("[{}] O11y API 호출 실패: {}", getSystemCode(), e.getMessage());
                throw e;
            }

            // 2b. JSON 파싱
            Map<String, Object> body = objectMapper.readValue(
                    response.getBody(), new TypeReference<Map<String, Object>>() {});

            Boolean flag = (Boolean) body.get("flag");
            if (flag == null || !flag) {
                String message = (String) body.getOrDefault("message", "Unknown error");
                log.error("[{}] O11y API 오류 응답: {}", getSystemCode(), message);
                throw new Exception("O11y API 오류: " + message);
            }

            @SuppressWarnings("unchecked")
            Map<String, Object> result = (Map<String, Object>) body.get("result");
            @SuppressWarnings("unchecked")
            List<Map<String, Object>> events = (List<Map<String, Object>>) result.get("events");

            if (events != null && !events.isEmpty()) {
                // 2c. X01_IF_EVENT_OBS batch INSERT
                Map<String, Object> insertParam = new HashMap<>();
                insertParam.put("systemCode", getSystemCode());
                insertParam.put("dataList", events);
                eventBatchMapper.insertTempEventObs(insertParam);

                totalCount += events.size();

                // 2d. seq 갱신 (방어: events 실제 max seq와 API last_seq 중 큰 값)
                long eventsMaxSeq = events.stream()
                        .mapToLong(e -> ((Number) e.get("seq")).longValue())
                        .max()
                        .orElse(currentSeq);

                Number lastSeq = (Number) result.get("last_seq");
                long apiLastSeq = (lastSeq != null) ? lastSeq.longValue() : currentSeq;

                currentSeq = Math.max(eventsMaxSeq, apiLastSeq);

                if (eventsMaxSeq != apiLastSeq) {
                    log.warn("[{}] seq 불일치: events max={}, API last_seq={}",
                            getSystemCode(), eventsMaxSeq, apiLastSeq);
                }

                log.debug("[{}] {} 건 적재, last_seq: {}", getSystemCode(), events.size(), currentSeq);
            }

            // 2e. has_more 체크
            Boolean hasMoreFlag = (Boolean) result.get("has_more");
            hasMore = Boolean.TRUE.equals(hasMoreFlag) && events != null && !events.isEmpty();
        }

        // 3. 최종 seq 업데이트
        Map<String, String> updateParameter = new HashMap<>();
        updateParameter.put("systemCode", getSystemCode());
        updateParameter.put("batchBean", getJobName());
        updateParameter.put("if_idx", String.valueOf(currentSeq));
        updateParameter.put("if_dt", "now()");
        batchSchedulerMapper.updateBatchEventInfo(updateParameter);

        log.info("[{}] O11y API 이벤트 수집 완료: {} 건, last_seq: {}",
                getSystemCode(), totalCount, currentSeq);
    }

    private RestTemplate createRestTemplate() {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(10_000);
        factory.setReadTimeout(30_000);
        return new RestTemplate(factory);
    }
}
```

---

## 6. EventBatchMapper.java 수정

> 파일: `src/main/java/com/ktc/luppiter/batch/mapper/EventBatchMapper.java`
> 변경: 메서드 2개 추가

**변경 전** (파일 끝):
```java
    // 예외신청건 만료 처리
    public Map<String, Object> expireEventException();
}
```

**변경 후**:
```java
    // 예외신청건 만료 처리
    public Map<String, Object> expireEventException();

    // 이벤트(Observability) 데이터 임시 테이블 입력
    public void insertTempEventObs(Map<String, Object> params);

    // Observability 데이터 통합
    public void combineEventForObs(Map<String, Object> params);
}
```

---

## 7. EventBatchMapper.xml 수정

> 파일: `src/main/resources/sqlmap/EventBatchMapper.xml`
> 변경: `</mapper>` 태그 직전에 3개 블록 추가

**`</mapper>` 직전에 추가**:

```xml
    <!-- 이벤트(Observability) 데이터 임시 테이블 입력 -->
    <insert id="insertTempEventObs" parameterType="java.util.HashMap">
        <!-- EventBatchMapper.insertTempEventObs -->
        INSERT INTO X01_IF_EVENT_OBS
            ( system_code
            , seq
            , event_id
            , type
            , status
            , region
            , zone
            , target_ip
            , target_name
            , target_contents
            , event_level
            , trigger_id
            , stdnm
            , occu_time
            , r_time
            , source
            , dashboard_url
            , dimensions
            , if_dt)
        VALUES
            <foreach collection="dataList" item="item" separator="," >
                (
                  #{systemCode}
                , #{item.seq}
                , #{item.event_id}
                , #{item.type}
                , #{item.status}
                , #{item.region}
                , #{item.zone}
                , #{item.target_ip}
                , #{item.target_name}
                , #{item.target_contents}
                , #{item.event_level}
                , #{item.trigger_id}
                , #{item.stdnm}
                , #{item.occu_time}::timestamp
                , #{item.r_time}::timestamp
                , #{item.source}
                , #{item.dashboard_url}
                , #{item.dimensions}::jsonb
                , now()
                )
            </foreach>
        ON CONFLICT DO NOTHING
    </insert>

    <!-- 임시 이벤트 데이터(Observability) 와 메인 이벤트 테이블 통합 Procedure 호출 -->
    <select id="combineEventForObs" parameterType="java.util.Map" statementType="CALLABLE">
        CALL p_combine_event_obs(#{systemCode,  mode=IN,    jdbcType=VARCHAR})
    </select>
```

---

## 8. CombineEventServiceJob.java 수정

> 파일: `src/main/java/com/ktc/luppiter/batch/task/common/CombineEventServiceJob.java`
> 변경: if-else 분기(83-89행) → Factory.combine() 위임 (1줄)

**변경 전** (83-89행):
```java
						try {

							if (StringUtils.equalsIgnoreCase(eventSyncTypeCode, EventWorkerFactory.EST020.getCode())) { // Zenius 인 경우
								eventBatchMapper.combineEventForZenius(combineParams);
							} else { // zabbix 인 경우
								eventBatchMapper.combineEventForZabbix(combineParams);
							}
```

**변경 후**:
```java
						try {

							// Factory enum에 위임 (EST010/011→Zabbix, EST020→Zenius, EST030→Obs)
							EventWorkerFactory.valueOf(eventSyncTypeCode).combine(eventBatchMapper, combineParams);
```

> import 변경 없음 — `EventWorkerFactory` 이미 import 되어 있음 (8행).

---

## 9. p_combine_event_obs 프로시저

> DB에서 직접 실행. 설계문서 4절의 구체 구현.
> p_combine_event_zabbix 패턴을 참고하되, type별 분기 처리 추가.

```sql
CREATE OR REPLACE PROCEDURE p_combine_event_obs(
    p_system_code VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cnt INTEGER := 0;
BEGIN
    -- ============================================================
    -- 1. Infra 타입: target_ip 기반 inventory_master 매칭
    -- ============================================================
    INSERT INTO cmon_event_info (
        system_code, event_id, event_state, event_level,
        target_ip, hostname, mgmt_ip, ipmi_ip, equ_barcode,
        l1_nm, l2_nm, l3_nm, zone, estdnm, gubun,
        host_group_nm, target_contents,
        occu_time, r_time, source, type, dashboard_url, dimensions,
        if_dt
    )
    SELECT
        obs.system_code,
        obs.event_id,
        obs.status,
        obs.event_level,
        obs.target_ip,
        inv.host_nm,
        inv.mgmt_ip,
        inv.ipmi_ip,
        inv.equnr,
        inv.l1_layer_cd,
        inv.l2_layer_cd,
        inv.l3_layer_cd,
        inv.zone,
        inv.e_std_nm,
        inv.control_area,
        inv.host_group_nm,
        obs.target_contents,
        obs.occu_time,
        obs.r_time,
        obs.source,
        obs.type,
        obs.dashboard_url,
        obs.dimensions,
        obs.if_dt
    FROM x01_if_event_obs obs
    INNER JOIN inventory_master inv ON inv.zabbix_ip = obs.target_ip
    WHERE obs.system_code = p_system_code
      AND obs.type IN ('infra')
    ON CONFLICT (system_code, event_id) DO UPDATE SET
        event_state = EXCLUDED.event_state,
        r_time = EXCLUDED.r_time,
        if_dt = EXCLUDED.if_dt;

    GET DIAGNOSTICS v_cnt = ROW_COUNT;
    RAISE NOTICE 'p_combine_event_obs [%] Infra: % 건', p_system_code, v_cnt;

    -- ============================================================
    -- 2. Service/Platform 타입: target_name + region 기반 매칭
    -- ============================================================
    INSERT INTO cmon_event_info (
        system_code, event_id, event_state, event_level,
        hostname, l1_nm, l2_nm, l3_nm, zone, gubun,
        host_group_nm, target_contents,
        occu_time, r_time, source, type, dashboard_url, dimensions,
        if_dt
    )
    SELECT
        obs.system_code,
        obs.event_id,
        obs.status,
        obs.event_level,
        obs.target_name,
        sinv.l1_layer_cd,
        sinv.l2_layer_cd,
        sinv.l3_layer_cd,
        sinv.zone,
        obs.type,        -- 'service' or 'platform' → gubun으로 사용
        sinv.host_group_nm,
        obs.target_contents,
        obs.occu_time,
        obs.r_time,
        obs.source,
        obs.type,
        obs.dashboard_url,
        obs.dimensions,
        obs.if_dt
    FROM x01_if_event_obs obs
    INNER JOIN cmon_service_inventory_master sinv
        ON sinv.service_nm = obs.target_name
        AND sinv.region = obs.region
    WHERE obs.system_code = p_system_code
      AND obs.type IN ('service', 'platform')
    ON CONFLICT (system_code, event_id) DO UPDATE SET
        event_state = EXCLUDED.event_state,
        r_time = EXCLUDED.r_time,
        if_dt = EXCLUDED.if_dt;

    GET DIAGNOSTICS v_cnt = ROW_COUNT;
    RAISE NOTICE 'p_combine_event_obs [%] Service/Platform: % 건', p_system_code, v_cnt;

    -- ============================================================
    -- 3. 처리 완료 데이터 삭제 (임시 테이블 정리)
    -- ============================================================
    DELETE FROM x01_if_event_obs
    WHERE system_code = p_system_code;

    GET DIAGNOSTICS v_cnt = ROW_COUNT;
    RAISE NOTICE 'p_combine_event_obs [%] 임시 데이터 삭제: % 건', p_system_code, v_cnt;

END;
$$;

COMMENT ON PROCEDURE p_combine_event_obs IS 'Observability 임시 이벤트를 cmon_event_info로 통합';
```

> **주의**: 위 프로시저는 cmon_event_info의 실제 컬럼명/제약조건에 맞춰 조정 필요.
> p_combine_event_zabbix를 참고하여 컬럼 매핑을 검증할 것.

---

## 체크리스트

| # | 작업 | 확인 |
|---|------|------|
| 1 | X01_IF_EVENT_OBS DDL 실행 | |
| 2 | C01_DBCONN_INFO DML 실행 (URL/API Key 실제값) | |
| 3 | C01_BATCH_EVENT DML 실행 (use_yn='N') | |
| 4 | EventJobWorker.java — DBInfo.isHttp()/isJdbc() 추가 | |
| 5 | EventWorkerFactory.java — 전체 교체 (EST030 + abstract combine) | |
| 6 | ObservabilityEventWorker.java — 신규 생성 | |
| 7 | EventBatchMapper.java — 메서드 2개 추가 | |
| 8 | EventBatchMapper.xml — INSERT + CALL 추가 | |
| 9 | CombineEventServiceJob.java — if-else → Factory.combine() | |
| 10 | p_combine_event_obs 프로시저 생성 (cmon_event_info 컬럼 검증 후) | |
| 11 | 빌드 확인 | |
| 12 | STG 환경에서 use_yn='Y' 활성화 후 테스트 | |
| 13 | EST010/011/020 회귀 테스트 (combine 정상 동작) | |

---

## 주의사항

1. **API Key 암호화**: 기존 `CryptoUtil.encrypt()` 사용. `EventJobWorker.setJobInfo()`에서 `db_pwd` → `cryptoUtil.decrypt(v)` 자동 복호화됨.
2. **system_code 채번**: ES0010/ES0011은 예시. 팀/DBA 협의 후 확정.
3. **use_yn='N'**: DML에서 비활성 상태로 추가. 검증 완료 후 'Y'로 전환.
4. **p_combine_event_obs**: cmon_event_info에 source/type/dashboard_url/dimensions 컬럼이 이미 ALTER로 추가되어 있어야 함 (02-ddl.sql 5절).
5. **dimensions 타입 캐스팅**: MyBatis에서 `#{item.dimensions}::jsonb`로 명시적 캐스팅. Jackson이 Map→String 직렬화 후 PostgreSQL이 jsonb로 변환.

---

**최종 업데이트**: 2026-02-10
