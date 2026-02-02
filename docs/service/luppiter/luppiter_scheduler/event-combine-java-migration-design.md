# 이벤트 연동 아키텍처 개선 계획

> 작성일: 2026-01-30
> 상태: 설계 완료, 개발 대기

## 목표

- 프로시저 제거 → Java 로직 전환 (안정성 최우선)
- 병렬 처리로 성능 개선 (36s → 6~8s)
- 향후 확장성 확보 (새 시스템 추가 용이)

---

## Phase 구분

| Phase | 내용 | 우선순위 | 목표 | 변경 범위 |
|-------|------|---------|------|----------|
| **Phase 1** | 프로시저 → Java 전환 | 1순위 | 안정성 + 성능 | AP만 변경, DB 구조 유지 |
| **Phase 2** | API 연동 + 통합 테이블 | 2순위 | 확장성 | AP + DB 구조 변경 |

---

# Phase 1: 프로시저 → Java 전환

## 핵심 원칙

- **DB 구조 변경 없음** - 기존 테이블(x01_if_event_data, x01_if_event_zenius) 그대로 사용
- **프로시저와 동일한 동작** - 인벤토리 미매핑/형식 오류 건은 로깅 후 버림 (재처리 없음)
- **병행 운영** - 프로시저와 Java 로직 동시 실행 후 결과 비교 검증
- **점진적 전환** - 검증 완료 후 프로시저 호출 제거

---

## 설계 패턴: Template Method

공통 로직은 추상 클래스에, 차이점만 서브클래스에서 구현.

```
┌─────────────────────────────────────────────────────────────────┐
│              AbstractEventCombineService (추상 클래스)            │
├─────────────────────────────────────────────────────────────────┤
│ [공통 로직 - Template Method]                                    │
│  • combine()           - 전체 흐름 제어                          │
│  • processNewEvents()  - 신규 이벤트 처리 (변환+배치INSERT)         │
│  • insertRespManageInfo() - 대응관리 정보 입력                    │
│  • updateSyncIdx()     - sync_idx 업데이트                       │
│  • convertEvent()      - 이벤트 변환 (인벤토리 매핑 포함)           │
├─────────────────────────────────────────────────────────────────┤
│ [훅 메서드 - 서브클래스에서 구현/오버라이드]                         │
│  • findNewEvents()           - 신규 이벤트 조회 (추상)            │
│  • processResolvedEvents()   - 해소 처리 (추상)                  │
│  • getMaxSyncIdx()           - sync_idx 최대값 (추상)            │
│  • buildEventContents()      - 이벤트 내용 생성 (추상)            │
│  • checkException()          - 예외 체크 (기본: false)           │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┴───────────────┐
              ▼                               ▼
┌─────────────────────────┐     ┌─────────────────────────┐
│ ZabbixEventCombineService│     │ ZeniusEventCombineService│
├─────────────────────────┤     ├─────────────────────────┤
│ findNewEvents()         │     │ findNewEvents()         │
│  → event_id > sync_idx  │     │  → if_idx > sync_idx    │
│  → event_status = 1     │     │  → z_alert IN (50,60)   │
├─────────────────────────┤     ├─────────────────────────┤
│ checkException()        │     │ (기본 사용: false)        │
│  → cmon_exception_event │     │                         │
├─────────────────────────┤     ├─────────────────────────┤
│ processResolvedEvents() │     │ processResolvedEvents() │
│  → recovery_dst_id 매칭  │     │  → IF 테이블 미존재 시    │
├─────────────────────────┤     ├─────────────────────────┤
│ buildEventContents()    │     │ buildEventContents()    │
│  → event_contents 그대로 │     │  → 조합 형식             │
└─────────────────────────┘     └─────────────────────────┘
```

---

## 공통점 vs 차이점

### 공통 로직 (추상 클래스)

| 단계 | 로직 | 메서드 |
|------|------|--------|
| 1 | 시스템 설정 조회 | `getBatchEventConfig()` |
| 2 | 인벤토리 매핑 | `mapInventory()` (INNER JOIN 대응) |
| 3 | 계위 정보 조회 | `getLayerInfo()` |
| 4 | INSERT cmon_event_info | `batchInsertEventInfo()` |
| 5 | INSERT 대응관리 정보 | `insertRespManageInfo()` |
| 6 | sync_idx 업데이트 | `updateSyncIdx()` |

### 차이점 (훅 메서드)

| 항목 | Zabbix | Zenius |
|------|--------|--------|
| 신규 이벤트 조회 | `event_id > sync_idx`, `event_status=1` | `if_idx > sync_idx`, `z_alert IN (50,60)` |
| 예외 처리 체크 | `cmon_exception_event` 체크 | 없음 (기본 false) |
| 해소 처리 | `recovery_dst_id` 매칭 | IF 테이블에 미존재 시 |
| 이벤트 내용 | `event_contents` 그대로 | `event_code + level + set_name + ...` 조합 |
| sync_idx 값 | `max(if_event_id)` | `max(if_idx)` |

---

## 실패 건 처리 (프로시저와 동일)

**원칙**: 인벤토리 미매핑, 형식 오류 건은 **로깅 후 버림** (재처리 없음)

```
100건 조회
    ↓
변환 처리
    ├─ 95건 성공 → validEvents 리스트에 추가
    └─ 5건 실패 → log.debug() 후 continue (프로시저 INNER JOIN과 동일)
    ↓
배치 INSERT 95건
    ↓
sync_idx = max(100번째 event_id)  ← 실패 건 무관하게 정상 진행
    ↓
완료 (newEventCount: 95)
```

**프로시저 동작과 비교**:

| 케이스 | 프로시저 (현재) | Java (전환) |
|--------|---------------|-------------|
| 인벤토리 미등록 | INNER JOIN 실패 → 자동 제외 | `inventory == null` → continue |
| 데이터 형식 오류 | INSERT 실패 → 자동 제외 | try-catch → continue |
| 정상 건 | INSERT 성공 | INSERT 성공 |

**재처리 Job 없음** - 프로시저와 동일한 동작 유지

---

## Java 클래스 설계

### AbstractEventCombineService (Template)

```java
@Slf4j
public abstract class AbstractEventCombineService implements IEventCombineService {

    @Autowired
    protected EventCombineMapper mapper;
    
    @Autowired
    protected InventoryMasterMapper inventoryMapper;
    
    /**
     * Template Method - 전체 취합 흐름
     */
    @Override
    @Transactional
    public CombineResult combine(String systemCode) {
        long startTime = System.currentTimeMillis();
        
        try {
            // 1. 시스템 설정 조회
            BatchEventConfig config = mapper.getBatchEventConfig(systemCode);
            validateConfig(config);
            
            // 2. 신규 이벤트 처리
            int newCount = processNewEvents(config);
            
            // 3. 해소 이벤트 처리 (훅 메서드)
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
            log.error("[{}] combine failed", getSourceType(), e);
            return CombineResult.builder()
                .systemCode(systemCode)
                .success(false)
                .errorMessage(e.getMessage())
                .elapsedTimeMs(System.currentTimeMillis() - startTime)
                .build();
        }
    }
    
    /**
     * 신규 이벤트 처리 (공통 로직)
     */
    private int processNewEvents(BatchEventConfig config) {
        // 훅 메서드: 신규 이벤트 조회
        List<RawEvent> rawEvents = findNewEvents(config);
        
        if (rawEvents.isEmpty()) {
            return 0;
        }
        
        log.info("[{}] Found {} new events", getSourceType(), rawEvents.size());
        
        // 이벤트 변환 (실패 건은 스킵)
        List<EventInfo> validEvents = new ArrayList<>();
        
        for (RawEvent raw : rawEvents) {
            // 인벤토리 매핑 (프로시저의 INNER JOIN과 동일)
            InventoryMaster inventory = inventoryMapper.findByZabbixIp(raw.getEventIp());
            if (inventory == null) {
                log.debug("Skip - inventory not found: ip={}", raw.getEventIp());
                continue;  // 프로시저와 동일하게 버림
            }
            
            try {
                EventInfo eventInfo = convertEvent(raw, config, inventory);
                validEvents.add(eventInfo);
            } catch (Exception e) {
                log.debug("Skip - convert failed: id={}, reason={}", 
                    raw.getEventId(), e.getMessage());
                continue;  // 프로시저와 동일하게 버림
            }
        }
        
        // 배치 INSERT (전체 한 번에)
        if (!validEvents.isEmpty()) {
            mapper.batchInsertEventInfo(validEvents);
            
            // 대응관리 정보 입력
            List<String> eventIds = validEvents.stream()
                .map(EventInfo::getEventId)
                .toList();
            mapper.insertRespManageInfo(eventIds);
        }
        
        return validEvents.size();
    }
    
    /**
     * 이벤트 변환 (공통 + 훅 조합)
     */
    private EventInfo convertEvent(RawEvent raw, BatchEventConfig config, InventoryMaster inventory) {
        // 훅 메서드: 예외 처리 체크 (Zabbix만 오버라이드)
        boolean isException = checkException(raw);
        
        // 계위 정보 조회
        LayerInfo layerInfo = mapper.getLayerInfo(inventory);
        
        // EventInfo 생성
        return EventInfo.builder()
            .eventId(mapper.getNextEventSequence())
            .occuTime(raw.getEventDt())
            .targetIp(raw.getEventIp())
            .targetContents(buildEventContents(raw))  // 훅 메서드
            .sendAgent(config.getSystemIp())
            .eventLevel(convertEventLevel(raw.getEventLevel()))
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
            .triggerId(raw.getTriggerId())
            .l1Nm(layerInfo.getL1Nm())
            .l2Nm(layerInfo.getL2Nm())
            .l3Nm(layerInfo.getL3Nm())
            .zone(inventory.getZone())
            .gubun(getControlArea(raw, inventory))
            .hostGroupNm(getHostGroupNm(raw, inventory))
            .ifEventId(raw.getEventId())
            .createTime(LocalDateTime.now())
            .lastOccuTime(LocalDateTime.now())
            .build();
    }
    
    private void updateSyncIdx(BatchEventConfig config) {
        Object maxSyncIdx = getMaxSyncIdx(config);  // 훅 메서드
        mapper.updateSyncIdx(config.getSystemCode(), maxSyncIdx);
    }
    
    // ========== 훅 메서드 (서브클래스에서 구현/오버라이드) ==========
    
    /** 신규 이벤트 조회 */
    protected abstract List<RawEvent> findNewEvents(BatchEventConfig config);
    
    /** 해소 이벤트 처리 */
    protected abstract int processResolvedEvents(BatchEventConfig config);
    
    /** sync_idx 최대값 조회 */
    protected abstract Object getMaxSyncIdx(BatchEventConfig config);
    
    /** 이벤트 내용 생성 */
    protected abstract String buildEventContents(RawEvent raw);
    
    /** 예외 처리 체크 (기본: false, Zabbix만 오버라이드) */
    protected boolean checkException(RawEvent raw) {
        return false;
    }
    
    /** control_area 조회 */
    protected String getControlArea(RawEvent raw, InventoryMaster inventory) {
        String subControlArea = mapper.getSubControlArea(raw.getEventIp(), raw.getEventContents());
        return subControlArea != null ? subControlArea : inventory.getControlArea();
    }
    
    /** host_group_nm 조회 */
    protected String getHostGroupNm(RawEvent raw, InventoryMaster inventory) {
        String subHostGroupNm = mapper.getSubHostGroupNm(raw.getEventIp(), raw.getEventContents());
        return subHostGroupNm != null ? subHostGroupNm : inventory.getHostGroupNm();
    }
}
```

### ZabbixEventCombineService

```java
@Service
@Slf4j
public class ZabbixEventCombineService extends AbstractEventCombineService {

    @Override
    public String getSourceType() {
        return "ZABBIX";
    }
    
    @Override
    public String getSupportedEventType() {
        return "EST010,EST011";
    }
    
    @Override
    protected List<RawEvent> findNewEvents(BatchEventConfig config) {
        // Zabbix: event_id > sync_idx, event_status=1, event_level IN (2,4)
        return mapper.findNewZabbixEvents(
            config.getSystemCode(),
            config.getSyncIdxAsLong(),
            config.getSystemIp()
        );
    }
    
    @Override
    protected boolean checkException(RawEvent raw) {
        // Zabbix만 예외 처리 체크
        return mapper.checkExceptionEvent(raw.getEventIp(), raw.getTriggerId());
    }
    
    @Override
    protected int processResolvedEvents(BatchEventConfig config) {
        // Zabbix: recovery_dst_id 매칭으로 해소
        int exceptionResolved = mapper.resolveZabbixExceptionEvents(
            config.getSystemCode(),
            config.getSyncIdxAsLong(),
            config.getSystemIp()
        );
        
        int normalResolved = mapper.resolveZabbixNormalEvents(
            config.getSystemCode(),
            config.getSyncIdxAsLong()
        );
        
        return exceptionResolved + normalResolved;
    }
    
    @Override
    protected Object getMaxSyncIdx(BatchEventConfig config) {
        return mapper.getMaxZabbixEventId(config.getSystemIp());
    }
    
    @Override
    protected String buildEventContents(RawEvent raw) {
        return raw.getEventContents();
    }
}
```

### ZeniusEventCombineService

```java
@Service
@Slf4j
public class ZeniusEventCombineService extends AbstractEventCombineService {

    @Override
    public String getSourceType() {
        return "ZENIUS";
    }
    
    @Override
    public String getSupportedEventType() {
        return "EST020";
    }
    
    @Override
    protected List<RawEvent> findNewEvents(BatchEventConfig config) {
        // Zenius: if_idx > sync_idx, z_alert IN (50,60)
        return mapper.findNewZeniusEvents(
            config.getSystemCode(),
            config.getSyncIdx(),
            config.getSystemIp()
        );
    }
    
    // checkException() - 기본 구현(false) 사용
    
    @Override
    protected int processResolvedEvents(BatchEventConfig config) {
        // Zenius: IF 테이블에 미존재 시 해소
        return mapper.resolveZeniusEvents(
            config.getSystemCode(),
            config.getSyncIdx(),
            config.getSystemIp()
        );
    }
    
    @Override
    protected Object getMaxSyncIdx(BatchEventConfig config) {
        return mapper.getMaxZeniusIfIdx();
    }
    
    @Override
    protected String buildEventContents(RawEvent raw) {
        // Zenius: 조합 형식
        // event_code + ' ' + zenius_level + '/' + set_name + '/' + z_myname + '/' + z_mymsg
        ZeniusRawEvent zenius = (ZeniusRawEvent) raw;
        return String.format("%s %s/%s/%s/%s",
            zenius.getEventCode(),
            zenius.getZeniusLevel(),
            zenius.getSetName(),
            zenius.getZMyname(),
            zenius.getZMymsg()
        );
    }
}
```

### EventCombineOrchestrator (병렬 처리)

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class EventCombineOrchestrator {

    private final List<IEventCombineService> combineServices;
    
    @Value("${event.combine.thread-pool-size:6}")
    private int threadPoolSize;
    
    private ExecutorService executor;
    
    @PostConstruct
    public void init() {
        executor = Executors.newFixedThreadPool(threadPoolSize);
    }
    
    @PreDestroy
    public void destroy() {
        executor.shutdown();
    }
    
    /**
     * 모든 시스템 병렬 취합
     */
    public List<CombineResult> combineAll(List<BatchEventConfig> configs) {
        log.info("Start combineAll: {} systems", configs.size());
        long startTime = System.currentTimeMillis();
        
        List<CompletableFuture<CombineResult>> futures = configs.stream()
            .map(config -> CompletableFuture.supplyAsync(() -> {
                IEventCombineService service = findService(config.getEventSyncType());
                return service.combine(config.getSystemCode());
            }, executor))
            .toList();
        
        // 모든 작업 완료 대기
        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();
        
        // 결과 수집
        List<CombineResult> results = futures.stream()
            .map(CompletableFuture::join)
            .toList();
        
        log.info("Completed combineAll: {}ms, results={}", 
            System.currentTimeMillis() - startTime, results);
        
        return results;
    }
    
    private IEventCombineService findService(String eventSyncType) {
        return combineServices.stream()
            .filter(s -> s.getSupportedEventType().contains(eventSyncType))
            .findFirst()
            .orElseThrow(() -> new IllegalArgumentException("Unknown type: " + eventSyncType));
    }
}
```

---

## 상세 설계 의사결정

### 확정 사항

| 항목 | 결정 |
|------|------|
| **트랜잭션 범위** | combine() 전체를 1트랜잭션 (프로시저와 동일) |
| **스레드 풀** | 고정 6개 |
| **Shadow Mode 비교 범위** | 건수 + 핵심 필드 (event_state, zabbix_state, r_time) |
| **Shadow Mode 비교 시점** | 프로시저 먼저 실행, Java는 Dry Run (실제 INSERT 안 함) |
| **롤백 트리거** | 수동 판단 (로그 확인 후 설정 변경) |
| **실패건 로깅** | 기존 시스템은 DEBUG 로깅만, O11Y 연동 시 Slack 전송 |
| **성능 로깅** | 시스템별 처리 시간 (`[CombineJob]` 스타일) |
| **필드 매핑 검증** | 단위 테스트 + 체크리스트 |

---

## 안정성 확보 전략

### 1. 병행 운영 (Shadow Mode)

```java
@Service
public class CombineEventServiceJob {
    
    @Value("${event.combine.shadow-mode:true}")
    private boolean shadowMode;
    
    public void execute() {
        List<BatchEventConfig> configs = getConfigs();
        
        if (shadowMode) {
            // 1. 프로시저 실행 (메인 - 실제 INSERT)
            executeWithProcedure(configs);
            
            // 2. Java 실행 (검증용 - Dry Run, INSERT 안 함)
            List<CombineResult> javaResults = orchestrator.combineAllDryRun(configs);
            
            // 3. 결과 비교 (건수 + 핵심 필드)
            compareAndLog(javaResults);
            
        } else {
            // 정상 운영: Java만 실행
            orchestrator.combineAll(configs);
        }
    }
}
```

**Dry Run 모드**:

```java
@Transactional(readOnly = true)  // INSERT 방지
public CombineResult combineDryRun(String systemCode) {
    // 동일 로직 수행하되 INSERT/UPDATE는 count만 계산
    int newCount = countNewEvents(config);
    int resolvedCount = countResolvedEvents(config);
    return CombineResult.builder()...build();
}
```

### 2. 결과 비교 검증

**비교 항목**:
- 신규 이벤트 수 (newEventCount)
- 해소 이벤트 수 (resolvedEventCount)
- 핵심 필드: event_state, zabbix_state, r_time

```java
private void compareAndLog(List<CombineResult> javaResults) {
    for (CombineResult java : javaResults) {
        // 건수 비교
        if (procCount != java.getNewEventCount()) {
            log.warn("[CombineJob] {} newEventCount mismatch: proc={}, java={}",
                java.getSystemCode(), procCount, java.getNewEventCount());
        }
        
        // 핵심 필드 비교
        List<EventDiff> diffs = compareKeyFields(java.getSystemCode());
        if (!diffs.isEmpty()) {
            log.warn("[CombineJob] {} field diff count: {}", 
                java.getSystemCode(), diffs.size());
        }
    }
}
```

### 3. 롤백 계획

| 상황 | 대응 |
|------|------|
| Java 로직 오류 | shadow-mode=true로 전환 (프로시저 사용) |
| 성능 저하 | thread-pool-size 조정 또는 프로시저 복구 |
| 데이터 불일치 | 프로시저로 롤백 + 원인 분석 |

**롤백 판단**: 수동 (로그 확인 후 설정 변경)

---

## 성능 측정 로깅

```java
// EventCombineOrchestrator
public List<CombineResult> combineAll(List<BatchEventConfig> configs) {
    long totalStart = System.currentTimeMillis();
    
    // 병렬 실행...
    List<CombineResult> results = ...;
    
    // 시스템별 로깅
    results.forEach(r -> 
        log.info("[CombineJob] {} - {}ms, new={}, resolved={}, success={}",
            r.getSystemCode(),
            r.getElapsedTimeMs(),
            r.getNewEventCount(),
            r.getResolvedEventCount(),
            r.isSuccess())
    );
    
    log.info("[CombineJob] Total - {}ms, systems={}", 
        System.currentTimeMillis() - totalStart, configs.size());
    
    return results;
}
```

**로그 출력 예시**:

```
[CombineJob] ES0001 - 1523ms, new=12, resolved=3, success=true
[CombineJob] ES0002 - 2104ms, new=8, resolved=1, success=true
[CombineJob] ES0003 - 1876ms, new=5, resolved=2, success=true
[CombineJob] ES0004 - 1432ms, new=3, resolved=0, success=true
[CombineJob] ES0005 - 1654ms, new=7, resolved=4, success=true
[CombineJob] ES0006 - 2543ms, new=15, resolved=6, success=true
[CombineJob] Total - 2651ms, systems=6
```

---

## 실패건 로깅 정책

**기존 연동 시스템 (Zabbix, Zenius)**:
- DEBUG 레벨 로깅만 (별도 관리 안 함)
- 프로시저와 동일하게 스킵

```java
if (inventory == null) {
    log.debug("Skip - inventory not found: ip={}", raw.getEventIp());
    continue;
}
```

**O11Y 연동 시 (향후)**:
- Slack 전송 (#luppiter-unregistered-events)
- 공통 모듈에서 처리

```java
// 공통 모듈에서 O11Y 여부 체크 후 Slack 전송
if (isObservabilitySource()) {
    slackNotifier.sendUnregisteredEvent(raw);
}
```

---

## 필드 매핑 체크리스트

구현 시 프로시저와 Java 간 필드 매핑 일치 여부 검증용.

**cmon_event_info 주요 필드**:

| 필드 | 프로시저 매핑 | Java 매핑 | 확인 |
|------|-------------|----------|------|
| event_id | get_next_event_sequence() | mapper.getNextEventSequence() | [ ] |
| occu_time | xied.event_dt | raw.getEventDt() | [ ] |
| target_ip | xied.event_ip | raw.getEventIp() | [ ] |
| target_contents | xied.event_contents / 조합 | buildEventContents() | [ ] |
| send_agent | v_system_ip | config.getSystemIp() | [ ] |
| event_level | CASE WHEN 2 THEN 'Critical'... | convertEventLevel() | [ ] |
| equ_barcode | inv_mst.equnr | inventory.getEqunr() | [ ] |
| device_ip | inv_mst.mgmt_ip | inventory.getMgmtIp() | [ ] |
| event_state | COALESCE(ex_info, '신규') | isException ? "예외" : "신규" | [ ] |
| zabbix_state | '지속' | "지속" | [ ] |
| trigger_id | xied.trigger_id | raw.getTriggerId() | [ ] |
| gubun | COALESCE(inv_sub, inv_mst) | getControlArea() | [ ] |
| host_group_nm | COALESCE(inv_sub, inv_mst) | getHostGroupNm() | [ ] |
| if_event_id | xied.event_id | raw.getEventId() | [ ] |

**검증 방법**: 단위 테스트 + 코드 리뷰

---

## Phase 1 일정

| 단계 | 작업 | 기간 | 산출물 |
|------|------|------|--------|
| 1 | AbstractEventCombineService 설계 | 0.5일 | 추상 클래스 + 인터페이스 |
| 2 | ZabbixEventCombineService | 2일 | Java 클래스 + Mapper |
| 3 | ZeniusEventCombineService | 1.5일 | Java 클래스 + Mapper |
| 4 | EventCombineOrchestrator | 0.5일 | 병렬 처리 |
| 5 | Shadow Mode 구현 | 0.5일 | 병행 운영 로직 |
| 6 | 단위 테스트 | 1일 | JUnit 테스트 (80%+) |
| 7 | 통합 테스트 | 1일 | 프로시저 vs Java 비교 |
| 8 | STG 병행 운영 | 1주 | 결과 비교 로그 |
| 9 | PRD 배포 | 1일 | shadow-mode=false |
| **합계** | | **8일 + 1주** | |

---

## 파일 구조 (Phase 1)

```
luppiter_scheduler/src/main/java/com/ktcloud/luppiter/
├── event/
│   ├── combine/
│   │   ├── IEventCombineService.java           # 인터페이스
│   │   ├── AbstractEventCombineService.java    # 추상 클래스 (Template)
│   │   ├── ZabbixEventCombineService.java      # Zabbix 구현
│   │   ├── ZeniusEventCombineService.java      # Zenius 구현
│   │   └── EventCombineOrchestrator.java       # 병렬 처리
│   ├── dto/
│   │   ├── CombineResult.java                  # 결과 DTO
│   │   ├── RawEvent.java                       # 원시 이벤트 (공통)
│   │   ├── ZabbixRawEvent.java                 # Zabbix 원시 이벤트
│   │   ├── ZeniusRawEvent.java                 # Zenius 원시 이벤트
│   │   ├── EventInfo.java                      # cmon_event_info DTO
│   │   └── BatchEventConfig.java               # 배치 설정 DTO
│   └── mapper/
│       ├── EventCombineMapper.java             # 취합 Mapper
│       └── EventCombineMapper.xml              # MyBatis XML
└── job/
    └── CombineEventServiceJob.java             # 수정 (Orchestrator 호출)
```

---

## 위험 요소 및 대응

| 위험 | 영향 | 대응 |
|------|------|------|
| Java 로직 오류 | 이벤트 누락/중복 | Shadow Mode 병행 운영 |
| 트랜잭션 범위 차이 | 데이터 불일치 | 프로시저와 동일한 트랜잭션 범위 |
| 병렬 처리 경합 | 데드락 | 시스템별 독립 처리 (교차 없음) |
| 시퀀스 채번 충돌 | event_id 중복 | get_next_event_sequence() 그대로 사용 |
| 인벤토리 미매핑 | 이벤트 누락 | 로깅 후 버림 (프로시저와 동일) |

---

# Phase 2: API 연동 + 통합 테이블 (2순위)

> Phase 1 완료 후 진행. 상세 계획은 Phase 1 안정화 후 수립.

## 개요

- **목표**: 새 시스템 추가 시 최소 코드 변경
- **변경 범위**: DB 구조 변경 (통합 임시 테이블)
- **전제 조건**: Phase 1 안정화 완료

## 주요 작업

1. 통합 임시 테이블 DDL 설계 (x01_if_event_unified)
2. Webhook API 구현 (EventWebhookController)
3. 기존 Worker 마이그레이션 (통합 테이블 사용)
4. 기존 임시 테이블 제거 (x01_if_event_data, x01_if_event_zenius)

## 예상 구조

```
[외부 시스템] ─Push─→ [Webhook API] ──┐
                                      ├──→ [x01_if_event_unified] → [EventCombineService]
[외부 시스템] ←Poll─→ [수집 Worker] ──┘
```
