# Luppiter Scheduler 이벤트 처리 Java 전환 상세 설계

> 작성일: 2026-01-28
> 버전: 1.1
> 상태: 설계 중
> 변경이력: Registry 패턴 적용 (OCP 준수)

---

## 1. 개요

### 1.1 목적

Luppiter Scheduler의 이벤트 연동(Sync) 및 취합(Combine) 로직을 프로시저 기반에서 Java 서비스 기반으로 전환하여 성능, 유지보수성, 테스트 용이성을 개선한다.

### 1.2 범위

| 구분 | AS-IS | TO-BE |
|------|-------|-------|
| 이벤트 연동 | ZabbixEventWorker, ZeniusEventWorker | ZabbixEventSyncService, ZeniusEventSyncService |
| 이벤트 취합 | p_combine_event_zabbix, p_combine_event_zenius (프로시저) | ZabbixEventCombineService, ZeniusEventCombineService |
| 실행 방식 | 순차 처리 (for loop) | 병렬 처리 (CompletableFuture) |

### 1.3 기대 효과

| 항목 | AS-IS | TO-BE | 개선율 |
|------|-------|-------|--------|
| 취합 소요시간 | 36초 | 6~8초 | **80% 감소** |
| 테스트 커버리지 | 0% (프로시저) | 80%+ | - |
| 디버깅 용이성 | 낮음 | 높음 | - |

### 1.4 설계 원칙

| 원칙 | 적용 |
|------|------|
| **OCP** (Open-Closed Principle) | 새 시스템 추가 시 기존 코드 수정 없이 확장 가능 |
| **SRP** (Single Responsibility) | 각 Service는 하나의 시스템 타입만 담당 |
| **DIP** (Dependency Inversion) | Orchestrator는 인터페이스에 의존 |
| **Strategy Pattern** | 시스템별 다른 처리 로직 캡슐화 |
| **Registry Pattern** | Service 자동 등록 및 탐색 |

### 1.5 확장성

**새 시스템(예: Observability) 추가 시:**
1. `ObservabilityEventCombineService` 클래스 생성 (IEventCombineService 구현)
2. DB에 시스템 설정 추가 (`c01_batch_event`)
3. **끝!** - Orchestrator 수정 불필요

---

## 2. 현재 구조 분석 (AS-IS)

### 2.1 전체 흐름

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              매분 타임라인                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│  :00              :20                        :50              :00(다음분)    │
│   │                │                          │                │            │
│   ▼                ▼                          ▼                ▼            │
│ [연동Job]       [취합Job]                  [알림Job]       [연동Job]        │
│ EventSync      CombineEvent              EventAlarm       EventSync        │
│                    │                                                        │
│                    │←────── 정상: ~15초 ──────→│                            │
│                    │←────── 현재: 36초 ────────│→ 겹침!                     │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 이벤트 연동 (Sync) - 현재 구조

```java
// EventWorkerFactory.java
EST010("EST010", () -> new ZabbixEventWorker("EST010")),  // Zabbix v5
EST011("EST011", () -> new ZabbixEventWorker("EST011")),  // Zabbix v7
EST020("EST020", () -> new ZeniusEventWorker("EST020"));  // Zenius
```

#### ZabbixEventWorker 흐름
```
1. c01_batch_event에서 if_idx(마지막 연동 ID) 조회
2. Zabbix DB 연결
3. event_id > if_idx 조건으로 이벤트 조회
4. CSV 변환 후 x01_if_event_data에 COPY
5. c01_batch_event.if_idx 업데이트
```

#### ZeniusEventWorker 흐름
```
1. c01_batch_event에서 if_dt(마지막 연동 시간) 조회
2. Zenius DB 연결
3. 이벤트 조회 (SMS/NMS 전체 + SYSLOG는 시간 이후)
4. 데이터 가공 (zenius_level, event_code 등)
5. x01_if_event_zenius에 배치 INSERT
6. c01_batch_event.if_idx, if_dt 업데이트
```

### 2.3 이벤트 취합 (Combine) - 현재 구조

```java
// CombineEventServiceJob.java (69-96줄)
for(Map<String, String> map : batchMapList) {
    if (EST020.equals(eventSyncTypeCode)) {
        eventBatchMapper.combineEventForZenius(combineParams);  // 프로시저 호출
    } else {
        eventBatchMapper.combineEventForZabbix(combineParams);  // 프로시저 호출
    }
}
```

#### p_combine_event_zabbix 프로시저 로직
```
1. 시스템 설정 조회 (system_ip, sync_idx)
2. 신규 이벤트 처리
   2.1. x01_if_event_data → cmon_event_info INSERT
        - inventory_master 조인 (IP 매핑)
        - cmon_exception_event 조인 (예외 처리)
        - cmon_layer_code_info 조인 (계위 정보)
   2.2. cmon_event_resp_manage_info INSERT (대응관리)
3. 해소 이벤트 처리
   3.1. 예외 이벤트 해소 (event_state='예외')
   3.2. 일반 해소 (recovery_dst_id 매칭)
4. sync_idx 업데이트
```

#### p_combine_event_zenius 프로시저 로직
```
1. 시스템 설정 조회 (system_ip, sync_idx)
2. 신규 이벤트 처리
   2.1. x01_if_event_zenius → cmon_event_info INSERT
        - DISTINCT ON (z_myip, z_myid)로 중복 제거
        - inventory_master 조인 (IP 매핑)
   2.2. cmon_event_resp_manage_info INSERT (대응관리)
3. 해소 이벤트 처리
   - 인터페이스 테이블에 미존재 시 해소 처리
4. sync_idx 업데이트
```

### 2.4 문제점

| 구분 | 문제 | 영향 |
|------|------|------|
| 순차 처리 | 6개 시스템 순차 실행 | 총 처리시간 = 각 시스템 시간의 합 |
| 프로시저 의존 | 로직이 DB에 있음 | 테스트 불가, 디버깅 어려움 |
| 임시 테이블 누적 | 정리 로직 없음 | 조회 성능 저하 |
| 인덱스 누락 | x01_if_event_zenius 인덱스 없음 | 풀스캔 발생 |

---

## 3. 목표 구조 설계 (TO-BE)

### 3.1 전체 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           Scheduler Layer                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│  EventSyncServiceJob              CombineEventServiceJob                    │
│  (매분 :00 실행)                   (매분 :20 실행)                            │
└──────────┬────────────────────────────────┬─────────────────────────────────┘
           │                                │
           ▼                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          Orchestrator Layer                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│  EventSyncOrchestrator            EventCombineOrchestrator                  │
│  - 병렬 실행 관리                   - 병렬 실행 관리                           │
│  - CompletableFuture              - CompletableFuture                       │
└──────────┬────────────────────────────────┬─────────────────────────────────┘
           │                                │
           ▼                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Service Layer                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────┐          ┌─────────────────────┐                   │
│  │ IEventSyncService   │          │ IEventCombineService │                  │
│  └─────────────────────┘          └─────────────────────┘                   │
│           △                                △                                 │
│     ┌─────┴─────┐                    ┌─────┴─────┐                          │
│     │           │                    │           │                          │
│  ┌──┴───┐   ┌───┴──┐              ┌──┴───┐   ┌───┴──┐                       │
│  │Zabbix│   │Zenius│              │Zabbix│   │Zenius│                       │
│  │Sync  │   │Sync  │              │Combine│  │Combine│                      │
│  │Service│  │Service│             │Service│  │Service│                      │
│  └──────┘   └──────┘              └───────┘  └───────┘                      │
└─────────────────────────────────────────────────────────────────────────────┘
           │                                │
           ▼                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            Mapper Layer                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  EventSyncMapper                  EventCombineMapper                        │
│  - 외부 DB 조회                    - 신규 이벤트 조회/입력                     │
│  - 임시 테이블 입력                 - 해소 이벤트 처리                         │
│                                   - 대응관리 정보 입력                        │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2 패키지 구조

```
com.ktc.luppiter.batch
├── task/
│   ├── common/
│   │   ├── EventSyncServiceJob.java          # 연동 Job (기존 수정)
│   │   └── CombineEventServiceJob.java       # 취합 Job (기존 수정)
│   └── builder/                              # 기존 Worker (Deprecated 예정)
│
├── service/
│   ├── sync/                                 # [신규] 이벤트 연동
│   │   ├── IEventSyncService.java
│   │   ├── ZabbixEventSyncService.java
│   │   ├── ZeniusEventSyncService.java
│   │   └── EventSyncOrchestrator.java
│   │
│   └── combine/                              # [신규] 이벤트 취합
│       ├── IEventCombineService.java
│       ├── ZabbixEventCombineService.java
│       ├── ZeniusEventCombineService.java
│       └── EventCombineOrchestrator.java
│
├── dto/                                      # [신규] 데이터 객체
│   ├── SyncResult.java
│   ├── CombineResult.java
│   ├── BatchEventConfig.java
│   ├── IfEventData.java                      # Zabbix 임시 이벤트
│   ├── IfEventZenius.java                    # Zenius 임시 이벤트
│   └── EventInfo.java                        # 메인 이벤트
│
└── mapper/
    ├── EventSyncMapper.java                  # [신규]
    └── EventCombineMapper.java               # [신규]
```

---

## 4. 상세 설계

### 4.1 공통 DTO

#### BatchEventConfig.java
```java
@Data
@Builder
public class BatchEventConfig {
    private String systemCode;      // ES0001, ES0002, ...
    private String eventSyncType;   // EST010(Zabbix v5), EST011(Zabbix v7), EST020(Zenius)
    private String systemIp;        // 시스템 IP
    private String syncIdx;         // 마지막 연동 인덱스
    private LocalDateTime syncDt;   // 마지막 연동 시간
    private LocalDateTime ifDt;     // 마지막 IF 시간
    private String useYn;           // 사용 여부

    // DB 연결 정보
    private String dbDriver;
    private String dbUrl;
    private String dbUsername;
    private String dbPassword;
}
```

#### SyncResult.java
```java
@Data
@Builder
public class SyncResult {
    private String systemCode;
    private int fetchedCount;       // 조회된 이벤트 수
    private int insertedCount;      // 입력된 이벤트 수
    private String lastSyncIdx;     // 마지막 연동 인덱스
    private long elapsedTimeMs;
    private boolean success;
    private String errorMessage;
}
```

#### CombineResult.java
```java
@Data
@Builder
public class CombineResult {
    private String systemCode;
    private int newEventCount;      // 신규 이벤트 수
    private int resolvedEventCount; // 해소 이벤트 수
    private int respInfoCount;      // 대응관리 정보 수
    private long elapsedTimeMs;
    private boolean success;
    private String errorMessage;
}
```

### 4.2 이벤트 연동 서비스 (Sync)

#### IEventSyncService.java
```java
public interface IEventSyncService {

    /**
     * 외부 시스템에서 이벤트를 조회하여 임시 테이블에 저장
     * @param config 배치 설정 정보
     * @return 연동 결과
     */
    SyncResult sync(BatchEventConfig config);

    /**
     * 지원하는 이벤트 타입 코드 반환
     */
    String getSupportedEventType();
}
```

#### ZabbixEventSyncService.java
```java
@Service
@RequiredArgsConstructor
@Slf4j
public class ZabbixEventSyncService implements IEventSyncService {

    private final EventSyncMapper eventSyncMapper;
    private final BatchSchedulerMapper batchSchedulerMapper;

    @Override
    public String getSupportedEventType() {
        return "EST010,EST011";  // Zabbix v5, v7
    }

    @Override
    @Transactional
    public SyncResult sync(BatchEventConfig config) {
        long startTime = System.currentTimeMillis();

        try {
            // 1. 마지막 sync_idx 조회
            long lastSyncIdx = Long.parseLong(
                Optional.ofNullable(config.getSyncIdx()).orElse("0")
            );

            // 2. Zabbix DB에서 이벤트 조회
            List<IfEventData> events = fetchEventsFromZabbix(config, lastSyncIdx);

            if (events.isEmpty()) {
                return buildSuccessResult(config.getSystemCode(), 0, 0,
                    String.valueOf(lastSyncIdx), startTime);
            }

            // 3. 임시 테이블에 배치 INSERT
            int insertedCount = batchInsertToTempTable(events);

            // 4. sync_idx 업데이트
            String newSyncIdx = String.valueOf(
                events.stream().mapToLong(IfEventData::getEventId).max().orElse(lastSyncIdx)
            );
            updateSyncIdx(config.getSystemCode(), newSyncIdx);

            return buildSuccessResult(config.getSystemCode(), events.size(),
                insertedCount, newSyncIdx, startTime);

        } catch (Exception e) {
            log.error("[{}] Sync failed: {}", config.getSystemCode(), e.getMessage(), e);
            return buildFailureResult(config.getSystemCode(), e.getMessage(), startTime);
        }
    }

    private List<IfEventData> fetchEventsFromZabbix(BatchEventConfig config, long lastSyncIdx) {
        // Zabbix DB 연결 및 조회
        String query = config.getEventSyncType().equals("EST011")
            ? IFEventMapper.zabbixEventForV7
            : IFEventMapper.zabbixEventForV5;

        // 외부 DB 조회 로직
        return eventSyncMapper.fetchZabbixEvents(config, lastSyncIdx, query);
    }

    private int batchInsertToTempTable(List<IfEventData> events) {
        // 1000건씩 배치 INSERT
        int batchSize = 1000;
        int totalInserted = 0;

        for (int i = 0; i < events.size(); i += batchSize) {
            List<IfEventData> batch = events.subList(i,
                Math.min(i + batchSize, events.size()));
            eventSyncMapper.batchInsertIfEventData(batch);
            totalInserted += batch.size();
        }

        return totalInserted;
    }

    private void updateSyncIdx(String systemCode, String syncIdx) {
        batchSchedulerMapper.updateBatchEventInfo(Map.of(
            "systemCode", systemCode,
            "if_idx", syncIdx,
            "if_dt", "now()"
        ));
    }
}
```

#### ZeniusEventSyncService.java
```java
@Service
@RequiredArgsConstructor
@Slf4j
public class ZeniusEventSyncService implements IEventSyncService {

    private final EventSyncMapper eventSyncMapper;
    private final BatchSchedulerMapper batchSchedulerMapper;

    // Zenius 인프라 코드
    private static final int INFRA_SMS = 10;
    private static final int INFRA_NMS = 11;
    private static final int INFRA_SYSLOG = 19;

    @Override
    public String getSupportedEventType() {
        return "EST020";
    }

    @Override
    @Transactional
    public SyncResult sync(BatchEventConfig config) {
        long startTime = System.currentTimeMillis();

        try {
            // 1. 마지막 연동 시간 조회
            LocalDateTime lastIfDt = Optional.ofNullable(config.getIfDt())
                .orElse(LocalDateTime.now().minusMinutes(5));

            // 2. Zenius DB에서 이벤트 조회
            List<IfEventZenius> events = fetchEventsFromZenius(config, lastIfDt);

            if (events.isEmpty()) {
                return buildSuccessResult(config.getSystemCode(), 0, 0, null, startTime);
            }

            // 3. 데이터 가공 (zenius_level, event_code 등)
            events.forEach(this::enrichEventData);

            // 4. 임시 테이블에 배치 INSERT
            int insertedCount = batchInsertToTempTable(events);

            // 5. sync_idx, if_dt 업데이트
            LocalDateTime maxEvtTime = events.stream()
                .map(IfEventZenius::getZEvttime)
                .max(LocalDateTime::compareTo)
                .orElse(lastIfDt);
            updateSyncInfo(config.getSystemCode(), maxEvtTime);

            return buildSuccessResult(config.getSystemCode(), events.size(),
                insertedCount, null, startTime);

        } catch (Exception e) {
            log.error("[{}] Sync failed: {}", config.getSystemCode(), e.getMessage(), e);
            return buildFailureResult(config.getSystemCode(), e.getMessage(), startTime);
        }
    }

    private void enrichEventData(IfEventZenius event) {
        int zAlert = event.getZAlert();

        // zenius_level, event_level
        event.setZeniusLevel(zAlert == 50 ? "긴급" : "치명");
        event.setEventLevel(zAlert == 50 ? 2 : 4);

        // infra_code
        int infraId = event.getZInfraid();
        if (infraId == INFRA_SMS) event.setInfraCode(1);
        else if (infraId == INFRA_NMS) event.setInfraCode(2);
        else if (infraId == INFRA_SYSLOG) event.setInfraCode(3);

        // set_name
        event.setSetName(convertSetName(event.getZSetid()));

        // event_code
        event.setEventCode(String.format("[NW99%d%d]",
            event.getInfraCode(), event.getEventLevel()));
    }

    private String convertSetName(int setId) {
        return switch (setId) {
            case 8 -> "Set1";
            case 9 -> "Set2";
            case 10 -> "Set3";
            case 11 -> "Set4";
            case 12 -> "Set5";
            case 13 -> "Set6";
            case 14 -> "Set8";
            case 15 -> "Set9";
            default -> String.valueOf(setId);
        };
    }
}
```

#### EventSyncOrchestrator.java
```java
@Service
@Slf4j
public class EventSyncOrchestrator {

    private final Map<String, IEventSyncService> serviceRegistry;
    private final ThreadPoolTaskExecutor executor;

    /**
     * 생성자: Spring이 모든 IEventSyncService 구현체를 주입
     * → 새 시스템 추가 시 이 클래스 수정 불필요 (OCP 준수)
     */
    public EventSyncOrchestrator(
            List<IEventSyncService> services,
            @Qualifier("eventSyncExecutor") ThreadPoolTaskExecutor executor) {

        this.executor = executor;

        // 각 Service의 getSupportedEventType()으로 자동 등록
        this.serviceRegistry = services.stream()
            .flatMap(service -> Arrays.stream(service.getSupportedEventType().split(","))
                .map(type -> Map.entry(type.trim(), service)))
            .collect(Collectors.toMap(
                Map.Entry::getKey,
                Map.Entry::getValue,
                (existing, replacement) -> existing  // 중복 시 기존 유지
            ));

        log.info("EventSyncOrchestrator initialized with {} services: {}",
            serviceRegistry.size(), serviceRegistry.keySet());
    }

    /**
     * 모든 시스템의 이벤트를 병렬로 연동
     */
    public List<SyncResult> syncAll(List<BatchEventConfig> configs) {
        log.info("Starting parallel sync for {} systems", configs.size());

        List<CompletableFuture<SyncResult>> futures = configs.stream()
            .filter(config -> "Y".equals(config.getUseYn()))
            .map(config -> CompletableFuture.supplyAsync(
                () -> doSync(config), executor))
            .toList();

        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();

        List<SyncResult> results = futures.stream()
            .map(CompletableFuture::join)
            .toList();

        logSummary(results);
        return results;
    }

    private SyncResult doSync(BatchEventConfig config) {
        IEventSyncService service = resolveService(config.getEventSyncType());
        return service.sync(config);
    }

    /**
     * Registry에서 Service 조회
     * → if-else 분기 없음, 새 시스템 추가 시 수정 불필요
     */
    private IEventSyncService resolveService(String eventSyncType) {
        IEventSyncService service = serviceRegistry.get(eventSyncType);
        if (service == null) {
            throw new IllegalArgumentException(
                "Unknown event sync type: " + eventSyncType +
                ". Available types: " + serviceRegistry.keySet());
        }
        return service;
    }

    private void logSummary(List<SyncResult> results) {
        int totalFetched = results.stream().mapToInt(SyncResult::getFetchedCount).sum();
        int totalInserted = results.stream().mapToInt(SyncResult::getInsertedCount).sum();
        long totalTime = results.stream().mapToLong(SyncResult::getElapsedTimeMs).max().orElse(0);

        log.info("Sync completed: fetched={}, inserted={}, elapsed={}ms",
            totalFetched, totalInserted, totalTime);
    }
}
```

### 4.3 이벤트 취합 서비스 (Combine)

#### IEventCombineService.java
```java
public interface IEventCombineService {

    /**
     * 임시 테이블의 이벤트를 메인 테이블로 취합
     * @param config 배치 설정 정보
     * @return 취합 결과
     */
    CombineResult combine(BatchEventConfig config);

    /**
     * 지원하는 이벤트 타입 코드 반환
     */
    String getSupportedEventType();
}
```

#### ZabbixEventCombineService.java
```java
@Service
@RequiredArgsConstructor
@Slf4j
public class ZabbixEventCombineService implements IEventCombineService {

    private final EventCombineMapper eventCombineMapper;
    private final InventoryMasterMapper inventoryMapper;
    private final EventInfoMapper eventInfoMapper;
    private final RespManageInfoMapper respManageInfoMapper;

    @Override
    public String getSupportedEventType() {
        return "EST010,EST011";
    }

    @Override
    @Transactional
    public CombineResult combine(BatchEventConfig config) {
        long startTime = System.currentTimeMillis();
        String systemCode = config.getSystemCode();

        try {
            log.debug("[{}] Starting combine process", systemCode);

            // 1. 신규 이벤트 처리
            int newCount = processNewEvents(config);

            // 2. 대응관리 정보 입력
            int respCount = insertRespManageInfo(config);

            // 3. 예외 이벤트 해소 처리
            int exceptionResolvedCount = processExceptionResolved(config);

            // 4. 일반 해소 처리
            int resolvedCount = processResolvedEvents(config);

            // 5. sync_idx 업데이트
            updateSyncIdx(config);

            log.debug("[{}] Combine completed: new={}, resolved={}",
                systemCode, newCount, resolvedCount + exceptionResolvedCount);

            return CombineResult.builder()
                .systemCode(systemCode)
                .newEventCount(newCount)
                .resolvedEventCount(resolvedCount + exceptionResolvedCount)
                .respInfoCount(respCount)
                .elapsedTimeMs(System.currentTimeMillis() - startTime)
                .success(true)
                .build();

        } catch (Exception e) {
            log.error("[{}] Combine failed: {}", systemCode, e.getMessage(), e);
            return CombineResult.builder()
                .systemCode(systemCode)
                .elapsedTimeMs(System.currentTimeMillis() - startTime)
                .success(false)
                .errorMessage(e.getMessage())
                .build();
        }
    }

    /**
     * 신규 이벤트 처리
     * - x01_if_event_data → cmon_event_info INSERT
     */
    private int processNewEvents(BatchEventConfig config) {
        // 1. 신규 이벤트 조회 (인벤토리 미존재 건 제외)
        List<IfEventData> newEvents = eventCombineMapper.findNewZabbixEvents(
            config.getSystemCode(),
            Long.parseLong(config.getSyncIdx())
        );

        if (newEvents.isEmpty()) {
            return 0;
        }

        // 2. EventInfo로 변환 및 입력
        List<EventInfo> eventInfoList = newEvents.stream()
            .map(ifEvent -> convertToEventInfo(ifEvent, config))
            .filter(Objects::nonNull)
            .toList();

        if (!eventInfoList.isEmpty()) {
            eventInfoMapper.batchInsert(eventInfoList);
        }

        return eventInfoList.size();
    }

    /**
     * 임시 이벤트 → EventInfo 변환
     */
    private EventInfo convertToEventInfo(IfEventData ifEvent, BatchEventConfig config) {
        // 인벤토리 매핑
        InventoryMaster inventory = inventoryMapper.findByZabbixIp(ifEvent.getEventIp());
        if (inventory == null) {
            log.warn("[{}] Inventory not found for IP: {}",
                config.getSystemCode(), ifEvent.getEventIp());
            return null;
        }

        // 예외 처리 체크
        boolean isException = eventCombineMapper.checkExceptionEvent(
            ifEvent.getEventIp(), ifEvent.getTriggerId());

        return EventInfo.builder()
            .eventId(generateEventId())
            .occuTime(ifEvent.getEventDt())
            .targetIp(ifEvent.getEventIp())
            .targetContents(ifEvent.getEventContents())
            .sendAgent(config.getSystemIp())
            .eventLevel(convertEventLevel(ifEvent.getEventLevel()))
            .equBarcode(inventory.getEqunr())
            .deviceIp(inventory.getMgmtIp())
            .ipmiIp(inventory.getIpmiIp())
            .hostname(inventory.getHostNm())
            .equipLabel(inventory.getHostType())
            .containerNm(inventory.getCenterNm())
            .datacenterNm(inventory.getDatacenterNm())
            .rackLocation(inventory.getRackLocation())
            .equipPosition(inventory.getEquipPosition())
            .stdnm(inventory.getStdNm())
            .estdnm(inventory.getEStdNm())
            .eventState(isException ? "예외" : "신규")
            .zabbixState("지속")
            .triggerId(ifEvent.getTriggerId())
            .zbxAvailable(ifEvent.getStatusAgent())
            .ipmiAvailable(ifEvent.getStatusIpmi())
            .snmpAvailable(ifEvent.getStatusSnmp())
            .jmxAvailable(ifEvent.getStatusJmx())
            .l1Nm(inventory.getL1LayerNm())
            .l2Nm(inventory.getL2LayerNm())
            .l3Nm(inventory.getL3LayerNm())
            .zone(inventory.getZone())
            .gubun(inventory.getControlArea())
            .hostGroupNm(inventory.getHostGroupNm())
            .ifEventId(ifEvent.getEventId())
            .createTime(LocalDateTime.now())
            .lastOccuTime(LocalDateTime.now())
            .build();
    }

    /**
     * 대응관리 정보 입력
     */
    private int insertRespManageInfo(BatchEventConfig config) {
        return respManageInfoMapper.insertFromNewEvents(config.getSystemIp());
    }

    /**
     * 예외 이벤트 해소 처리
     */
    private int processExceptionResolved(BatchEventConfig config) {
        return eventCombineMapper.updateExceptionResolvedEvents(
            config.getSystemCode(),
            Long.parseLong(config.getSyncIdx())
        );
    }

    /**
     * 일반 해소 처리 (recovery_dst_id 매칭)
     */
    private int processResolvedEvents(BatchEventConfig config) {
        return eventCombineMapper.updateResolvedEvents(
            config.getSystemCode(),
            Long.parseLong(config.getSyncIdx())
        );
    }

    /**
     * sync_idx 업데이트
     */
    private void updateSyncIdx(BatchEventConfig config) {
        Long maxIfEventId = eventCombineMapper.findMaxIfEventId(config.getSystemIp());
        if (maxIfEventId != null) {
            eventCombineMapper.updateSyncIdx(config.getSystemCode(), maxIfEventId);
        }
    }

    private String generateEventId() {
        // get_next_event_sequence() 함수 호출
        return eventCombineMapper.getNextEventSequence();
    }

    private String convertEventLevel(int level) {
        return switch (level) {
            case 2 -> "Critical";
            case 4 -> "Fatal";
            default -> String.valueOf(level);
        };
    }
}
```

#### ZeniusEventCombineService.java
```java
@Service
@RequiredArgsConstructor
@Slf4j
public class ZeniusEventCombineService implements IEventCombineService {

    private final EventCombineMapper eventCombineMapper;
    private final InventoryMasterMapper inventoryMapper;
    private final EventInfoMapper eventInfoMapper;
    private final RespManageInfoMapper respManageInfoMapper;

    @Override
    public String getSupportedEventType() {
        return "EST020";
    }

    @Override
    @Transactional
    public CombineResult combine(BatchEventConfig config) {
        long startTime = System.currentTimeMillis();
        String systemCode = config.getSystemCode();

        try {
            log.debug("[{}] Starting combine process", systemCode);

            // 1. 신규 이벤트 처리
            int newCount = processNewEvents(config);

            // 2. 대응관리 정보 입력
            int respCount = insertRespManageInfo(config);

            // 3. 해소 처리 (인터페이스 미존재 시)
            int resolvedCount = processResolvedEvents(config);

            // 4. sync_idx 업데이트
            updateSyncIdx(config);

            log.debug("[{}] Combine completed: new={}, resolved={}",
                systemCode, newCount, resolvedCount);

            return CombineResult.builder()
                .systemCode(systemCode)
                .newEventCount(newCount)
                .resolvedEventCount(resolvedCount)
                .respInfoCount(respCount)
                .elapsedTimeMs(System.currentTimeMillis() - startTime)
                .success(true)
                .build();

        } catch (Exception e) {
            log.error("[{}] Combine failed: {}", systemCode, e.getMessage(), e);
            return CombineResult.builder()
                .systemCode(systemCode)
                .elapsedTimeMs(System.currentTimeMillis() - startTime)
                .success(false)
                .errorMessage(e.getMessage())
                .build();
        }
    }

    /**
     * 신규 이벤트 처리
     * - DISTINCT ON (z_myip, z_myid)로 중복 제거
     * - x01_if_event_zenius → cmon_event_info INSERT
     */
    private int processNewEvents(BatchEventConfig config) {
        // 1. 신규 이벤트 조회
        List<IfEventZenius> newEvents = eventCombineMapper.findNewZeniusEvents(
            config.getSystemCode(),
            config.getSyncIdx()
        );

        if (newEvents.isEmpty()) {
            return 0;
        }

        // 2. EventInfo로 변환 및 입력
        List<EventInfo> eventInfoList = newEvents.stream()
            .map(ifEvent -> convertToEventInfo(ifEvent, config))
            .filter(Objects::nonNull)
            .toList();

        if (!eventInfoList.isEmpty()) {
            eventInfoMapper.batchInsert(eventInfoList);
        }

        return eventInfoList.size();
    }

    /**
     * 해소 처리 (인터페이스 테이블에 미존재 시)
     */
    private int processResolvedEvents(BatchEventConfig config) {
        return eventCombineMapper.updateZeniusResolvedEvents(
            config.getSystemCode(),
            config.getSyncIdx(),
            config.getSystemIp()
        );
    }
}
```

#### EventCombineOrchestrator.java
```java
@Service
@Slf4j
public class EventCombineOrchestrator {

    private final Map<String, IEventCombineService> serviceRegistry;
    private final ThreadPoolTaskExecutor executor;

    /**
     * 생성자: Spring이 모든 IEventCombineService 구현체를 주입
     * → 새 시스템 추가 시 이 클래스 수정 불필요 (OCP 준수)
     */
    public EventCombineOrchestrator(
            List<IEventCombineService> services,
            @Qualifier("eventCombineExecutor") ThreadPoolTaskExecutor executor) {

        this.executor = executor;

        // 각 Service의 getSupportedEventType()으로 자동 등록
        this.serviceRegistry = services.stream()
            .flatMap(service -> Arrays.stream(service.getSupportedEventType().split(","))
                .map(type -> Map.entry(type.trim(), service)))
            .collect(Collectors.toMap(
                Map.Entry::getKey,
                Map.Entry::getValue,
                (existing, replacement) -> existing
            ));

        log.info("EventCombineOrchestrator initialized with {} services: {}",
            serviceRegistry.size(), serviceRegistry.keySet());
    }

    /**
     * 모든 시스템의 이벤트를 병렬로 취합
     */
    public List<CombineResult> combineAll(List<BatchEventConfig> configs) {
        log.info("Starting parallel combine for {} systems", configs.size());
        long startTime = System.currentTimeMillis();

        List<CompletableFuture<CombineResult>> futures = configs.stream()
            .filter(config -> "Y".equals(config.getUseYn()))
            .map(config -> CompletableFuture.supplyAsync(
                () -> doCombine(config), executor))
            .toList();

        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();

        List<CombineResult> results = futures.stream()
            .map(CompletableFuture::join)
            .toList();

        logSummary(results, startTime);
        return results;
    }

    private CombineResult doCombine(BatchEventConfig config) {
        IEventCombineService service = resolveService(config.getEventSyncType());
        return service.combine(config);
    }

    /**
     * Registry에서 Service 조회
     * → if-else 분기 없음, 새 시스템 추가 시 수정 불필요
     */
    private IEventCombineService resolveService(String eventSyncType) {
        IEventCombineService service = serviceRegistry.get(eventSyncType);
        if (service == null) {
            throw new IllegalArgumentException(
                "Unknown event combine type: " + eventSyncType +
                ". Available types: " + serviceRegistry.keySet());
        }
        return service;
    }

    private void logSummary(List<CombineResult> results, long startTime) {
        int totalNew = results.stream().mapToInt(CombineResult::getNewEventCount).sum();
        int totalResolved = results.stream().mapToInt(CombineResult::getResolvedEventCount).sum();
        long elapsed = System.currentTimeMillis() - startTime;

        log.info("Combine completed: new={}, resolved={}, elapsed={}ms",
            totalNew, totalResolved, elapsed);
    }
}
```

### 4.4 ThreadPool 설정

```java
@Configuration
public class AsyncConfig {

    @Bean("eventSyncExecutor")
    public ThreadPoolTaskExecutor eventSyncExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(6);        // 6개 시스템 동시 처리
        executor.setMaxPoolSize(10);
        executor.setQueueCapacity(25);
        executor.setThreadNamePrefix("event-sync-");
        executor.initialize();
        return executor;
    }

    @Bean("eventCombineExecutor")
    public ThreadPoolTaskExecutor eventCombineExecutor() {
        ThreadPoolTaskExecutor executor = new ThreadPoolTaskExecutor();
        executor.setCorePoolSize(6);        // 6개 시스템 동시 처리
        executor.setMaxPoolSize(10);
        executor.setQueueCapacity(25);
        executor.setThreadNamePrefix("event-combine-");
        executor.initialize();
        return executor;
    }
}
```

---

## 5. Mapper SQL 설계

### 5.1 EventCombineMapper.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN"
    "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.ktc.luppiter.batch.mapper.EventCombineMapper">

    <!-- 신규 Zabbix 이벤트 조회 -->
    <select id="findNewZabbixEvents" resultType="IfEventData">
        SELECT
            xied.system_code,
            xied.event_id,
            xied.event_dt,
            xied.event_level,
            xied.event_contents,
            xied.event_status,
            xied.recovery_dst_id,
            xied.event_ip,
            xied.trigger_id,
            xied.status_agent,
            xied.status_ipmi,
            xied.status_snmp,
            xied.status_jmx,
            xied.maintenance_status
        FROM x01_if_event_data xied
        INNER JOIN inventory_master inv_mst
            ON inv_mst.zabbix_ip = xied.event_ip
        WHERE xied.system_code = #{systemCode}
          AND xied.event_id > #{syncIdx}
          AND xied.event_status = 1
          AND xied.event_level IN (2, 4)
          AND xied.maintenance_status = 0
          AND NOT EXISTS (
              SELECT 1 FROM cmon_event_info evt
              WHERE evt.send_agent = #{systemIp}
                AND evt.if_event_id = xied.event_id
          )
        ORDER BY xied.event_id
    </select>

    <!-- 예외 이벤트 체크 -->
    <select id="checkExceptionEvent" resultType="boolean">
        SELECT EXISTS (
            SELECT 1
            FROM cmon_exception_event ex
            INNER JOIN cmon_exception_event_detail exd
                ON ex.excp_seq = exd.excp_seq
            WHERE exd.ip = #{eventIp}
              AND exd.trigger_id = #{triggerId}
              AND exd.delete_yn = 'N'
              AND NOW() BETWEEN ex.start_dtm AND ex.end_dtm
        )
    </select>

    <!-- 예외 이벤트 해소 처리 -->
    <update id="updateExceptionResolvedEvents">
        UPDATE cmon_event_info ei
        SET zabbix_state = '해소',
            event_state = COALESCE(r_evt.ex_event_state, event_state),
            r_time = r_evt.event_dt,
            event_step1_user = COALESCE(event_step1_user, '유피테르'),
            event_step2_user = COALESCE(event_step2_user, '유피테르'),
            event_step1_start = COALESCE(event_step1_start, GREATEST(create_time, r_evt.excp_time)),
            event_step2_start = COALESCE(event_step2_start, GREATEST(create_time, r_evt.excp_time)),
            event_step1_end = COALESCE(event_step1_end, GREATEST(create_time, r_evt.excp_time)),
            event_step2_end = COALESCE(event_step2_end, GREATEST(create_time, r_evt.excp_time)),
            event_step1_contents = COALESCE(event_step1_contents, r_evt.ex_contents),
            event_step2_contents = COALESCE(event_step2_contents, r_evt.ex_contents),
            event_service_impact = COALESCE(event_service_impact, 'N'),
            event_tech_voc = COALESCE(event_tech_voc, 'N'),
            event_result_type = COALESCE(event_result_type, '9'),
            event_result_user = COALESCE(event_result_user, '유피테르'),
            event_result_time = COALESCE(event_result_time, GREATEST(create_time, r_evt.excp_time)),
            last_occu_time = NOW()
        FROM (
            SELECT cei.event_id,
                   xied.event_dt,
                   GREATEST(ex.start_dtm, ex.cret_dt) AS excp_time,
                   ex.evt_excp_contents AS ex_contents,
                   '예외' AS ex_event_state
            FROM cmon_event_info cei
            INNER JOIN x01_if_event_data xied
                ON cei.trigger_id = xied.trigger_id
               AND cei.if_event_id = xied.recovery_dst_id
               AND xied.system_code = #{systemCode}
               AND xied.event_id > #{syncIdx}
               AND xied.event_status = 0
            INNER JOIN cmon_exception_event ex
            INNER JOIN cmon_exception_event_detail exd
                ON ex.excp_seq = exd.excp_seq
               AND exd.trigger_id = cei.trigger_id
               AND exd.ip = cei.target_ip
               AND exd.delete_yn = 'N'
               AND NOW() BETWEEN ex.start_dtm AND ex.end_dtm
            WHERE cei.r_time IS NULL
        ) AS r_evt
        WHERE ei.event_id = r_evt.event_id
    </update>

    <!-- 일반 해소 처리 (Zabbix) -->
    <update id="updateResolvedEvents">
        UPDATE cmon_event_info evt
        SET zabbix_state = '해소',
            r_time = r_evt.event_dt,
            last_occu_time = NOW()
        FROM (
            SELECT cei.event_id,
                   xied.event_dt
            FROM cmon_event_info cei
            INNER JOIN x01_if_event_data xied
                ON cei.trigger_id = xied.trigger_id
               AND cei.if_event_id = xied.recovery_dst_id
               AND xied.system_code = #{systemCode}
               AND xied.event_status = 0
               AND xied.event_id > #{syncIdx}
            WHERE cei.r_time IS NULL
        ) AS r_evt
        WHERE evt.event_id = r_evt.event_id
    </update>

    <!-- Zenius 해소 처리 (인터페이스 미존재 시) -->
    <update id="updateZeniusResolvedEvents">
        UPDATE cmon_event_info evt
        SET zabbix_state = '해소',
            r_time = NOW(),
            last_occu_time = NOW()
        FROM (
            SELECT event_id
            FROM cmon_event_info evt
            LEFT JOIN x01_if_event_zenius xiez
                ON xiez.z_myip = evt.target_ip
               AND xiez.z_myid::numeric = evt.trigger_id
               AND xiez.system_code = #{systemCode}
               AND xiez.z_alert IN (50, 60)
               AND xiez.if_idx > #{syncIdx}
            WHERE evt.zabbix_state = '지속'
              AND evt.send_agent = #{systemIp}
              AND xiez.z_myid IS NULL
        ) AS r_evt
        WHERE evt.event_id = r_evt.event_id
    </update>

    <!-- 이벤트 시퀀스 생성 -->
    <select id="getNextEventSequence" resultType="string">
        SELECT get_next_event_sequence()
    </select>

    <!-- sync_idx 업데이트 -->
    <update id="updateSyncIdx">
        UPDATE c01_batch_event
        SET sync_idx = #{syncIdx},
            sync_dt = NOW()
        WHERE system_code = #{systemCode}
    </update>

</mapper>
```

---

## 6. 마이그레이션 계획

### 6.1 단계별 전환

| 단계 | 작업 | 기간 | 위험도 |
|------|------|------|--------|
| **Phase 1** | DTO, 인터페이스 정의 | 0.5일 | 낮음 |
| **Phase 2** | EventCombineMapper 구현 | 1일 | 낮음 |
| **Phase 3** | ZabbixEventCombineService 구현 | 3일 | 중간 |
| **Phase 4** | ZeniusEventCombineService 구현 | 2일 | 중간 |
| **Phase 5** | EventCombineOrchestrator 구현 | 1일 | 낮음 |
| **Phase 6** | EventSyncService 구현 (선택) | 2일 | 중간 |
| **Phase 7** | 단위 테스트 (80%+) | 2일 | 낮음 |
| **Phase 8** | STG 배포 및 검증 | 1주 | 중간 |
| **Phase 9** | PRD 배포 | 1일 | 높음 |

### 6.2 롤백 전략

```java
// application.yml
luppiter:
  combine:
    use-java-service: true   # false로 변경 시 기존 프로시저 사용
```

```java
// CombineEventServiceJob.java
if (useJavaService) {
    orchestrator.combineAll(configs);
} else {
    // 기존 프로시저 호출 (롤백 시)
    for (BatchEventConfig config : configs) {
        eventBatchMapper.combineEventForZabbix(config.getSystemCode());
    }
}
```

### 6.3 모니터링 항목

| 항목 | 임계치 | 알림 |
|------|--------|------|
| 취합 소요시간 | > 15초 | Warning |
| 취합 소요시간 | > 30초 | Critical |
| 신규 이벤트 0건 | 연속 10회 | Warning |
| 에러 발생 | 1회 | Critical |

---

## 7. 테스트 계획

### 7.1 단위 테스트

```java
@ExtendWith(MockitoExtension.class)
class ZabbixEventCombineServiceTest {

    @Mock
    private EventCombineMapper eventCombineMapper;

    @Mock
    private InventoryMasterMapper inventoryMapper;

    @InjectMocks
    private ZabbixEventCombineService service;

    @Test
    void combine_신규이벤트_정상처리() {
        // Given
        BatchEventConfig config = createTestConfig("ES0001");
        List<IfEventData> events = createTestEvents(10);
        when(eventCombineMapper.findNewZabbixEvents(any(), any())).thenReturn(events);

        // When
        CombineResult result = service.combine(config);

        // Then
        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getNewEventCount()).isEqualTo(10);
    }

    @Test
    void combine_해소이벤트_정상처리() {
        // Given
        BatchEventConfig config = createTestConfig("ES0001");
        when(eventCombineMapper.updateResolvedEvents(any(), any())).thenReturn(5);

        // When
        CombineResult result = service.combine(config);

        // Then
        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getResolvedEventCount()).isEqualTo(5);
    }
}
```

### 7.2 통합 테스트

```java
@SpringBootTest
@Transactional
class EventCombineOrchestratorIntegrationTest {

    @Autowired
    private EventCombineOrchestrator orchestrator;

    @Autowired
    private BatchSchedulerMapper batchSchedulerMapper;

    @Test
    void combineAll_병렬실행_성능테스트() {
        // Given
        List<BatchEventConfig> configs = batchSchedulerMapper.selectAllBatchEventConfigs();

        // When
        long startTime = System.currentTimeMillis();
        List<CombineResult> results = orchestrator.combineAll(configs);
        long elapsed = System.currentTimeMillis() - startTime;

        // Then
        assertThat(elapsed).isLessThan(15000);  // 15초 이내
        assertThat(results).allMatch(CombineResult::isSuccess);
    }
}
```

---

## 8. 체크리스트

### 구현 전 확인사항
- [ ] 기존 프로시저 로직 완전 분석
- [ ] 인벤토리 매핑 규칙 확인
- [ ] 예외 처리 규칙 확인
- [ ] 해소 처리 규칙 확인 (Zabbix vs Zenius 차이)

### 구현 완료 확인사항
- [ ] DTO 클래스 구현
- [ ] 인터페이스 정의
- [ ] ZabbixEventCombineService 구현
- [ ] ZeniusEventCombineService 구현
- [ ] EventCombineOrchestrator 구현
- [ ] Mapper XML 작성
- [ ] ThreadPool 설정
- [ ] 단위 테스트 (80%+)
- [ ] 통합 테스트
- [ ] 롤백 전략 구현

### 배포 전 확인사항
- [ ] STG 환경 1주 검증
- [ ] 성능 비교 (AS-IS vs TO-BE)
- [ ] 알림 누락 여부 확인
- [ ] 모니터링 대시보드 설정

---

## 9. 확장 예시: 새 시스템 추가 (Observability)

### 9.1 추가 절차

새로운 모니터링 시스템(예: Observability)을 추가할 때 필요한 작업:

| 단계 | 작업 | 파일 수정 |
|------|------|----------|
| 1 | Service 클래스 생성 | **신규 생성** |
| 2 | Mapper 메서드 추가 | **신규 추가** |
| 3 | DB 설정 추가 | **INSERT** |
| 4 | Orchestrator 수정 | ❌ **불필요** |

### 9.2 구현 예시

#### Step 1. Service 클래스 생성

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class ObservabilityEventCombineService implements IEventCombineService {

    private final EventCombineMapper eventCombineMapper;
    private final InventoryMasterMapper inventoryMapper;

    @Override
    public String getSupportedEventType() {
        return "EST030";  // 새 타입 코드
    }

    @Override
    @Transactional
    public CombineResult combine(BatchEventConfig config) {
        long startTime = System.currentTimeMillis();

        try {
            // 1. 신규 이벤트 처리
            int newCount = processNewEvents(config);

            // 2. 해소 이벤트 처리
            int resolvedCount = processResolvedEvents(config);

            // 3. sync_idx 업데이트
            updateSyncIdx(config);

            return CombineResult.builder()
                .systemCode(config.getSystemCode())
                .newEventCount(newCount)
                .resolvedEventCount(resolvedCount)
                .elapsedTimeMs(System.currentTimeMillis() - startTime)
                .success(true)
                .build();

        } catch (Exception e) {
            log.error("[{}] Combine failed: {}", config.getSystemCode(), e.getMessage(), e);
            return CombineResult.builder()
                .systemCode(config.getSystemCode())
                .success(false)
                .errorMessage(e.getMessage())
                .build();
        }
    }

    private int processNewEvents(BatchEventConfig config) {
        // Observability 특화 로직 구현
        // - target_name + region 기반 매핑
        // - cmon_service_inventory_master 조인
        return eventCombineMapper.findNewObservabilityEvents(config);
    }

    private int processResolvedEvents(BatchEventConfig config) {
        // Observability 해소 로직
        return eventCombineMapper.updateObservabilityResolvedEvents(config);
    }

    private void updateSyncIdx(BatchEventConfig config) {
        eventCombineMapper.updateSyncIdx(config.getSystemCode(), config.getSyncIdx());
    }
}
```

#### Step 2. DB 설정 추가

```sql
-- 시스템 설정 추가
INSERT INTO c01_batch_event (
    system_code,
    event_sync_type,
    system_ip,
    use_yn,
    sync_idx,
    create_dt
) VALUES (
    'ES0007',           -- 새 시스템 코드
    'EST030',           -- 새 이벤트 타입 (Observability)
    '10.0.0.100',       -- 시스템 IP
    'Y',
    '0',
    NOW()
);
```

#### Step 3. 끝! (Orchestrator 수정 불필요)

Spring 애플리케이션 재시작 시:
```
EventCombineOrchestrator initialized with 3 services: [EST010, EST011, EST020, EST030]
                                                                              ↑ 자동 등록
```

### 9.3 확장 포인트 요약

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        확장 시 수정 범위                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  [수정 필요]                           [수정 불필요]                          │
│  ┌─────────────────────────┐          ┌─────────────────────────┐          │
│  │ ObservabilityEvent      │          │ EventCombineOrchestrator │          │
│  │ CombineService.java     │          │ EventSyncOrchestrator   │          │
│  │ (신규 생성)              │          │ CombineEventServiceJob  │          │
│  └─────────────────────────┘          │ 기존 Service 클래스들     │          │
│                                        └─────────────────────────┘          │
│  ┌─────────────────────────┐                                                │
│  │ EventCombineMapper.xml  │                                                │
│  │ (메서드 추가)            │                                                │
│  └─────────────────────────┘                                                │
│                                                                             │
│  ┌─────────────────────────┐                                                │
│  │ c01_batch_event         │                                                │
│  │ (DB INSERT)             │                                                │
│  └─────────────────────────┘                                                │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 부록: 관련 파일

| 파일 | 경로 | 용도 |
|------|------|------|
| CombineEventServiceJob | `batch/task/common/CombineEventServiceJob.java` | 현재 취합 Job |
| ZabbixEventWorker | `batch/task/builder/ZabbixEventWorker.java` | 현재 연동 Worker |
| ZeniusEventWorker | `batch/task/builder/ZeniusEventWorker.java` | 현재 연동 Worker |
| p_combine_event_zabbix | `DDML/p_combine_event_zabbix_.sql` | Zabbix 취합 프로시저 |
| p_combine_event_zenius | `DDML/p_combine_event_zenius.sql` | Zenius 취합 프로시저 |
