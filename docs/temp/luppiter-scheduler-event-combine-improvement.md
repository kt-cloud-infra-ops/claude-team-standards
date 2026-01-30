# Luppiter Scheduler 이벤트 취합 성능 개선

## 현황

### 문제점
- CombineEventServiceJob 실행시간: 13.9s → 28.2s (증가 추세)
- 알람 발송 지연 발생

### 원인 분석

**1. 순차 처리 구조**
```java
// 6개 시스템을 순차적으로 처리
for(Map<String, String> map : batchMapList) {
    eventBatchMapper.combineEventForZabbix(combineParams);  // 또는 combineEventForZenius
}
```

**2. 임시 테이블 데이터 누적**
| 테이블 | 용도 | 인덱스 |
|--------|------|--------|
| x01_if_event_data | Zabbix 이벤트 임시 | O (3개) |
| x01_if_event_zenius | Zenius 이벤트 임시 | **X (없음!)** |

**3. 프로시저별 특징**
| 프로시저 | 인터페이스 테이블 | 해소 방식 |
|---------|-------------------|-----------|
| p_combine_event_zabbix | x01_if_event_data | recovery_dst_id 매칭 |
| p_combine_event_zenius | x01_if_event_zenius | 인터페이스 미존재 시 해소 |

---

## Track 1: 즉시 조치 (운영 안정화)

### 1.1 임시 테이블 DROP 및 재생성

**Step 1. 연동 Job 중지**
```sql
UPDATE c01_batch_event
SET use_yn = 'N'
WHERE use_yn = 'Y';
```

**Step 2. 테이블 DROP 및 재생성**
```sql
-- x01_if_event_data
DROP TABLE IF EXISTS x01_if_event_data;

CREATE TABLE public.x01_if_event_data (
    system_code         varchar(50) not null,
    event_id            int8 not null,
    event_dt            timestamp not null,
    event_level         int8 not null,
    event_contents      varchar(2048) not null,
    event_status        int4 not null,
    recovery_dst_id     int8,
    event_ip            varchar(20),
    host_id             int8,
    template_id         int8,
    trigger_id          int8,
    item_id             int8,
    status_agent        int4,
    status_ipmi         int4,
    status_snmp         int4,
    status_jmx          int4,
    if_dt               timestamp not null,
    maintenance_status  int4
);

CREATE INDEX x01_if_event_data_system_code_idx ON x01_if_event_data (system_code, event_id);
CREATE INDEX x01_if_event_data_event_id_idx ON x01_if_event_data (event_id);
CREATE INDEX x01_if_event_data_trigger_id_idx ON x01_if_event_data (trigger_id);

-- x01_if_event_zenius
DROP TABLE IF EXISTS x01_if_event_zenius;

CREATE TABLE public.x01_if_event_zenius (
    system_code varchar(50) NOT NULL,
    z_status int4 NULL,
    z_alert int4 NULL,
    z_evttime timestamp NULL,
    z_rectime timestamp NULL,
    z_infraid int4 NULL,
    z_myhost varchar(500) NULL,
    z_myip varchar(200) NULL,
    z_myname varchar(200) NULL,
    z_mymsg varchar(1000) NULL,
    z_myid varchar(20) NULL,
    z_setid int4 NULL,
    zenius_level varchar(20) NULL,
    infra_code int4 NULL,
    event_level int8 NOT NULL,
    set_name varchar(20) NULL,
    event_code varchar(20) NULL,
    if_idx varchar(30) NULL,
    if_dt timestamp NOT NULL,
    maintenance_status int4 NULL
);

CREATE INDEX x01_if_event_zenius_system_code_idx ON x01_if_event_zenius (system_code, if_idx);
CREATE INDEX x01_if_event_zenius_z_myip_z_myid_idx ON x01_if_event_zenius (z_myip, z_myid);
```

**Step 3. 연동 Job 재시작**
```sql
UPDATE c01_batch_event
SET use_yn = 'Y'
WHERE use_yn = 'N';
```

**예상 소요시간:** 1~2분

### 1.2 누락된 인덱스 추가

```sql
-- x01_if_event_zenius 인덱스 추가 (현재 없음)
CREATE INDEX x01_if_event_zenius_system_code_idx
    ON public.x01_if_event_zenius (system_code, if_idx);

CREATE INDEX x01_if_event_zenius_z_myip_z_myid_idx
    ON public.x01_if_event_zenius (z_myip, z_myid);

CREATE INDEX x01_if_event_zenius_if_idx_idx
    ON public.x01_if_event_zenius (if_idx);

-- 통계 갱신
ANALYZE x01_if_event_zenius;
```

### 1.3 예상 효과
- 임시 테이블 조회 성능 개선
- 실행시간: 28.2s → **10초대** 예상

---

## Track 2: 장기 개선 (Java 프로세스 전환)

### 2.1 주기적 관리 체계

> **적용 시점:** 스케줄러 배포 시 적용

**A. 임시 테이블 정리 Job 추가**

```java
@Component
public class CleanupIfEventDataJob extends AbstractBatchJob {

    private static final int RETENTION_DAYS = 7;  // 7일 보관

    @Scheduled(cron = "0 0 3 * * ?")  // 매일 03:00
    public void execute() {
        // 7일 이전 데이터 삭제
        eventBatchMapper.deleteOldIfEventData(RETENTION_DAYS);
        eventBatchMapper.deleteOldIfEventZenius(RETENTION_DAYS);

        // 테이블 통계 갱신
        eventBatchMapper.analyzeIfEventTables();
    }
}
```

**B. Mapper 추가**

```xml
<delete id="deleteOldIfEventData">
    DELETE FROM x01_if_event_data
    WHERE if_dt < NOW() - INTERVAL '${days} days'
</delete>

<delete id="deleteOldIfEventZenius">
    DELETE FROM x01_if_event_zenius
    WHERE if_dt < NOW() - INTERVAL '${days} days'
</delete>

<update id="analyzeIfEventTables">
    ANALYZE x01_if_event_data;
    ANALYZE x01_if_event_zenius;
</update>
```

### 2.2 Java 로직 전환 (프로시저 대체)

**A. 전환 범위**

| 프로시저 | Java 클래스 | 우선순위 |
|---------|------------|---------|
| p_combine_event_zabbix | ZabbixEventCombineService | 높음 |
| p_combine_event_zenius | ZeniusEventCombineService | 높음 |

**B. 아키텍처**

```
┌─────────────────────────────────────────────────────────────┐
│                  CombineEventServiceJob                      │
│                        (Scheduler)                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  EventCombineOrchestrator                    │
│           (병렬 실행 관리, CompletableFuture)                 │
└─────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
    ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
    │ ZabbixEvent   │ │ ZabbixEvent   │ │ ZeniusEvent   │
    │ CombineService│ │ CombineService│ │ CombineService│
    │   (ES0001)    │ │   (ES0002)    │ │   (ES0006)    │
    └───────────────┘ └───────────────┘ └───────────────┘
```

**C. 핵심 인터페이스**

```java
public interface IEventCombineService {

    /**
     * 이벤트 취합 실행
     * @param systemCode 시스템 코드
     * @return 처리 결과
     */
    CombineResult combine(String systemCode);
}

@Data
@Builder
public class CombineResult {
    private String systemCode;
    private int newEventCount;      // 신규 이벤트 수
    private int resolvedEventCount; // 해소 이벤트 수
    private long elapsedTimeMs;     // 처리 시간
    private boolean success;
    private String errorMessage;
}
```

**D. Orchestrator 구현**

```java
@Service
@RequiredArgsConstructor
public class EventCombineOrchestrator {

    private final ZabbixEventCombineService zabbixService;
    private final ZeniusEventCombineService zeniusService;

    @Async
    public CompletableFuture<List<CombineResult>> combineAll(List<BatchEventConfig> configs) {

        List<CompletableFuture<CombineResult>> futures = configs.stream()
            .map(config -> CompletableFuture.supplyAsync(() -> {
                if (EST020.equals(config.getEventSyncTypeCode())) {
                    return zeniusService.combine(config.getSystemCode());
                } else {
                    return zabbixService.combine(config.getSystemCode());
                }
            }))
            .collect(Collectors.toList());

        return CompletableFuture.allOf(futures.toArray(new CompletableFuture[0]))
            .thenApply(v -> futures.stream()
                .map(CompletableFuture::join)
                .collect(Collectors.toList()));
    }
}
```

**E. Zabbix 이벤트 취합 서비스**

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class ZabbixEventCombineService implements IEventCombineService {

    private final EventCombineMapper eventCombineMapper;
    private final EventInfoMapper eventInfoMapper;
    private final InventoryMasterMapper inventoryMapper;

    @Override
    @Transactional
    public CombineResult combine(String systemCode) {
        long startTime = System.currentTimeMillis();

        try {
            // 1. 시스템 설정 조회
            BatchEventConfig config = eventCombineMapper.getBatchEventConfig(systemCode);
            validateConfig(config);

            // 2. 신규 이벤트 처리
            int newCount = processNewEvents(config);

            // 3. 해소 이벤트 처리
            int resolvedCount = processResolvedEvents(config);

            // 4. sync_idx 업데이트
            updateSyncIdx(config);

            return CombineResult.builder()
                .systemCode(systemCode)
                .newEventCount(newCount)
                .resolvedEventCount(resolvedCount)
                .elapsedTimeMs(System.currentTimeMillis() - startTime)
                .success(true)
                .build();

        } catch (Exception e) {
            log.error("Event combine failed for system: {}", systemCode, e);
            return CombineResult.builder()
                .systemCode(systemCode)
                .elapsedTimeMs(System.currentTimeMillis() - startTime)
                .success(false)
                .errorMessage(e.getMessage())
                .build();
        }
    }

    private int processNewEvents(BatchEventConfig config) {
        // 신규 이벤트 조회
        List<IfEventData> newEvents = eventCombineMapper.findNewEvents(
            config.getSystemCode(),
            config.getSyncIdx()
        );

        if (newEvents.isEmpty()) {
            return 0;
        }

        // 이벤트 변환 및 저장
        List<EventInfo> eventInfoList = newEvents.stream()
            .map(this::convertToEventInfo)
            .filter(Objects::nonNull)
            .collect(Collectors.toList());

        // 배치 INSERT
        if (!eventInfoList.isEmpty()) {
            eventInfoMapper.batchInsert(eventInfoList);

            // 대응관리 정보 입력
            eventInfoList.forEach(this::insertRespManageInfo);
        }

        return eventInfoList.size();
    }

    private EventInfo convertToEventInfo(IfEventData ifEvent) {
        // 인벤토리 매핑
        InventoryMaster inventory = inventoryMapper.findByZabbixIp(ifEvent.getEventIp());
        if (inventory == null) {
            log.warn("Inventory not found for IP: {}", ifEvent.getEventIp());
            return null;
        }

        // 예외 처리 체크
        String eventState = checkExceptionEvent(ifEvent) ? "예외" : "신규";

        return EventInfo.builder()
            .eventId(generateEventId())
            .occuTime(ifEvent.getEventDt())
            .targetIp(ifEvent.getEventIp())
            .targetContents(ifEvent.getEventContents())
            .sendAgent(config.getSystemIp())
            .eventLevel(convertEventLevel(ifEvent.getEventLevel()))
            .equBarcode(inventory.getEqunr())
            .deviceIp(inventory.getMgmtIp())
            // ... 나머지 필드 매핑
            .eventState(eventState)
            .zabbixState("지속")
            .triggerId(ifEvent.getTriggerId())
            .ifEventId(ifEvent.getEventId())
            .createTime(LocalDateTime.now())
            .lastOccuTime(LocalDateTime.now())
            .build();
    }

    private int processResolvedEvents(BatchEventConfig config) {
        // 해소 이벤트 업데이트
        return eventCombineMapper.updateResolvedEvents(
            config.getSystemCode(),
            config.getSyncIdx(),
            config.getSystemIp()
        );
    }
}
```

### 2.3 DB 파티션 검토

임시 테이블의 지속적인 성능 관리를 위해 파티션 적용 검토 중

**검토 대상 테이블:**
- x01_if_event_data
- x01_if_event_zenius

**파티션 전략 (안):**

| 전략 | 파티션 키 | 장점 | 단점 |
|-----|----------|------|------|
| Range (월별) | if_dt | 오래된 데이터 DROP 용이 | 월별 파티션 관리 필요 |
| Range (일별) | if_dt | 세밀한 보관 정책 | 파티션 수 증가 |

**예시 DDL:**
```sql
-- 월별 파티션 테이블 생성
CREATE TABLE x01_if_event_data_partitioned (
    LIKE x01_if_event_data INCLUDING ALL
) PARTITION BY RANGE (if_dt);

-- 월별 파티션 생성
CREATE TABLE x01_if_event_data_202601
    PARTITION OF x01_if_event_data_partitioned
    FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');

-- 오래된 파티션 삭제 (DELETE 대비 즉시 완료)
DROP TABLE x01_if_event_data_202601;
```

**기대 효과:**
- DELETE 대비 파티션 DROP으로 즉시 정리 가능
- 조회 시 파티션 프루닝으로 성능 향상

**검토 상태:** DBA 협의 진행 중

---

### 2.4 마이그레이션 계획

| 단계 | 작업 | 기간 | 비고 |
|-----|------|------|------|
| 1 | 임시테이블 정리 Job 추가 | 1일 | 스케줄러 배포 시 적용 |
| 2 | DB 파티션 검토/적용 | - | DBA 협의 |
| 3 | Java 서비스 인터페이스 설계 | 1일 | IEventCombineService |
| 4 | ZabbixEventCombineService 구현 | 3일 | 프로시저 로직 전환 |
| 5 | ZeniusEventCombineService 구현 | 2일 | 프로시저 로직 전환 |
| 6 | Orchestrator 병렬 처리 구현 | 1일 | CompletableFuture |
| 7 | 통합 테스트 | 2일 | 기능 검증 |
| 8 | 운영 배포 | 1일 | 프로시저 → Java 전환 |

---

## 시퀀스 함수 분석 (참고)

### get_next_event_sequence()

```sql
-- 일별 시퀀스 자동 생성
-- 형식: E + YYYYMMDD + 5자리시퀀스
-- 예: E2026012700001

CREATE OR REPLACE FUNCTION get_next_event_sequence()
RETURNS text AS $$
DECLARE
    seq_name TEXT := 'seq_event_info_' || TO_CHAR(NOW(), 'YYYYMMDD');
BEGIN
    -- 시퀀스 없으면 생성
    IF NOT EXISTS (SELECT 1 FROM pg_class WHERE relname = seq_name) THEN
        EXECUTE format('CREATE SEQUENCE %I START 1 CACHE 1', seq_name);
    END IF;

    -- 다음 값 반환
    RETURN 'E' || TO_CHAR(NOW(), 'YYYYMMDD') ||
           LPAD(nextval(seq_name)::TEXT, 5, '0');
END;
$$ LANGUAGE plpgsql;
```

**병렬 처리 안전성:** ✅
- PostgreSQL 시퀀스는 동시 접근 시 원자적 처리
- CACHE 1 설정으로 Gap 최소화

### fn_cleanup_old_sequences()

```sql
-- 7일 이전 시퀀스 삭제 (메모리 관리)
SELECT fn_cleanup_old_sequences(7);
```

---

## 체크리스트

### Track 1: 즉시 조치
- [ ] 연동 Job 중지 (use_yn = 'N')
- [ ] x01_if_event_data DROP 및 재생성
- [ ] x01_if_event_zenius DROP 및 재생성 (인덱스 포함)
- [ ] 연동 Job 재시작 (use_yn = 'Y')
- [ ] CombineEventServiceJob 실행 시간 확인

### Track 2: 장기 개선
- [ ] CleanupIfEventDataJob 개발 (스케줄러 배포 시 적용)
- [ ] DB 파티션 검토 (DBA 협의)
- [ ] IEventCombineService 인터페이스 정의
- [ ] ZabbixEventCombineService 구현
- [ ] ZeniusEventCombineService 구현
- [ ] EventCombineOrchestrator 병렬 처리 구현
- [ ] 단위 테스트 작성
- [ ] 통합 테스트 (STG 환경)
- [ ] 운영 배포

---

## 관련 파일

| 파일 | 경로 |
|-----|------|
| Job 클래스 | luppiter_scheduler/.../CombineEventServiceJob.java |
| Zabbix 프로시저 | luppiter_scheduler/DDML/p_combine_event_zabbix_.sql |
| Zenius 프로시저 | luppiter_scheduler/DDML/p_combine_event_zenius.sql |
| 시퀀스 함수 | luppiter_scheduler/DDML/fn_event_id_채번관련.sql |
| DDL | luppiter_scheduler/DDML/[DDL]Luppiter_Scheduler.sql |
