---
tags:
  - type/guide
  - service/luppiter
  - service/luppiter/o11y
  - audience/team
---

> 상위: [next-observability](README.md) · [docs](../../README.md)

# Observability 연동 - 구현 가이드

> 작성일: 2026-01-20
> 수정일: 2026-02-06
> 기준: luppiter_scheduler, luppiter_web 기존 패턴 준수

---

## 목차

**Part 1. Scheduler (luppiter_scheduler)**
1. [Scheduler 개요](#1-scheduler-개요)
2. [ObservabilityEventWorker 구현](#2-observabilityeventworker-구현)
3. [프로시저 구현](#3-프로시저-구현)

**Part 2. Web (luppiter_web)**
4. [프로젝트 구조](#4-프로젝트-구조)
5. [코딩 패턴](#5-코딩-패턴)
6. [기능별 구현 상세](#6-기능별-구현-상세)
   - 6.1 서비스/플랫폼 등록
   - 6.2 관제 대상 삭제 (탭 분리)
   - 6.3 예외 관리 (타입 선택 팝업)
   - 6.4 메인터넌스 관리 (타입 선택 팝업)
7. [API 엔드포인트 목록](#7-api-엔드포인트-목록)
8. [체크리스트](#8-체크리스트)
   - 8.6 기존 시스템 Cross-Cutting (TECHIOPS26-271)

---

# Part 1. Scheduler (luppiter_scheduler)

## 1. Scheduler 개요

### 1.1 처리 흐름

```
[Observability DB (GB)] → [ObservabilityEventWorker] → [x01_if_event_obs] → [프로시저] → [cmon_event_info]
                               (EST030-GB)                  (임시 테이블)                      (본 테이블)

[Observability DB (SE)] → [ObservabilityEventWorker] → [x01_if_event_obs] → [프로시저] → [cmon_event_info]
                               (EST030-SE)                  (임시 테이블)                      (본 테이블)
```

> **Note**: 연동 DB가 리전별로 분리됨 (현재: GB, SE). 리전 확장 시 Worker 추가 등록.

### 1.2 참고 파일

| 파일 | 용도 |
|------|------|
| `EventJobWorker.java` | 추상 클래스 (상속) |
| `ZeniusEventWorker.java` | DB 연동 패턴 참고 (동일 구조) |
| `EventWorkerFactory.java` | EST030 등록 필요 |

---

## 2. ObservabilityEventWorker 구현

### 2.1 신규 파일

```
src/main/java/com/ktc/luppiter/batch/task/builder/
└── ObservabilityEventWorker.java    # 신규

src/main/java/com/ktc/luppiter/batch/mapper/
└── IFEventMapper.java               # 쿼리 추가

src/main/resources/mybatis/mapper/
└── EventBatchMapper.xml             # INSERT 쿼리 추가
```

### 2.2 EventWorkerFactory 수정

```java
public enum EventWorkerFactory {

    EST010("EST010", () -> new ZabbixEventWorker("EST010")),
    EST011("EST011", () -> new ZabbixEventWorker("EST011")),
    EST020("EST020", () -> new ZeniusEventWorker("EST020")),
    EST030("EST030", () -> new ObservabilityEventWorker("EST030")),  // GB (경북)
    EST031("EST031", () -> new ObservabilityEventWorker("EST031"));  // SE (서울)

    // ... 이하 동일
}
```

### 2.3 C01_BATCH_EVENT 등록 (리전별)

> **리전 확장 시**: 새 리전 추가 시 아래 테이블에 행 추가 + EventWorkerFactory에 enum 추가

| system_code | batch_bean | 리전 | DB URL | 비고 |
|-------------|------------|------|--------|------|
| OBS001 | EST030 | GB (경북) | jdbc:postgresql://{gb-host}:{port}/{db} | |
| OBS002 | EST031 | SE (서울) | jdbc:postgresql://{se-host}:{port}/{db} | |
| OBS00N | EST03N | {신규리전} | jdbc:postgresql://{new-host}:{port}/{db} | 확장 시 |

### 2.3 ObservabilityEventWorker 클래스

```java
package com.ktc.luppiter.batch.task.builder;

import com.ktc.luppiter.batch.common.ErrorCode;
import com.ktc.luppiter.batch.mapper.IFEventMapper;
import com.ktc.luppiter.utils.ResultSetUtils;
import com.ktc.luppiter.utils.TaskDBConnection;
import com.zaxxer.hikari.HikariDataSource;
import lombok.extern.slf4j.Slf4j;

import java.sql.*;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;

@Slf4j
public class ObservabilityEventWorker extends EventJobWorker {

    private HikariDataSource dataSource = null;
    private Connection conn = null;
    private PreparedStatement pstmt = null;

    public ObservabilityEventWorker() {}

    public ObservabilityEventWorker(String eventSyncType) {
        super.setSyncTypeCode(eventSyncType);
    }

    @Override
    public void doProcess() throws Exception {
        log.info("[{}] {}", this.getSystemCode(), this.getSyncTypeCode());

        try {
            // 1. 마지막 연동 seq 조회
            Map<String, String> params = new HashMap<>();
            params.put("systemCode", getSystemCode());
            params.put("batchBean", getJobName());

            Map<String, String> batchEventInfo = eventBatchMapper.selectBatchEventInfo(params);

            long lastSeq = 0;
            if (batchEventInfo != null && batchEventInfo.get("if_idx") != null) {
                lastSeq = Long.parseLong(batchEventInfo.get("if_idx"));
            }

            // 2. Observability DB 연결
            log.debug("[{}] Observability DB 연결", getSystemCode());
            dataSource = TaskDBConnection.getDataSource(
                getSystemCode(),
                getDbInfo().getDriver(),
                getDbInfo().getUrl(),
                getDbInfo().getUserName(),
                getDbInfo().getPassword()
            );
            conn = Objects.requireNonNull(dataSource).getConnection();

            // 3. 이벤트 조회 (seq 기반 증분)
            String query = IFEventMapper.observabilityEvent;
            pstmt = conn.prepareStatement(query,
                ResultSet.TYPE_SCROLL_SENSITIVE,
                ResultSet.CONCUR_UPDATABLE);
            pstmt.setLong(1, lastSeq);
            pstmt.setQueryTimeout(30);

            ResultSet rs = pstmt.executeQuery();

            // 4. 결과 처리
            int transactionCount = 1000;
            List<List<Map<String, Object>>> tempDataList =
                ResultSetUtils.convertResultToListMap(rs, transactionCount);

            if (!tempDataList.isEmpty()) {
                processEvents(tempDataList);
            } else {
                log.debug("[{}] 가져올 원본 데이터가 없음", getSystemCode());
                updateBatchEventTime();
            }

        } catch (Exception e) {
            throw e;
        } finally {
            closeResources();
        }
    }

    private void processEvents(List<List<Map<String, Object>>> tempDataList) {
        // 상세 구현은 2.4 참고
    }

    private void updateBatchEventTime() {
        Map<String, String> param = new HashMap<>();
        param.put("systemCode", getSystemCode());
        param.put("batchBean", getSystemCode());
        param.put("if_dt", "now()");
        batchSchedulerMapper.updateBatchEventInfo(param);
    }

    private void closeResources() {
        try {
            if (pstmt != null) pstmt.close();
            if (conn != null) conn.close();
            if (dataSource != null) dataSource.close();
        } catch (SQLException ignore) {}
    }
}
```

### 2.4 processEvents() 상세

```java
private void processEvents(List<List<Map<String, Object>>> tempDataList) {
    log.debug("[{}] 이벤트 데이터 연동 작업 시작", getSystemCode());

    List<Integer> commitCountList = new ArrayList<>();
    List<Long> lastSeqList = new ArrayList<>();

    Map<String, String> updateParameter = new HashMap<>();
    updateParameter.put("systemCode", getSystemCode());
    updateParameter.put("batchBean", getSystemCode());

    Map<String, Object> insertParameter = new HashMap<>();
    insertParameter.put("systemCode", getSystemCode());

    tempDataList.forEach(list -> {
        try {
            // 데이터 가공
            list.forEach(data -> {
                // event_level 변환 (critical → 2, fatal → 4)
                String level = String.valueOf(data.get("event_level"));
                int eventLevel = "critical".equalsIgnoreCase(level) ? 2 : 4;
                data.put("event_level_code", eventLevel);
            });

            conn.setAutoCommit(false);

            // x01_if_event_obs에 INSERT
            insertParameter.put("dataList", list);
            eventBatchMapper.insertTempEventObs(insertParameter);

            // 마지막 seq 저장
            Optional<Long> maxSeq = list.stream()
                .map(o -> Long.parseLong(o.get("seq").toString()))
                .max(Long::compareTo);
            maxSeq.ifPresent(lastSeqList::add);

            conn.commit();
            commitCountList.add(list.size());

        } catch (SQLException e) {
            try { conn.rollback(); } catch (SQLException re) {}
            log.error("[{}] INSERT 실패: {}", getSystemCode(), e.getMessage());
        } finally {
            try { conn.setAutoCommit(true); } catch (SQLException ignore) {}
        }
    });

    // 마지막 seq 업데이트
    if (!lastSeqList.isEmpty()) {
        long maxSeq = lastSeqList.stream().max(Long::compareTo).get();
        int totalCount = commitCountList.stream().mapToInt(i -> i).sum();

        log.debug("[{}] 연동 완료 - 건수: {}, 마지막 seq: {}", getSystemCode(), totalCount, maxSeq);

        updateParameter.put("if_idx", String.valueOf(maxSeq));
        updateParameter.put("if_dt", "now()");
        batchSchedulerMapper.updateBatchEventInfo(updateParameter);
    }

    log.debug("[{}] 이벤트 데이터 연동 작업 종료", getSystemCode());
}
```

### 2.5 SQL 쿼리

#### IFEventMapper.java에 추가

```java
public static String observabilityEvent = """
    SELECT
        seq,
        event_id,
        type,
        status,
        region,
        zone,
        target_ip,
        target_name,
        target_contents,
        event_level,
        trigger_id,
        stdnm,
        occu_time,
        r_time,
        source,
        dashboard_url,
        dimensions::text as dimensions
    FROM obs_event_view
    WHERE seq > ?
    ORDER BY seq ASC
    LIMIT 5000
    """;
```

#### EventBatchMapper.xml에 추가

```xml
<insert id="insertTempEventObs" parameterType="hashmap">
    INSERT INTO x01_if_event_obs (
        seq, event_id, type, status, region, zone,
        target_ip, target_name, target_contents, event_level,
        trigger_id, stdnm, occu_time, r_time,
        source, dashboard_url, dimensions, if_dt
    ) VALUES
    <foreach collection="dataList" item="item" separator=",">
    (
        #{item.seq},
        #{item.event_id},
        #{item.type},
        #{item.status},
        #{item.region},
        #{item.zone},
        #{item.target_ip},
        #{item.target_name},
        #{item.target_contents},
        #{item.event_level},
        #{item.trigger_id},
        #{item.stdnm},
        #{item.occu_time},
        #{item.r_time},
        #{item.source},
        #{item.dashboard_url},
        #{item.dimensions}::jsonb,
        NOW()
    )
    </foreach>
</insert>
```

### 2.6 배치 등록 (DB)

`C01_BATCH_EVENT` 테이블에 등록:

```sql
INSERT INTO c01_batch_event (
    system_code,
    batch_bean,
    batch_title,
    event_sync_type,
    db_driver,
    db_url,
    db_user,
    db_pwd,
    use_yn
) VALUES (
    'OBS001',
    'EST030',
    'Observability 이벤트 연동',
    'EST030',
    'org.postgresql.Driver',
    'jdbc:postgresql://{host}:{port}/{db}',
    '{user}',
    '{encrypted_password}',
    'Y'
);
```

---

## 3. 프로시저 구현

### 3.1 개요

- 프로시저명: `p_combine_event_obs`
- 역할: x01_if_event_obs → cmon_event_info 이관
- 호출: CombineEventServiceJob에서 호출

### 3.2 처리 로직

```
[x01_if_event_obs 임시 데이터]
       │
       ▼
[타입 분기]
  ├─ Infra: target_ip 기준 inventory_master 매칭
  │         → 관제영역 파생 (CSW/HW/VM)
  │
  └─ Service/Platform: target_name + region 기준
                       cmon_service_inventory_master 매칭
                       → 미등록 시 Slack 알림
       │
       ▼
[예외 대상 체크]
  ├─ Infra: cmon_exception_event_detail 조회
  └─ Service/Platform: cmon_exception_service_detail 조회
       │
       ▼
[cmon_event_info INSERT/UPDATE]
  ├─ 신규 이벤트: INSERT
  └─ 해소 이벤트: UPDATE (r_time, status)
       │
       ▼
[x01_if_event_obs 삭제 또는 처리완료 마킹]
```

### 3.3 프로시저 골격

```sql
CREATE OR REPLACE PROCEDURE p_combine_event_obs()
LANGUAGE plpgsql
AS $$
DECLARE
    v_row RECORD;
    v_event_seq BIGINT;
    v_host_group VARCHAR(200);
    v_control_area VARCHAR(20);
    v_is_exception BOOLEAN;
BEGIN
    -- 1. 임시 테이블에서 미처리 데이터 조회
    FOR v_row IN
        SELECT * FROM x01_if_event_obs
        WHERE processed_yn = 'N'
        ORDER BY seq
    LOOP
        BEGIN
            -- 2. 타입별 분기 처리
            IF v_row.type = 'infra' THEN
                -- Infra 처리
                CALL p_process_infra_event(v_row, v_host_group, v_control_area, v_is_exception);
            ELSE
                -- Service/Platform 처리
                CALL p_process_service_event(v_row, v_host_group, v_control_area, v_is_exception);
            END IF;

            -- 3. 예외 대상이 아닌 경우 이벤트 저장
            IF NOT v_is_exception THEN
                IF v_row.status = 'firing' THEN
                    -- 신규 이벤트 INSERT
                    INSERT INTO cmon_event_info (...) VALUES (...);
                ELSE
                    -- 해소 이벤트 UPDATE
                    UPDATE cmon_event_info
                    SET r_time = v_row.r_time, status = 'resolved'
                    WHERE event_id = v_row.event_id;
                END IF;
            END IF;

            -- 4. 처리 완료 마킹
            UPDATE x01_if_event_obs
            SET processed_yn = 'Y'
            WHERE seq = v_row.seq;

        EXCEPTION WHEN OTHERS THEN
            -- 에러 로깅
            RAISE NOTICE 'Error processing seq %: %', v_row.seq, SQLERRM;
        END;
    END LOOP;
END;
$$;
```

### 3.4 미등록 이벤트 Slack 알림

Service/Platform 이벤트 중 매칭 실패 시:

```sql
-- Slack 알림용 테이블에 INSERT (별도 배치에서 Slack 발송)
INSERT INTO x01_unregistered_event_alert (
    event_id, type, target_name, region, occu_time, alert_yn, cret_dt
) VALUES (
    v_row.event_id, v_row.type, v_row.target_name, v_row.region, v_row.occu_time, 'N', NOW()
);
```

---

# Part 2. Web (luppiter_web)

---

## 4. 프로젝트 구조

### 4.1 서비스/플랫폼 관리 (구현 완료)

> **Note**: 기존 Stt* 파일 확장 방식으로 구현됨 (LUPR-687)

```
src/main/java/com/ktc/luppiter/web/
├── controller/
│   └── SttController.java                    # 기존 파일에 API 추가
├── service/
│   ├── SttService.java                       # 인터페이스 메서드 추가
│   └── impl/
│       └── SttServiceImpl.java               # 구현체 메서드 추가
└── mapper/
    └── SttMapper.java                        # 매퍼 메서드 추가

src/main/resources/sqlmap/
├── sql-stt.xml                               # 서비스 인벤토리 쿼리 추가
└── sql-ctl.xml                               # 호스트그룹 UNION 쿼리 추가

src/main/webapp/WEB-INF/jsp/stt/
├── servicePlatformManage.jsp                 # 목록 화면
└── popupServicePlatformInfo.jsp              # 등록/수정 팝업
```

**테이블**: `d00_service_inventory_master`

### 4.2 기존 파일 수정 (예정)

```
src/main/java/com/ktc/luppiter/web/
├── controller/
│   ├── InventoryManagerController.java       # 삭제 탭 분리
│   └── EvtController.java                    # 예외/메인터넌스 탭 분리
├── service/
│   └── impl/
│       ├── InventoryManagerServiceImpl.java  # 삭제 로직 확장
│       ├── EvtExcpService.java               # 예외 로직 확장
│       └── EvtCommService.java               # 공통 로직 확장
└── mapper/
    ├── InventoryManageMapper.java            # 삭제 쿼리 추가
    └── EvtExcpMapper.java                    # 예외 쿼리 추가

src/main/resources/sqlmap/
├── sql-inv-manage.xml                        # 삭제 쿼리 추가
└── sql-evt-excp.xml                          # 예외 쿼리 추가

src/main/webapp/WEB-INF/jsp/
├── mng/
│   └── deleteHosts.jsp                       # 삭제 화면 (탭 추가)
└── evt/
    ├── subEventExcpState.jsp                 # 예외 화면 (탭 추가)
    └── subMaintenanceState.jsp               # 메인터넌스 화면 (탭 추가)
```

---

## 5. 코딩 패턴

### 5.1 Controller 패턴

```java
@Controller
public class ObsController extends WebControllerHelper {

    Logger logger = LoggerFactory.getLogger(this.getClass());

    @Autowired
    private ObsServiceImpl obsService;

    /**
     * 서비스/플랫폼 등록 화면
     */
    @RequestMapping("/view/obs/serviceInventory")
    public ModelAndView serviceInventory(ModelAndView mav,
                                         @RequestParam Map<String, Object> map,
                                         HttpServletRequest request) throws Exception {
        // 초기화
        super.setInit(mav, map, request);
        // 화면VIEW
        super.setViewName(mav, map, "obs/serviceInventory");
        return mav;
    }

    /**
     * 서비스/플랫폼 목록 조회 API
     */
    @RequestMapping(value="/api/obs/service/list", method=RequestMethod.POST)
    public @ResponseBody Map<String, Object> getServiceInventoryList(
            @RequestParam Map<String, Object> map,
            HttpServletRequest request,
            PagingDto pagingDto) throws Exception {

        try {
            // 1. 초기화
            super.setInit(map, request);

            // 2. 목록 조회 + 페이징
            super.setPagingList(map, request, pagingDto,
                "serviceInventoryList",
                obsService.getServiceInventoryList(map));

        } catch(Exception e) {
            logger.error("[obs-service-list-exception] {}", e.getMessage());
            super.setResFail(map, request, e);
        }

        return map;
    }

    /**
     * 서비스/플랫폼 등록 API
     */
    @Transactional
    @RequestMapping(value="/api/obs/service/save", method=RequestMethod.POST)
    public @ResponseBody Map<String, Object> saveServiceInventory(
            @RequestBody Map<String, Object> map,
            HttpServletRequest request) throws Exception {

        try {
            // 1. 초기화
            super.setInit(map, request);

            // 2. 등록 처리
            logger.info("[obs-service-save] 서비스/플랫폼 등록 시작");
            obsService.saveServiceInventory(map);

            // 3. 성공 응답
            map.put("resCode", 200);
            logger.info("[obs-service-save] 서비스/플랫폼 등록 완료");

        } catch(Exception e) {
            logger.error("[obs-service-save-exception] {}", e.getMessage());
            super.setResFail(map, request, e);
        }

        return map;
    }
}
```

### 5.2 Service 패턴

```java
// Interface
public interface ObsService {

    // 서비스/플랫폼 목록 조회
    List<Map<String, Object>> getServiceInventoryList(Map<String, Object> map) throws Exception;

    // 서비스/플랫폼 등록
    int saveServiceInventory(Map<String, Object> map) throws Exception;

    // 서비스/플랫폼 삭제
    int deleteServiceInventory(Map<String, Object> map) throws Exception;
}

// Implementation
@Slf4j
@Service
public class ObsServiceImpl implements ObsService {

    @Autowired
    private ObsMapper obsMapper;

    @Override
    public List<Map<String, Object>> getServiceInventoryList(Map<String, Object> map) throws Exception {
        log.info("[getServiceInventoryList] params: {}", map);
        return obsMapper.selectServiceInventoryList(map);
    }

    @Override
    @Transactional
    public int saveServiceInventory(Map<String, Object> map) throws Exception {
        log.info("[saveServiceInventory] 등록 시작");

        // 1. 서비스/플랫폼 정보 저장
        int result = obsMapper.insertServiceInventory(map);

        // 2. 호스트그룹 자동생성
        if (result > 0) {
            String hostGroupNm = generateHostGroupName(map);
            map.put("hostGroupNm", hostGroupNm);
            obsMapper.insertHostGroup(map);
            log.info("[saveServiceInventory] 호스트그룹 생성: {}", hostGroupNm);
        }

        log.info("[saveServiceInventory] 등록 완료: {}", result);
        return result;
    }

    /**
     * 호스트그룹명 생성
     * 형식: {L1}-{L3}-{L4}-{관제영역}
     */
    private String generateHostGroupName(Map<String, Object> map) {
        return String.format("%s-%s-%s-%s",
            map.get("l1LayerNm"),
            map.get("l3LayerNm"),
            map.get("zone"),
            map.get("controlArea")
        );
    }
}
```

### 5.3 Mapper 패턴

```java
@Mapper
public interface ObsMapper {

    // 서비스/플랫폼 목록 조회
    List<Map<String, Object>> selectServiceInventoryList(Map<String, Object> map);

    // 서비스/플랫폼 등록
    int insertServiceInventory(Map<String, Object> map);

    // 서비스/플랫폼 삭제
    int deleteServiceInventory(Map<String, Object> map);

    // 호스트그룹 등록
    int insertHostGroup(Map<String, Object> map);
}
```

### 5.4 SQL 매핑 패턴

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
    "http://mybatis.org/dtd/mybatis-3-mapper.dtd">

<mapper namespace="com.ktc.luppiter.web.mapper.ObsMapper">

    <!-- 서비스/플랫폼 목록 조회 -->
    <select id="selectServiceInventoryList" resultType="java.util.HashMap">
    /* ObsMapper.selectServiceInventoryList */
        SELECT COUNT(*) OVER() AS total_count
             , inv.service_seq
             , inv.service_type
             , inv.service_nm
             , inv.namespace
             , inv.region
             , inv.l1_layer_cd
             , inv.l2_layer_cd
             , inv.l3_layer_cd
             , inv.zone
             , inv.host_group_nm
             , inv.use_yn
             , TO_CHAR(inv.cret_dt, 'YYYY-MM-DD HH24:MI:SS') AS cret_dt
             , inv.cretr_id
          FROM cmon_service_inventory_master inv
         WHERE 1=1
           AND inv.use_yn = 'Y'
        <if test="serviceType != null and serviceType != ''">
           AND inv.service_type = #{serviceType}
        </if>
        <if test="searchServiceNm != null and searchServiceNm != ''">
           AND inv.service_nm ILIKE CONCAT('%', #{searchServiceNm}, '%')
        </if>
        <if test="l1LayerCd != null and l1LayerCd != ''">
           AND inv.l1_layer_cd = #{l1LayerCd}
        </if>
         ORDER BY inv.cret_dt DESC
        <if test='pagingYn != null and pagingYn == "Y"'>
         LIMIT CAST(#{pageSize} AS INTEGER)
        OFFSET (CAST(#{pageNo} AS INTEGER) - 1) * CAST(#{pageSize} AS INTEGER)
        </if>
    </select>

    <!-- 서비스/플랫폼 등록 -->
    <insert id="insertServiceInventory">
    /* ObsMapper.insertServiceInventory */
        INSERT INTO cmon_service_inventory_master (
            service_type
          , service_nm
          , namespace
          , region
          , l1_layer_cd
          , l2_layer_cd
          , l3_layer_cd
          , zone
          , host_group_nm
          , use_yn
          , cret_dt
          , cretr_id
        ) VALUES (
            #{serviceType}
          , #{serviceNm}
          , #{namespace}
          , #{region}
          , #{l1LayerCd}
          , #{l2LayerCd}
          , #{l3LayerCd}
          , #{zone}
          , #{hostGroupNm}
          , 'Y'
          , NOW()
          , #{loginUserId}
        )
    </insert>

</mapper>
```

---

## 6. 기능별 구현 상세

### 6.1 서비스/플랫폼 등록 (구현 완료 - LUPR-687)

#### 6.1.1 화면 구성

| 구성요소 | 파일 | 비고 |
|---------|------|------|
| 메인 화면 | stt/servicePlatformManage.jsp | 목록 + 검색 |
| 등록/수정 팝업 | stt/popupServicePlatformInfo.jsp | 등록/수정 겸용 |

#### 6.1.2 API 목록

| API | Method | Endpoint | 설명 |
|-----|--------|----------|------|
| 목록 조회 | POST | /api/stt/servicePlatformList | 페이징 + 호스트그룹 권한 필터링 |
| 상세 조회 | POST | /api/stt/servicePlatformInfo | 단건 조회 |
| 중복 체크 | POST | /api/stt/servicePlatformCheck | svc_type + region 중복 확인 |
| 저장 | POST | /api/stt/saveServiceInventoryInfo | 등록/수정 (mode 파라미터) |

#### 6.1.3 권한

| 기능 | 권한 조건 |
|------|----------|
| 조회 | 사용자에게 할당된 호스트그룹만 (설비권한그룹-호스트그룹) |
| 저장 | `관제담당자` 역할만 |

> **Note**: 신규 호스트그룹 생성 시 [권한관리 > 설비권한그룹-호스트그룹]에서 할당 필요

#### 6.1.4 입력 항목

| 항목 | 필드명 | 타입 | 필수 | 비고 |
|------|--------|------|------|------|
| 서비스 타입 | svc_type | String | Y | 'SERVICE' / 'PLATFORM' |
| 리전 | region | String | Y | L4 Zone 코드 |
| L1 (분류) | l1_layer_cd | String | Y | 계위 코드 |
| L2 (도메인) | l2_layer_cd | String | Y | 계위 코드 |
| L3 (표준서비스) | l3_layer_cd | String | Y | 계위 코드 |

> **Note**: 서비스명(service_nm), Namespace 입력 필드 제거됨 (1/28 피드백 반영)

#### 6.1.5 처리 로직

```
[저장 버튼 클릭]
    │
    ▼
[권한 체크]
  └─ userAuth == '관제담당자' 확인
    │
    ▼
[Validation]
  ├─ 필수값 체크
  └─ 중복 체크 (svc_type + region)
    │
    ▼
[DB 저장]
  ├─ d00_service_inventory_master INSERT/UPDATE
  └─ 호스트그룹 자동생성 (cmon_layer_code_info INSERT)
    │
    ▼
[응답 반환]
```

#### 6.1.6 호스트그룹 네이밍 규칙

형식: `{L1_nm}_{L3_nm}_{L4_nm}_{svc_type_nm}`

예시: `클라우드_KT Cloud_G-SE_Service`

---

### 6.2 관제 대상 삭제 (탭 분리)

#### 6.2.1 화면 변경

**기존**: deleteHosts.jsp (Zabbix만)

**변경**: 탭 추가
- Tab 1: Zabbix (기존)
- Tab 2: Zenius (신규)
- Tab 3: Observability (신규)

#### 6.2.2 탭별 처리 로직

| 탭 | 장비 조회 | 삭제 처리 |
|----|----------|----------|
| Zabbix | inventory_master | DB 저장 + Zabbix API 삭제 |
| Zenius | inventory_master | DB 저장만 |
| O11y | cmon_service_inventory_master | DB 저장만 |

#### 6.2.3 API 추가/수정

| API | Method | Endpoint | 변경사항 |
|-----|--------|----------|---------|
| 삭제 처리 | POST | /api/mng/hostsMng/remove | monitorType 파라미터 추가 |

#### 6.2.4 파라미터 추가

```java
// 기존
map.put("requestType", "DEL");

// 변경 (monitorType 추가)
map.put("requestType", "DEL");
map.put("monitorType", "ZABBIX");  // ZABBIX / ZENIUS / O11Y
```

#### 6.2.5 Service 로직 수정

```java
public void removeHostManage(Map<String, Object> map) throws Exception {
    String monitorType = (String) map.get("monitorType");

    // 1. 삭제 정보 저장 (공통)
    putHostManageInfo(map);

    // 2. 시스템별 삭제 처리
    switch (monitorType) {
        case "ZABBIX":
            // Zabbix API 호출하여 실제 삭제
            removeZabbixHostForLIB(map);
            break;
        case "ZENIUS":
        case "O11Y":
            // DB 인벤토리만 삭제 (use_yn = 'N')
            updateInventoryUseYn(map);
            break;
    }
}
```

---

### 6.3 예외 관리 (타입 선택 팝업)

#### 6.3.1 화면 변경

**기존**: subEventExcpState.jsp (Infra만)

**변경**: 타입 선택 버튼 + 팝업 방식
- 버튼 클릭 시 팝업 표시
- 팝업 옵션:
  - Infra (Zabbix, Zenius, Observability)
  - Service (Observability)
  - Platform (Observability)
- 선택한 타입에 따라 컬럼 표시 분기

#### 6.3.2 탭별 조회 테이블

| 탭 | 장비 대상 조회 | 이벤트 목록 조회 | 저장 테이블 |
|----|--------------|-----------------|------------|
| Infra | inventory_master | Zabbix API (trigger) | cmon_exception_event_detail |
| Service | cmon_service_inventory_master | 인벤토리 + O11y API | cmon_exception_service_detail |
| Platform | cmon_service_inventory_master | 인벤토리 + O11y API | cmon_exception_service_detail |

#### 6.3.3 API 추가

| API | Method | Endpoint | 설명 |
|-----|--------|----------|------|
| 서비스 장비 조회 | POST | /api/evt/comm/serviceDeviceList | Service/Platform용 |
| 서비스 이벤트 조회 | POST | /api/evt/comm/serviceEventList | O11y API 연동 |
| 서비스 예외 등록 | POST | /api/evt/excp/saveService | Service/Platform용 |

#### 6.3.4 신규 Mapper 쿼리

```xml
<!-- 서비스/플랫폼 예외 상세 등록 -->
<insert id="insertExcpServiceDetail">
/* EvtExcpMapper.insertExcpServiceDetail */
    INSERT INTO cmon_exception_service_detail (
        excp_seq
      , service_type
      , service_nm
      , namespace
      , region
      , evt_name
      , trigger_id
      , l3_layer_cd
      , zone
      , host_group_nm
      , cret_dt
      , cretr_id
    ) VALUES (
        #{excp_seq}
      , #{serviceType}
      , #{serviceNm}
      , #{namespace}
      , #{region}
      , #{evtName}
      , #{triggerId}
      , #{l3LayerCd}
      , #{zone}
      , #{hostGroupNm}
      , NOW()
      , #{cretrId}
    )
</insert>
```

---

### 6.4 메인터넌스 관리 (타입 선택 팝업)

#### 6.4.1 화면 변경

**기존**: subMaintenanceState.jsp (Infra만)

**변경**: 타입 선택 버튼 + 팝업 방식
- 버튼 클릭 시 팝업 표시
- 팝업 옵션:
  - Infra (Zabbix, Observability) - Zenius 미지원
  - Service (Observability)
  - Platform (Observability)
- 선택한 타입에 따라 컬럼 표시 분기

> **주의**: Zenius는 메인터넌스 미지원 (팝업 내 안내 문구 표시)

#### 6.4.2 탭별 API 연동

| 탭 | 메인터넌스 API |
|----|---------------|
| Infra (Zabbix) | Zabbix API 실제 중단 |
| Infra (O11y) | O11y API 실제 중단 |
| Service | O11y API 실제 중단 |
| Platform | O11y API 실제 중단 |

#### 6.4.3 API 추가

| API | Method | Endpoint | 설명 |
|-----|--------|----------|------|
| 서비스 메인터넌스 등록 | POST | /api/evt/maint/saveService | Service/Platform용 |
| O11y 메인터넌스 API 호출 | - | ObsApiService | 외부 API 연동 |

#### 6.4.4 O11y API 연동 서비스 (멀티 리전)

> **Note**: O11y API가 리전별로 분리됨 (현재: GB, SE). 리전 확장 가능성 고려하여 Map 기반 설정 권장.

**설정 (application.yml)** - 리전 확장 고려:
```yaml
obs:
  api:
    timeout: 30000
    regions:
      GB:
        url: https://obs-api-gb.example.com
        name: 경북
      SE:
        url: https://obs-api-se.example.com
        name: 서울
      # 신규 리전 추가 시 여기에 추가
      # CC:
      #   url: https://obs-api-cc.example.com
      #   name: 충청
```

**서비스 구현** - Map 기반 리전 관리:
```java
@Slf4j
@Service
@ConfigurationProperties(prefix = "obs.api")
public class ObsApiService {

    private int timeout;
    private Map<String, RegionConfig> regions = new HashMap<>();

    @Data
    public static class RegionConfig {
        private String url;
        private String name;
    }

    /**
     * 리전 코드에서 API URL 추출
     * - region 값에서 리전 코드 파싱 (예: "DX-G-SE" → "SE")
     */
    private String getApiUrl(String region) {
        if (region == null) {
            throw new IllegalArgumentException("Region is required");
        }

        // 리전 코드 추출 (마지막 2자리 또는 설정된 패턴)
        for (String key : regions.keySet()) {
            if (region.contains(key)) {
                return regions.get(key).getUrl();
            }
        }

        throw new IllegalArgumentException("Unknown region: " + region);
    }

    /**
     * O11y 메인터넌스 등록
     */
    public Map<String, Object> createMaintenance(Map<String, Object> params) throws Exception {
        String region = (String) params.get("region");
        String baseUrl = getApiUrl(region);

        log.info("[O11y API] 메인터넌스 등록 요청 ({}): {}", region, params);

        String endpoint = baseUrl + "/api/v1/maintenance";

        // API 호출 로직 (RestTemplate 또는 WebClient 사용)
        // ...

        return result;
    }

    /**
     * O11y 메인터넌스 해제
     */
    public Map<String, Object> deleteMaintenance(Map<String, Object> params) throws Exception {
        String region = (String) params.get("region");
        String baseUrl = getApiUrl(region);

        log.info("[O11y API] 메인터넌스 해제 요청 ({}): {}", region, params);

        // API 호출 로직
        // ...

        return result;
    }

    // Getter/Setter for ConfigurationProperties
    public void setTimeout(int timeout) { this.timeout = timeout; }
    public void setRegions(Map<String, RegionConfig> regions) { this.regions = regions; }
}
```

> **예외 API도 동일한 방식으로 리전별 분기 적용**

**리전 확장 체크리스트**:
- [ ] application.yml에 신규 리전 설정 추가
- [ ] C01_BATCH_EVENT 테이블에 신규 리전 Worker 등록
- [ ] EventWorkerFactory에 신규 리전 enum 추가
- [ ] 테스트: 신규 리전 DB 연결 및 API 호출 확인

---

## 7. API 엔드포인트 목록

### 7.1 신규 API

| 기능 | Method | Endpoint | Controller |
|------|--------|----------|------------|
| 서비스/플랫폼 목록 | POST | /api/obs/service/list | ObsController |
| 서비스/플랫폼 상세 | POST | /api/obs/service/detail | ObsController |
| 서비스/플랫폼 등록 | POST | /api/obs/service/save | ObsController |
| 서비스/플랫폼 수정 | POST | /api/obs/service/update | ObsController |
| 서비스/플랫폼 삭제 | POST | /api/obs/service/delete | ObsController |
| 서비스 장비 조회 | POST | /api/evt/comm/serviceDeviceList | EvtController |
| 서비스 이벤트 조회 | POST | /api/evt/comm/serviceEventList | EvtController |
| 서비스 예외 등록 | POST | /api/evt/excp/saveService | EvtExcpRestController |
| 서비스 메인터넌스 등록 | POST | /api/evt/maint/saveService | EvtMaintController |

### 7.2 수정 API

| 기능 | Method | Endpoint | 변경사항 |
|------|--------|----------|---------|
| 관제삭제 | POST | /api/mng/hostsMng/remove | monitorType 파라미터 추가 |
| 예외 등록 | POST | /api/evt/excp/save | eventType 파라미터 추가 |
| 메인터넌스 등록 | POST | /api/evt/maint/save | eventType 파라미터 추가 |

---

## 8. 체크리스트

### 8.0 Scheduler (luppiter_scheduler)

- [ ] EventWorkerFactory에 EST030 등록
- [ ] ObservabilityEventWorker.java 생성
- [ ] IFEventMapper.java에 observabilityEvent 쿼리 추가
- [ ] EventBatchMapper.xml에 insertTempEventObs 추가
- [ ] C01_BATCH_EVENT 테이블에 OBS001 등록
- [ ] DB 연결 테스트 (Observability DB)
- [ ] seq 기반 증분 조회 정상 동작
- [ ] x01_if_event_obs INSERT 정상
- [ ] 프로시저 p_combine_event_obs 생성
- [ ] CombineEventServiceJob에 프로시저 호출 추가

### 8.1 공통

- [ ] WebControllerHelper 상속
- [ ] super.setInit() 호출
- [ ] super.setResFail() 에러 처리
- [ ] @Transactional 적용 (CUD 작업)
- [ ] Logger 로깅 (시작/완료/에러)
- [ ] Map<String, Object> 파라미터 사용

### 8.2 서비스/플랫폼 등록 ✅ (LUPR-687 완료)

- [x] SttController.java에 API 추가
- [x] SttService.java 인터페이스 메서드 추가
- [x] SttServiceImpl.java 구현체 메서드 추가
- [x] SttMapper.java 매퍼 메서드 추가
- [x] sql-stt.xml SQL 쿼리 추가
- [x] servicePlatformManage.jsp 화면 생성
- [x] popupServicePlatformInfo.jsp 팝업 생성
- [x] 호스트그룹 자동생성 로직
- [x] 권한 체크 (관제담당자)
- [x] 호스트그룹 기반 조회 필터링

### 8.3 관제 대상 삭제

- [ ] deleteHosts.jsp 탭 추가
- [ ] monitorType 파라미터 처리
- [ ] Zenius/O11y 삭제 로직 (DB만)
- [ ] 삭제 테이블 분기 처리

### 8.4 예외 관리

- [ ] subEventExcpState.jsp 타입 선택 버튼/팝업 추가
- [ ] 타입별 컬럼 표시 분기 처리
- [ ] cmon_exception_service_detail 테이블 사용
- [ ] 서비스 장비 조회 API
- [ ] O11y 이벤트 조회 API

### 8.5 메인터넌스 관리

- [ ] subMaintenanceState.jsp 타입 선택 버튼/팝업 추가
- [ ] 타입별 컬럼 표시 분기 처리
- [ ] cmon_maintenance_service_detail 테이블 사용
- [ ] O11y API 연동 서비스
- [ ] Zenius 미지원 안내 문구

### 8.6 기존 시스템 Cross-Cutting (TECHIOPS26-271)

서비스 인벤토리 추가에 따른 기존 쿼리/데이터 영향도 항목:

- [ ] CONTROL_AREA 공통코드 추가 (Service, Platform) → `02-ddl.sql` 6장
- [ ] c02_zone_type_mapping 서비스 zone 등록 → `02-ddl.sql` 7장
- [ ] 기존 이벤트 데이터 마이그레이션 (source/type UPDATE) → `02-ddl.sql` 8장
- [ ] 기존 쿼리 inventory_master UNION 반영 (WEB ~30건, Scheduler 6건) → `04-functional-spec.md` 9장
- [ ] Excel 다운로드 쿼리 서비스 인벤토리 반영
- [ ] 검색 조건 드롭다운 확장 (관제영역/표준서비스)
- [ ] 권한 체계 초기 설정 (설비권한그룹-호스트그룹 할당)

> 상세 쿼리 목록: `04-functional-spec.md` 9장
> 협력사 공유 가이드: `docs/temp/observability-cross-cutting-guide.md`

---

## 부록: 참고 파일

### 기존 패턴 참고

| 기능 | 참고 파일 |
|------|----------|
| Controller | InventoryManagerController.java |
| Service | InventoryManagerServiceImpl.java |
| Mapper | InventoryManageMapper.java |
| SQL | sql-inv-manage.xml |
| JSP (목록) | mng/deleteHosts.jsp |
| JSP (팝업) | mng/popupHostsRegist.jsp |
| 예외 관리 | EvtExcpService.java, sql-evt-excp.xml |
