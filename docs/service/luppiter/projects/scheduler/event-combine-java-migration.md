# 이벤트 취합 Java 전환

> 작성일: 2026-01-30
> 상태: 설계 완료, 개발 대기

---

## 목차

1. [개요](#1-개요)
2. [설계](#2-설계)
3. [의사결정](#3-의사결정)
4. [구현 코드](#4-구현-코드)
5. [안정성 확보 전략](#5-안정성-확보-전략)
6. [체크리스트](#6-체크리스트)
7. [일정 및 위험 요소](#7-일정-및-위험-요소)
8. [Phase 2 (향후)](#8-phase-2-향후)

---

## 1. 개요

### 목표
- 프로시저 제거 → Java 로직 전환 (안정성 최우선)
- 병렬 처리로 성능 개선 (36s → 6~8s)
- 향후 확장성 확보 (새 시스템 추가 용이)

### Phase 구분

| Phase | 내용 | 우선순위 | 목표 | 변경 범위 |
|-------|------|---------|------|----------|
| **Phase 1** | 프로시저 → Java 전환 | 1순위 | 안정성 + 성능 | AP만 변경, DB 구조 유지 |
| **Phase 2** | API 연동 + 통합 테이블 | 2순위 | 확장성 | AP + DB 구조 변경 |

### 핵심 원칙
- **DB 구조 변경 없음** - 기존 테이블(x01_if_event_data, x01_if_event_zenius) 그대로 사용
- **프로시저와 동일한 동작** - 인벤토리 미매핑/형식 오류 건은 로깅 후 버림 (재처리 없음)
- **병행 운영** - 프로시저와 Java 로직 동시 실행 후 결과 비교 검증
- **점진적 전환** - 검증 완료 후 프로시저 호출 제거

---

## 2. 설계

### 설계 패턴: Template Method

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
└─────────────────────────┘     └─────────────────────────┘
```

### 공통점 vs 차이점

**공통 로직 (추상 클래스)**:

| 단계 | 로직 | 메서드 |
|------|------|--------|
| 1 | 시스템 설정 조회 | `getBatchEventConfig()` |
| 2 | 인벤토리 매핑 | `mapInventory()` |
| 3 | 계위 정보 조회 | `getLayerInfo()` |
| 4 | INSERT cmon_event_info | `batchInsertEventInfo()` |
| 5 | INSERT 대응관리 정보 | `insertRespManageInfo()` |
| 6 | sync_idx 업데이트 | `updateSyncIdx()` |

**차이점 (훅 메서드)**:

| 항목 | Zabbix | Zenius |
|------|--------|--------|
| 신규 이벤트 조회 | `event_id > sync_idx`, `event_status=1` | `if_idx > sync_idx`, `z_alert IN (50,60)` |
| 예외 처리 체크 | `cmon_exception_event` 체크 | 없음 (기본 false) |
| 해소 처리 | `recovery_dst_id` 매칭 | IF 테이블에 미존재 시 |
| 이벤트 내용 | `event_contents` 그대로 | 조합 형식 |
| sync_idx 값 | `max(if_event_id)` | `max(if_idx)` |

### 실패 건 처리 흐름

```
100건 조회
    ↓
변환 처리
    ├─ 95건 성공 → validEvents 리스트에 추가
    └─ 5건 실패 → log.debug() 후 continue
    ↓
배치 INSERT 95건
    ↓
sync_idx = max(100번째 event_id)  ← 실패 건 무관하게 정상 진행
    ↓
완료 (newEventCount: 95)
```

### 패키지 구조

```
src/main/java/com/ktc/luppiter/batch/
└── event/
    ├── combine/
    │   ├── IEventCombineService.java
    │   ├── AbstractEventCombineService.java
    │   ├── ZabbixEventCombineService.java
    │   ├── ZeniusEventCombineService.java
    │   └── EventCombineOrchestrator.java
    ├── dto/
    │   ├── CombineResult.java
    │   ├── BatchEventConfig.java
    │   ├── RawEvent.java
    │   ├── ZabbixRawEvent.java
    │   ├── ZeniusRawEvent.java
    │   ├── EventInfo.java
    │   ├── InventoryMaster.java
    │   ├── InventoryMasterSub.java
    │   ├── LayerInfo.java
    │   └── ExceptionInfo.java
    └── mapper/
        └── EventCombineMapper.java

src/main/resources/sqlmap/
└── EventCombineMapper.xml
```

---

## 3. 의사결정

### 확정 사항

| 항목 | 결정 |
|------|------|
| **트랜잭션 범위** | combine() 전체를 1트랜잭션 (프로시저와 동일) |
| **스레드 풀** | 고정 6개 |
| **Shadow Mode 비교 범위** | 건수 + 핵심 필드 (event_state, zabbix_state, r_time) |
| **Shadow Mode 비교 시점** | 프로시저 먼저 실행, Java는 Dry Run |
| **롤백 트리거** | 수동 판단 (로그 확인 후 설정 변경) |
| **실패건 로깅** | 기존 시스템은 DEBUG, O11Y는 Slack |
| **성능 로깅** | 시스템별 처리 시간 (`[CombineJob]` 스타일) |
| **필드 매핑 검증** | 단위 테스트 + 체크리스트 |

### 필드 매핑 체크리스트

| 필드 | 프로시저 매핑 | Java 매핑 | 확인 |
|------|-------------|----------|------|
| event_id | get_next_event_sequence() | getNextEventSequence() | [ ] |
| occu_time | event_dt / z_evttime | eventDt / zEvttime | [ ] |
| target_ip | event_ip / z_myip | eventIp / zMyip | [ ] |
| event_level | CASE WHEN 2/4 | convertEventLevel() | [ ] |
| event_state | COALESCE(ex_info, '신규') | exceptionInfo != null ? "예외" : "신규" | [ ] |
| gubun | COALESCE(inv_sub, inv_mst) | invSub != null ? invSub : inventory | [ ] |

---

## 4. 구현 코드

### 4.1 DTO 클래스

#### CombineResult.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.ToString;

@Getter
@Builder
@ToString
public class CombineResult {
    private final String systemCode;
    private final String sourceType;
    private final int newEventCount;
    private final int resolvedEventCount;
    private final long elapsedTimeMs;
    private final boolean success;
    private final String errorMessage;
    @Builder.Default
    private final boolean dryRun = false;
}
```

#### BatchEventConfig.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class BatchEventConfig {
    private String systemCode;
    private String batchTitle;
    private String systemIp;
    private String syncIdx;
    private String eventSyncType;
    private String useYn;

    public Long getSyncIdxAsLong() {
        if (syncIdx == null || syncIdx.isEmpty()) return 0L;
        try {
            return Long.parseLong(syncIdx);
        } catch (NumberFormatException e) {
            return 0L;
        }
    }
}
```

#### RawEvent.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Getter
@Setter
public class RawEvent {
    protected Long ifEventId;
    protected LocalDateTime eventDt;
    protected Integer eventLevel;
    protected String eventContents;
    protected String eventIp;
    protected Long triggerId;
}
```

#### ZabbixRawEvent.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class ZabbixRawEvent extends RawEvent {
    private Integer eventStatus;
    private Long recoveryDstId;
    private String statusAgent;
    private String statusIpmi;
    private String statusSnmp;
    private String statusJmx;
    private Long hostId;
    private Long templateId;
    private Long itemId;
}
```

#### ZeniusRawEvent.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Getter
@Setter
public class ZeniusRawEvent extends RawEvent {
    private String ifIdx;
    private Integer zStatus;
    private Integer zAlert;
    private LocalDateTime zEvttime;
    private LocalDateTime zRectime;
    private Integer zInfraid;
    private String zMyhost;
    private String zMyip;
    private String zMyname;
    private String zMymsg;
    private String zMyid;
    private String zSetid;
    private String zeniusLevel;
    private String infraCode;
    private String setName;
    private String eventCode;
}
```

#### EventInfo.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
public class EventInfo {
    private String eventId;
    private LocalDateTime occuTime;
    private LocalDateTime createTime;
    private String targetIp;
    private String targetContents;
    private String sendAgent;
    private String eventLevel;
    private String equBarcode;
    private String deviceIp;
    private String ipmiIp;
    private String hostname;
    private String equipLabel;
    private String containerNm;
    private String datacenterNm;
    private String rackLocation;
    private String equipPosition;
    private String stdnm;
    private String estdnm;
    private String eventState;
    private String zabbixState;
    private Long triggerId;
    private String zbxAvailable;
    private String ipmiAvailable;
    private String snmpAvailable;
    private String jmxAvailable;
    private String l1Nm;
    private String l2Nm;
    private String l3Nm;
    private String zone;
    private String gubun;
    private String hostGroupNm;
    private Long ifEventId;
    private LocalDateTime lastOccuTime;
}
```

#### InventoryMaster.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class InventoryMaster {
    private String zabbixIp;
    private String equnr;
    private String mgmtIp;
    private String ipmiIp;
    private String hostNm;
    private String hostType;
    private String centerNm;
    private String datacenterNm;
    private String rackLocation;
    private String equipPosition;
    private String stdNm;
    private String eStdNm;
    private String zone;
    private String controlArea;
    private String hostGroupNm;
    private String l1LayerCd;
    private String l2LayerCd;
    private String l3LayerCd;
}
```

#### InventoryMasterSub.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class InventoryMasterSub {
    private String zabbixIp;
    private String controlArea;
    private String hostGroupNm;
}
```

#### LayerInfo.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class LayerInfo {
    private String l1Nm;
    private String l2Nm;
    private String l3Nm;
}
```

#### ExceptionInfo.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

@Getter
@Setter
public class ExceptionInfo {
    private String ip;
    private Long triggerId;
    private String eventState;
    private LocalDateTime excpTime;
    private LocalDateTime startDtm;
    private LocalDateTime endDtm;
    private String excpContents;
}
```

---

### 4.2 인터페이스 및 추상 클래스

#### IEventCombineService.java

```java
package com.ktc.luppiter.batch.event.combine;

import com.ktc.luppiter.batch.event.dto.BatchEventConfig;
import com.ktc.luppiter.batch.event.dto.CombineResult;

public interface IEventCombineService {
    String getSourceType();
    String getSupportedEventType();
    CombineResult combine(BatchEventConfig config);
    CombineResult combineDryRun(BatchEventConfig config);
}
```

#### AbstractEventCombineService.java

```java
package com.ktc.luppiter.batch.event.combine;

import com.ktc.luppiter.batch.event.dto.*;
import com.ktc.luppiter.batch.event.mapper.EventCombineMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Slf4j
public abstract class AbstractEventCombineService implements IEventCombineService {

    @Autowired
    protected EventCombineMapper eventCombineMapper;

    @Override
    @Transactional
    public CombineResult combine(BatchEventConfig config) {
        long startTime = System.currentTimeMillis();
        String systemCode = config.getSystemCode();

        log.info("[{}] {} 취합 시작", systemCode, getSourceType());

        try {
            validateConfig(config);

            int newCount = processNewEvents(config);
            int resolvedCount = processResolvedEvents(config);
            updateSyncIdx(config);

            long elapsed = System.currentTimeMillis() - startTime;
            log.info("[{}] {} 취합 완료 - {}ms, new={}, resolved={}",
                systemCode, getSourceType(), elapsed, newCount, resolvedCount);

            return CombineResult.builder()
                .systemCode(systemCode)
                .sourceType(getSourceType())
                .newEventCount(newCount)
                .resolvedEventCount(resolvedCount)
                .elapsedTimeMs(elapsed)
                .success(true)
                .build();

        } catch (Exception e) {
            long elapsed = System.currentTimeMillis() - startTime;
            log.error("[{}] {} 취합 실패 - {}ms", systemCode, getSourceType(), elapsed, e);

            return CombineResult.builder()
                .systemCode(systemCode)
                .sourceType(getSourceType())
                .success(false)
                .errorMessage(e.getMessage())
                .elapsedTimeMs(elapsed)
                .build();
        }
    }

    @Override
    @Transactional(readOnly = true)
    public CombineResult combineDryRun(BatchEventConfig config) {
        long startTime = System.currentTimeMillis();
        String systemCode = config.getSystemCode();

        try {
            validateConfig(config);

            List<? extends RawEvent> rawEvents = findNewEvents(config);
            int expectedNewCount = countValidEvents(rawEvents);
            int expectedResolvedCount = countResolvedEvents(config);

            return CombineResult.builder()
                .systemCode(systemCode)
                .sourceType(getSourceType())
                .newEventCount(expectedNewCount)
                .resolvedEventCount(expectedResolvedCount)
                .elapsedTimeMs(System.currentTimeMillis() - startTime)
                .success(true)
                .dryRun(true)
                .build();

        } catch (Exception e) {
            return CombineResult.builder()
                .systemCode(systemCode)
                .sourceType(getSourceType())
                .success(false)
                .errorMessage(e.getMessage())
                .elapsedTimeMs(System.currentTimeMillis() - startTime)
                .dryRun(true)
                .build();
        }
    }

    protected void validateConfig(BatchEventConfig config) {
        if (config == null) {
            throw new IllegalArgumentException("BatchEventConfig is null");
        }
        if (config.getSystemCode() == null || config.getSystemCode().isEmpty()) {
            throw new IllegalArgumentException("systemCode is required");
        }
        if (config.getSystemIp() == null || config.getSystemIp().isEmpty()) {
            throw new IllegalArgumentException(config.getSystemCode() + " has no system_ip");
        }
    }

    protected int processNewEvents(BatchEventConfig config) {
        List<? extends RawEvent> rawEvents = findNewEvents(config);

        if (rawEvents == null || rawEvents.isEmpty()) {
            log.debug("[{}] 신규 이벤트 없음", config.getSystemCode());
            return 0;
        }

        log.debug("[{}] 신규 이벤트 {} 건 조회", config.getSystemCode(), rawEvents.size());

        List<EventInfo> validEvents = new ArrayList<>();

        for (RawEvent raw : rawEvents) {
            try {
                EventInfo eventInfo = convertToEventInfo(raw, config);
                if (eventInfo != null) {
                    validEvents.add(eventInfo);
                }
            } catch (Exception e) {
                log.debug("[{}] 이벤트 변환 스킵 - id={}, reason={}",
                    config.getSystemCode(), raw.getIfEventId(), e.getMessage());
            }
        }

        if (validEvents.isEmpty()) {
            return 0;
        }

        eventCombineMapper.batchInsertEventInfo(validEvents);

        List<String> eventIds = validEvents.stream()
            .map(EventInfo::getEventId)
            .toList();
        eventCombineMapper.insertRespManageInfo(eventIds);

        log.debug("[{}] 신규 이벤트 {} 건 처리 완료", config.getSystemCode(), validEvents.size());

        return validEvents.size();
    }

    protected EventInfo convertToEventInfo(RawEvent raw, BatchEventConfig config) {
        InventoryMaster inventory = eventCombineMapper.findInventoryByZabbixIp(raw.getEventIp());
        if (inventory == null) {
            log.debug("Skip - inventory not found: ip={}", raw.getEventIp());
            return null;
        }

        ExceptionInfo exceptionInfo = checkException(raw);

        LayerInfo layerInfo = eventCombineMapper.findLayerInfo(
            inventory.getL1LayerCd(),
            inventory.getL2LayerCd(),
            inventory.getL3LayerCd()
        );

        InventoryMasterSub invSub = eventCombineMapper.findInventorySub(
            raw.getEventIp(),
            getEventContentsForSubMatch(raw)
        );

        String eventId = eventCombineMapper.getNextEventSequence();

        return EventInfo.builder()
            .eventId(eventId)
            .occuTime(raw.getEventDt())
            .createTime(LocalDateTime.now())
            .targetIp(raw.getEventIp())
            .targetContents(buildEventContents(raw))
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
            .eventState(exceptionInfo != null ? "예외" : "신규")
            .zabbixState("지속")
            .triggerId(raw.getTriggerId())
            .l1Nm(layerInfo != null ? layerInfo.getL1Nm() : null)
            .l2Nm(layerInfo != null ? layerInfo.getL2Nm() : null)
            .l3Nm(layerInfo != null ? layerInfo.getL3Nm() : null)
            .zone(inventory.getZone())
            .gubun(invSub != null ? invSub.getControlArea() : inventory.getControlArea())
            .hostGroupNm(invSub != null ? invSub.getHostGroupNm() : inventory.getHostGroupNm())
            .ifEventId(raw.getIfEventId())
            .lastOccuTime(LocalDateTime.now())
            .build();
    }

    protected String convertEventLevel(Integer level) {
        if (level == null) return null;
        return switch (level) {
            case 2 -> "Critical";
            case 4 -> "Fatal";
            default -> String.valueOf(level);
        };
    }

    protected void updateSyncIdx(BatchEventConfig config) {
        Object maxSyncIdx = getMaxSyncIdx(config);
        if (maxSyncIdx != null) {
            eventCombineMapper.updateSyncIdx(config.getSystemCode(), maxSyncIdx.toString());
        }
    }

    protected int countValidEvents(List<? extends RawEvent> rawEvents) {
        if (rawEvents == null || rawEvents.isEmpty()) return 0;
        int count = 0;
        for (RawEvent raw : rawEvents) {
            if (eventCombineMapper.findInventoryByZabbixIp(raw.getEventIp()) != null) {
                count++;
            }
        }
        return count;
    }

    // ========== 훅 메서드 ==========

    protected abstract List<? extends RawEvent> findNewEvents(BatchEventConfig config);
    protected abstract int processResolvedEvents(BatchEventConfig config);
    protected abstract int countResolvedEvents(BatchEventConfig config);
    protected abstract Object getMaxSyncIdx(BatchEventConfig config);
    protected abstract String buildEventContents(RawEvent raw);

    protected String getEventContentsForSubMatch(RawEvent raw) {
        return raw.getEventContents();
    }

    protected ExceptionInfo checkException(RawEvent raw) {
        return null;
    }
}
```

---

### 4.3 서비스 구현

#### ZabbixEventCombineService.java

```java
package com.ktc.luppiter.batch.event.combine;

import com.ktc.luppiter.batch.event.dto.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

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
    protected List<ZabbixRawEvent> findNewEvents(BatchEventConfig config) {
        return eventCombineMapper.findNewZabbixEvents(
            config.getSystemCode(),
            config.getSyncIdxAsLong(),
            config.getSystemIp()
        );
    }

    @Override
    protected ExceptionInfo checkException(RawEvent raw) {
        return eventCombineMapper.findExceptionInfo(raw.getEventIp(), raw.getTriggerId());
    }

    @Override
    protected EventInfo convertToEventInfo(RawEvent raw, BatchEventConfig config) {
        EventInfo eventInfo = super.convertToEventInfo(raw, config);

        if (eventInfo != null && raw instanceof ZabbixRawEvent zabbixRaw) {
            eventInfo.setZbxAvailable(zabbixRaw.getStatusAgent());
            eventInfo.setIpmiAvailable(zabbixRaw.getStatusIpmi());
            eventInfo.setSnmpAvailable(zabbixRaw.getStatusSnmp());
            eventInfo.setJmxAvailable(zabbixRaw.getStatusJmx());
        }

        return eventInfo;
    }

    @Override
    protected int processResolvedEvents(BatchEventConfig config) {
        int exceptionResolved = eventCombineMapper.resolveZabbixExceptionEvents(
            config.getSystemCode(),
            config.getSyncIdxAsLong(),
            config.getSystemIp()
        );

        int normalResolved = eventCombineMapper.resolveZabbixNormalEvents(
            config.getSystemCode(),
            config.getSyncIdxAsLong()
        );

        log.debug("[{}] 해소 처리 - 예외:{}, 일반:{}",
            config.getSystemCode(), exceptionResolved, normalResolved);

        return exceptionResolved + normalResolved;
    }

    @Override
    protected int countResolvedEvents(BatchEventConfig config) {
        return eventCombineMapper.countZabbixResolvedEvents(
            config.getSystemCode(),
            config.getSyncIdxAsLong()
        );
    }

    @Override
    protected Object getMaxSyncIdx(BatchEventConfig config) {
        return eventCombineMapper.getMaxZabbixIfEventId(config.getSystemIp());
    }

    @Override
    protected String buildEventContents(RawEvent raw) {
        return raw.getEventContents();
    }
}
```

#### ZeniusEventCombineService.java

```java
package com.ktc.luppiter.batch.event.combine;

import com.ktc.luppiter.batch.event.dto.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

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
    protected List<ZeniusRawEvent> findNewEvents(BatchEventConfig config) {
        return eventCombineMapper.findNewZeniusEvents(
            config.getSystemCode(),
            config.getSyncIdx(),
            config.getSystemIp()
        );
    }

    @Override
    protected int processResolvedEvents(BatchEventConfig config) {
        return eventCombineMapper.resolveZeniusEvents(
            config.getSystemCode(),
            config.getSyncIdx(),
            config.getSystemIp()
        );
    }

    @Override
    protected int countResolvedEvents(BatchEventConfig config) {
        return eventCombineMapper.countZeniusResolvedEvents(
            config.getSystemCode(),
            config.getSyncIdx(),
            config.getSystemIp()
        );
    }

    @Override
    protected Object getMaxSyncIdx(BatchEventConfig config) {
        return eventCombineMapper.getMaxZeniusIfIdx();
    }

    @Override
    protected String buildEventContents(RawEvent raw) {
        if (raw instanceof ZeniusRawEvent zenius) {
            return String.format("%s %s/%s/%s/%s",
                zenius.getEventCode(),
                zenius.getZeniusLevel(),
                zenius.getSetName(),
                zenius.getZMyname(),
                zenius.getZMymsg()
            );
        }
        return raw.getEventContents();
    }

    @Override
    protected String getEventContentsForSubMatch(RawEvent raw) {
        if (raw instanceof ZeniusRawEvent zenius) {
            return zenius.getEventCode();
        }
        return raw.getEventContents();
    }

    @Override
    protected EventInfo convertToEventInfo(RawEvent raw, BatchEventConfig config) {
        EventInfo eventInfo = super.convertToEventInfo(raw, config);

        if (eventInfo != null && raw instanceof ZeniusRawEvent zeniusRaw) {
            eventInfo.setOccuTime(zeniusRaw.getZEvttime());
            if (zeniusRaw.getZMyid() != null && !zeniusRaw.getZMyid().isEmpty()) {
                try {
                    eventInfo.setTriggerId(Long.parseLong(zeniusRaw.getZMyid()));
                } catch (NumberFormatException e) {
                    log.warn("Invalid z_myid: {}", zeniusRaw.getZMyid());
                }
            }
        }

        return eventInfo;
    }
}
```

#### EventCombineOrchestrator.java

```java
package com.ktc.luppiter.batch.event.combine;

import com.ktc.luppiter.batch.event.dto.BatchEventConfig;
import com.ktc.luppiter.batch.event.dto.CombineResult;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

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
        log.info("EventCombineOrchestrator initialized with {} threads", threadPoolSize);
    }

    @PreDestroy
    public void destroy() {
        if (executor != null) {
            executor.shutdown();
        }
    }

    public List<CombineResult> combineAll(List<BatchEventConfig> configs) {
        log.info("[CombineJob] 병렬 취합 시작 - {} systems", configs.size());
        long startTime = System.currentTimeMillis();

        List<CompletableFuture<CombineResult>> futures = configs.stream()
            .map(config -> CompletableFuture.supplyAsync(() -> {
                IEventCombineService service = findService(config.getEventSyncType());
                return service.combine(config);
            }, executor))
            .toList();

        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();

        List<CombineResult> results = futures.stream()
            .map(CompletableFuture::join)
            .toList();

        long totalElapsed = System.currentTimeMillis() - startTime;

        results.forEach(r ->
            log.info("[CombineJob] {} - {}ms, new={}, resolved={}, success={}",
                r.getSystemCode(), r.getElapsedTimeMs(),
                r.getNewEventCount(), r.getResolvedEventCount(), r.isSuccess())
        );

        log.info("[CombineJob] 병렬 취합 완료 - {}ms, systems={}", totalElapsed, configs.size());

        return results;
    }

    public List<CombineResult> combineAllDryRun(List<BatchEventConfig> configs) {
        log.debug("[CombineJob] Dry Run 시작 - {} systems", configs.size());

        List<CompletableFuture<CombineResult>> futures = configs.stream()
            .map(config -> CompletableFuture.supplyAsync(() -> {
                IEventCombineService service = findService(config.getEventSyncType());
                return service.combineDryRun(config);
            }, executor))
            .toList();

        CompletableFuture.allOf(futures.toArray(new CompletableFuture[0])).join();

        return futures.stream()
            .map(CompletableFuture::join)
            .toList();
    }

    private IEventCombineService findService(String eventSyncType) {
        return combineServices.stream()
            .filter(s -> s.getSupportedEventType().contains(eventSyncType))
            .findFirst()
            .orElseThrow(() -> new IllegalArgumentException("Unknown event sync type: " + eventSyncType));
    }
}
```

---

### 4.4 Mapper

#### EventCombineMapper.java

```java
package com.ktc.luppiter.batch.event.mapper;

import com.ktc.luppiter.batch.event.dto.*;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface EventCombineMapper {

    // ========== 공통 ==========

    String getNextEventSequence();

    InventoryMaster findInventoryByZabbixIp(@Param("zabbixIp") String zabbixIp);

    InventoryMasterSub findInventorySub(
        @Param("zabbixIp") String zabbixIp,
        @Param("eventContents") String eventContents
    );

    LayerInfo findLayerInfo(
        @Param("l1LayerCd") String l1LayerCd,
        @Param("l2LayerCd") String l2LayerCd,
        @Param("l3LayerCd") String l3LayerCd
    );

    void batchInsertEventInfo(@Param("list") List<EventInfo> eventInfoList);

    void insertRespManageInfo(@Param("eventIds") List<String> eventIds);

    void updateSyncIdx(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") String syncIdx
    );

    // ========== Zabbix ==========

    List<ZabbixRawEvent> findNewZabbixEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") Long syncIdx,
        @Param("systemIp") String systemIp
    );

    ExceptionInfo findExceptionInfo(
        @Param("ip") String ip,
        @Param("triggerId") Long triggerId
    );

    int resolveZabbixExceptionEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") Long syncIdx,
        @Param("systemIp") String systemIp
    );

    int resolveZabbixNormalEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") Long syncIdx
    );

    int countZabbixResolvedEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") Long syncIdx
    );

    Long getMaxZabbixIfEventId(@Param("systemIp") String systemIp);

    // ========== Zenius ==========

    List<ZeniusRawEvent> findNewZeniusEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") String syncIdx,
        @Param("systemIp") String systemIp
    );

    int resolveZeniusEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") String syncIdx,
        @Param("systemIp") String systemIp
    );

    int countZeniusResolvedEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") String syncIdx,
        @Param("systemIp") String systemIp
    );

    String getMaxZeniusIfIdx();
}
```

---

### 4.5 MyBatis XML

#### EventCombineMapper.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.ktc.luppiter.batch.event.mapper.EventCombineMapper">

    <!-- ========== 공통 ========== -->

    <select id="getNextEventSequence" resultType="String">
        SELECT get_next_event_sequence()
    </select>

    <select id="findInventoryByZabbixIp" resultType="com.ktc.luppiter.batch.event.dto.InventoryMaster">
        SELECT zabbix_ip, equnr, mgmt_ip, ipmi_ip, host_nm, host_type,
               center_nm, datacenter_nm, rack_location, equip_position,
               std_nm, e_std_nm, zone, control_area, host_group_nm,
               l1_layer_cd, l2_layer_cd, l3_layer_cd
        FROM inventory_master
        WHERE zabbix_ip = #{zabbixIp}
    </select>

    <select id="findInventorySub" resultType="com.ktc.luppiter.batch.event.dto.InventoryMasterSub">
        SELECT zabbix_ip, control_area, host_group_nm
        FROM inventory_master_sub
        WHERE zabbix_ip = #{zabbixIp}
          AND POSITION(SPLIT_PART(control_area, '_', 2) IN SUBSTRING(#{eventContents}, 1, 8)) > 0
        LIMIT 1
    </select>

    <select id="findLayerInfo" resultType="com.ktc.luppiter.batch.event.dto.LayerInfo">
        SELECT l1.layer_nm AS l1_nm, l2.layer_nm AS l2_nm, l3.layer_nm AS l3_nm
        FROM (SELECT 1) AS dummy
        LEFT JOIN cmon_layer_code_info l1 ON l1.layer_cd = #{l1LayerCd}
        LEFT JOIN cmon_layer_code_info l2 ON l2.layer_cd = #{l2LayerCd}
        LEFT JOIN cmon_layer_code_info l3 ON l3.layer_cd = #{l3LayerCd}
    </select>

    <insert id="batchInsertEventInfo">
        INSERT INTO cmon_event_info (
            event_id, occu_time, create_time, target_ip, target_contents,
            send_agent, event_level, equ_barcode, device_ip, ipmi_ip,
            hostname, equip_label, container_nm, datacenter_nm, rack_location,
            equip_position, stdnm, estdnm, event_state, zabbix_state,
            trigger_id, zbx_available, ipmi_available, snmp_available, jmx_available,
            l1_nm, l2_nm, l3_nm, zone, gubun, host_group_nm, if_event_id, last_occu_time
        ) VALUES
        <foreach collection="list" item="e" separator=",">
            (#{e.eventId}, #{e.occuTime}, #{e.createTime}, #{e.targetIp}, #{e.targetContents},
             #{e.sendAgent}, #{e.eventLevel}, #{e.equBarcode}, #{e.deviceIp}, #{e.ipmiIp},
             #{e.hostname}, #{e.equipLabel}, #{e.containerNm}, #{e.datacenterNm}, #{e.rackLocation},
             #{e.equipPosition}, #{e.stdnm}, #{e.estdnm}, #{e.eventState}, #{e.zabbixState},
             #{e.triggerId}, #{e.zbxAvailable}, #{e.ipmiAvailable}, #{e.snmpAvailable}, #{e.jmxAvailable},
             #{e.l1Nm}, #{e.l2Nm}, #{e.l3Nm}, #{e.zone}, #{e.gubun}, #{e.hostGroupNm}, #{e.ifEventId}, #{e.lastOccuTime})
        </foreach>
    </insert>

    <insert id="insertRespManageInfo">
        INSERT INTO cmon_event_resp_manage_info (
            event_id, resp_level, manage_dept, user_id_1st, user_id_2nd,
            control_dept, concall_group, resp_info, create_time, user_id_ktcloud
        )
        SELECT evt.event_id, rmi.resp_level, rmi.manage_dept, rmi.user_id_1st, rmi.user_id_2nd,
               rmi.control_dept, rmi.concall_group, rmi.resp_info, now(), rmi.user_id_ktcloud
        FROM cmon_resp_manage_info rmi
        INNER JOIN cmon_event_info evt
            ON evt.event_id IN
            <foreach collection="eventIds" item="id" open="(" separator="," close=")">#{id}</foreach>
            AND evt.host_group_nm = rmi.host_group_nm
        ON CONFLICT (event_id) DO NOTHING
    </insert>

    <update id="updateSyncIdx">
        UPDATE c01_batch_event
        SET sync_idx = #{syncIdx}, sync_dt = now()
        WHERE system_code = #{systemCode}
    </update>

    <!-- ========== Zabbix ========== -->

    <select id="findNewZabbixEvents" resultType="com.ktc.luppiter.batch.event.dto.ZabbixRawEvent">
        SELECT xied.event_id AS if_event_id, xied.event_dt, xied.event_level,
               xied.event_contents, xied.event_ip, xied.trigger_id,
               xied.event_status, xied.recovery_dst_id,
               xied.status_agent, xied.status_ipmi, xied.status_snmp, xied.status_jmx,
               xied.host_id, xied.template_id, xied.item_id
        FROM x01_if_event_data xied
        WHERE xied.system_code = #{systemCode}
          AND xied.event_id > #{syncIdx}
          AND xied.event_status = 1
          AND xied.event_level IN (2, 4)
          AND xied.maintenance_status = 0
          AND NOT EXISTS (
              SELECT 1 FROM cmon_event_info evt
              WHERE evt.send_agent = #{systemIp} AND evt.if_event_id = xied.event_id
          )
        ORDER BY xied.event_id
    </select>

    <select id="findExceptionInfo" resultType="com.ktc.luppiter.batch.event.dto.ExceptionInfo">
        SELECT exd.ip, exd.trigger_id, '예외' AS event_state,
               GREATEST(ex.start_dtm, ex.cret_dt) AS excp_time,
               ex.start_dtm, ex.end_dtm, ex.evt_excp_contents AS excp_contents
        FROM cmon_exception_event ex
        INNER JOIN cmon_exception_event_detail exd ON ex.excp_seq = exd.excp_seq
        WHERE exd.ip = #{ip} AND exd.trigger_id = #{triggerId}
          AND exd.delete_yn = 'N'
          AND now() BETWEEN ex.start_dtm AND ex.end_dtm
        LIMIT 1
    </select>

    <update id="resolveZabbixExceptionEvents">
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
            last_occu_time = now()
        FROM (
            SELECT cei.event_id, xied.event_dt, ex_evt.excp_time, ex_evt.ex_contents, ex_evt.ex_event_state
            FROM cmon_event_info cei
            INNER JOIN x01_if_event_data xied
                ON cei.trigger_id = xied.trigger_id AND cei.if_event_id = xied.recovery_dst_id
                AND xied.system_code = #{systemCode} AND xied.event_id > #{syncIdx} AND xied.event_status = 0
            INNER JOIN (
                SELECT GREATEST(ex.start_dtm, ex.cret_dt) AS excp_time, ex.evt_excp_contents AS ex_contents,
                       exd.ip AS ex_ip, exd.trigger_id AS ex_trigger_id, '예외' AS ex_event_state
                FROM cmon_exception_event ex
                INNER JOIN cmon_exception_event_detail exd ON ex.excp_seq = exd.excp_seq
                WHERE now() BETWEEN ex.start_dtm AND ex.end_dtm AND exd.delete_yn = 'N'
            ) AS ex_evt ON ex_evt.ex_trigger_id = cei.trigger_id AND ex_evt.ex_ip = cei.target_ip
            WHERE cei.r_time IS NULL
        ) AS r_evt
        WHERE ei.event_id = r_evt.event_id
    </update>

    <update id="resolveZabbixNormalEvents">
        UPDATE cmon_event_info evt
        SET zabbix_state = '해소', r_time = r_evt.event_dt, last_occu_time = now()
        FROM (
            SELECT cei.event_id, xied.event_dt
            FROM cmon_event_info cei
            INNER JOIN x01_if_event_data xied
                ON cei.trigger_id = xied.trigger_id AND cei.if_event_id = xied.recovery_dst_id
                AND xied.system_code = #{systemCode} AND xied.event_status = 0 AND xied.event_id > #{syncIdx}
            WHERE cei.r_time IS NULL
        ) AS r_evt
        WHERE evt.event_id = r_evt.event_id
    </update>

    <select id="countZabbixResolvedEvents" resultType="int">
        SELECT COUNT(*)
        FROM cmon_event_info cei
        INNER JOIN x01_if_event_data xied
            ON cei.trigger_id = xied.trigger_id AND cei.if_event_id = xied.recovery_dst_id
            AND xied.system_code = #{systemCode} AND xied.event_status = 0 AND xied.event_id > #{syncIdx}
        WHERE cei.r_time IS NULL
    </select>

    <select id="getMaxZabbixIfEventId" resultType="Long">
        SELECT MAX(if_event_id) FROM cmon_event_info WHERE send_agent = #{systemIp}
    </select>

    <!-- ========== Zenius ========== -->

    <select id="findNewZeniusEvents" resultType="com.ktc.luppiter.batch.event.dto.ZeniusRawEvent">
        SELECT DISTINCT ON (xiez.z_myip, xiez.z_myid)
               xiez.if_idx, xiez.z_evttime AS event_dt, xiez.event_level,
               xiez.z_myip AS event_ip, xiez.z_myid::numeric AS trigger_id,
               xiez.z_status, xiez.z_alert, xiez.z_evttime, xiez.z_rectime,
               xiez.z_infraid, xiez.z_myhost, xiez.z_myip, xiez.z_myname, xiez.z_mymsg,
               xiez.z_myid, xiez.z_setid, xiez.zenius_level, xiez.infra_code, xiez.set_name, xiez.event_code
        FROM x01_if_event_zenius xiez
        LEFT JOIN cmon_event_info evt
            ON xiez.z_myip = evt.target_ip AND xiez.z_myid::numeric = evt.trigger_id
            AND evt.zabbix_state IN ('신규', '지속')
        WHERE evt.event_id IS NULL
          AND xiez.system_code = #{systemCode}
          AND xiez.z_alert IN (50, 60)
          AND xiez.if_idx > #{syncIdx}
    </select>

    <update id="resolveZeniusEvents">
        UPDATE cmon_event_info evt
        SET zabbix_state = '해소', r_time = now(), last_occu_time = now()
        FROM (
            SELECT event_id
            FROM cmon_event_info evt
            LEFT JOIN x01_if_event_zenius xiez
                ON xiez.z_myip = evt.target_ip AND xiez.z_myid::numeric = evt.trigger_id
                AND xiez.system_code = #{systemCode} AND xiez.z_alert IN (50, 60) AND xiez.if_idx > #{syncIdx}
            WHERE evt.zabbix_state = '지속' AND evt.send_agent = #{systemIp} AND xiez.z_myid IS NULL
        ) AS r_evt
        WHERE evt.event_id = r_evt.event_id
    </update>

    <select id="countZeniusResolvedEvents" resultType="int">
        SELECT COUNT(*)
        FROM cmon_event_info evt
        LEFT JOIN x01_if_event_zenius xiez
            ON xiez.z_myip = evt.target_ip AND xiez.z_myid::numeric = evt.trigger_id
            AND xiez.system_code = #{systemCode} AND xiez.z_alert IN (50, 60) AND xiez.if_idx > #{syncIdx}
        WHERE evt.zabbix_state = '지속' AND evt.send_agent = #{systemIp} AND xiez.z_myid IS NULL
    </select>

    <select id="getMaxZeniusIfIdx" resultType="String">
        SELECT MAX(if_idx) FROM x01_if_event_zenius
    </select>

</mapper>
```

---

### 4.6 CombineEventServiceJob 수정

```java
package com.ktc.luppiter.batch.task.common;

import com.ktc.luppiter.batch.core.CustomScheduledTaskManager;
import com.ktc.luppiter.batch.event.combine.EventCombineOrchestrator;
import com.ktc.luppiter.batch.event.dto.BatchEventConfig;
import com.ktc.luppiter.batch.event.dto.CombineResult;
import com.ktc.luppiter.batch.mapper.BatchSchedulerMapper;
import com.ktc.luppiter.batch.mapper.EventBatchMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.StringUtils;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.net.InetAddress;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
@Slf4j
public class CombineEventServiceJob implements Runnable {

    private static final String BEAN_NAME = "CombineEventServiceJob";
    private static final DateTimeFormatter FORMATTER = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    private final BatchSchedulerMapper batchSchedulerMapper;
    private final EventBatchMapper eventBatchMapper;
    private final EventCombineOrchestrator orchestrator;

    @Value("${event.combine.shadow-mode:true}")
    private boolean shadowMode;

    @Override
    public void run() {
        log.debug("[{}] 시작", BEAN_NAME);

        Map<String, Object> pLogMap = new HashMap<>();

        try {
            String jobDateTime = LocalDateTime.now().format(FORMATTER);
            InetAddress localhost = InetAddress.getLocalHost();

            pLogMap.put("batch_bean", BEAN_NAME);
            pLogMap.put("result", CustomScheduledTaskManager.BATCH_STATUS_RUNNING);
            pLogMap.put("server_hostname", localhost.getHostName());
            pLogMap.put("server_ip", localhost.getHostAddress());
            pLogMap.put("start_dt", jobDateTime);

            batchSchedulerMapper.batchStartLog(pLogMap);

            List<Map<String, String>> batchMapList = batchSchedulerMapper.selectBatchEventList();

            List<BatchEventConfig> configs = batchMapList.stream()
                .filter(map -> "Y".equalsIgnoreCase(map.get("use_yn")))
                .map(this::toBatchEventConfig)
                .toList();

            if (shadowMode) {
                executeShadowMode(configs, batchMapList);
            } else {
                orchestrator.combineAll(configs);
            }

            pLogMap.put("result", CustomScheduledTaskManager.BATCH_STATUS_COMPLETED);

        } catch (Exception e) {
            log.error("[{}] 동작중 오류: {}", BEAN_NAME, e.getMessage(), e);
            pLogMap.put("result", CustomScheduledTaskManager.BATCH_STATUS_FAILURE);
            pLogMap.put("log_msg", e.getMessage());
        } finally {
            batchSchedulerMapper.batchEndLog(pLogMap);
            log.debug("[{}] 종료", BEAN_NAME);
        }
    }

    private void executeShadowMode(List<BatchEventConfig> configs, List<Map<String, String>> batchMapList) {
        // 1. 프로시저 실행 (기존 로직)
        for (Map<String, String> map : batchMapList) {
            String useFlag = StringUtils.equalsIgnoreCase(map.get("use_yn"), "Y") ? "Y" : "N";
            String systemCode = map.get("system_code");
            String eventSyncTypeCode = map.get("event_sync_type");

            if ("Y".equals(useFlag)) {
                log.debug("[{}] 프로시저 실행", systemCode);

                Map<String, Object> combineParams = new HashMap<>();
                combineParams.put("systemCode", systemCode);

                try {
                    if (StringUtils.equalsIgnoreCase(eventSyncTypeCode, "EST020")) {
                        eventBatchMapper.combineEventForZenius(combineParams);
                    } else {
                        eventBatchMapper.combineEventForZabbix(combineParams);
                    }
                } catch (Exception e) {
                    log.warn("[{}] 프로시저 오류: {}", systemCode, e.getMessage());
                }
            }
        }

        // 2. Java Dry Run
        List<CombineResult> javaResults = orchestrator.combineAllDryRun(configs);

        // 3. 결과 비교 로깅
        for (CombineResult java : javaResults) {
            log.info("[ShadowMode] {} - Java예상: new={}, resolved={}",
                java.getSystemCode(), java.getNewEventCount(), java.getResolvedEventCount());
        }
    }

    private BatchEventConfig toBatchEventConfig(Map<String, String> map) {
        BatchEventConfig config = new BatchEventConfig();
        config.setSystemCode(map.get("system_code"));
        config.setBatchTitle(map.get("batch_title"));
        config.setSystemIp(map.get("system_ip"));
        config.setSyncIdx(map.get("sync_idx"));
        config.setEventSyncType(map.get("event_sync_type"));
        config.setUseYn(map.get("use_yn"));
        return config;
    }
}
```

---

### 4.7 application.yml 설정

```yaml
event:
  combine:
    shadow-mode: true
    thread-pool-size: 6
```

---

## 5. 안정성 확보 전략

### Shadow Mode 동작

```
shadowMode=true:
  1. 프로시저 실행 (메인 - 실제 INSERT)
  2. Java Dry Run (검증용 - INSERT 안 함)
  3. 결과 비교 로깅

shadowMode=false:
  1. Java만 실행 (실제 INSERT)
```

### 결과 비교 검증

**비교 항목**:
- 신규 이벤트 수 (newEventCount)
- 해소 이벤트 수 (resolvedEventCount)
- 핵심 필드: event_state, zabbix_state, r_time

### 롤백 계획

| 상황 | 대응 |
|------|------|
| Java 로직 오류 | shadow-mode=true로 전환 |
| 성능 저하 | thread-pool-size 조정 또는 프로시저 복구 |
| 데이터 불일치 | 프로시저로 롤백 + 원인 분석 |

---

## 6. 체크리스트

### 파일 생성 확인

| # | 파일 | 위치 | 확인 |
|---|------|------|------|
| 1 | CombineResult.java | event/dto/ | [ ] |
| 2 | BatchEventConfig.java | event/dto/ | [ ] |
| 3 | RawEvent.java | event/dto/ | [ ] |
| 4 | ZabbixRawEvent.java | event/dto/ | [ ] |
| 5 | ZeniusRawEvent.java | event/dto/ | [ ] |
| 6 | EventInfo.java | event/dto/ | [ ] |
| 7 | InventoryMaster.java | event/dto/ | [ ] |
| 8 | InventoryMasterSub.java | event/dto/ | [ ] |
| 9 | LayerInfo.java | event/dto/ | [ ] |
| 10 | ExceptionInfo.java | event/dto/ | [ ] |
| 11 | IEventCombineService.java | event/combine/ | [ ] |
| 12 | AbstractEventCombineService.java | event/combine/ | [ ] |
| 13 | ZabbixEventCombineService.java | event/combine/ | [ ] |
| 14 | ZeniusEventCombineService.java | event/combine/ | [ ] |
| 15 | EventCombineOrchestrator.java | event/combine/ | [ ] |
| 16 | EventCombineMapper.java | event/mapper/ | [ ] |
| 17 | EventCombineMapper.xml | resources/sqlmap/ | [ ] |
| 18 | CombineEventServiceJob.java | task/common/ | [ ] (수정) |

### 배포 단계

| 단계 | 작업 | 설정 | 확인 |
|------|------|------|------|
| 1 | STG 배포 | shadow-mode=true | [ ] |
| 2 | 1주일 모니터링 | 로그 비교 확인 | [ ] |
| 3 | PRD 배포 | shadow-mode=true | [ ] |
| 4 | 1주일 모니터링 | 로그 비교 확인 | [ ] |
| 5 | shadow-mode 해제 | shadow-mode=false | [ ] |
| 6 | 프로시저 호출 코드 제거 | - | [ ] |

---

## 7. 일정 및 위험 요소

### 일정

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

### 위험 요소 및 대응

| 위험 | 영향 | 대응 |
|------|------|------|
| Java 로직 오류 | 이벤트 누락/중복 | Shadow Mode 병행 운영 |
| 트랜잭션 범위 차이 | 데이터 불일치 | 프로시저와 동일한 트랜잭션 범위 |
| 병렬 처리 경합 | 데드락 | 시스템별 독립 처리 |
| 시퀀스 채번 충돌 | event_id 중복 | get_next_event_sequence() 그대로 사용 |
| 인벤토리 미매핑 | 이벤트 누락 | 로깅 후 버림 (프로시저와 동일) |

---

## 8. Phase 2 (향후)

> Phase 1 완료 후 진행. 상세 계획은 Phase 1 안정화 후 수립.

### 개요
- **목표**: 새 시스템 추가 시 최소 코드 변경
- **변경 범위**: DB 구조 변경 (통합 임시 테이블)
- **전제 조건**: Phase 1 안정화 완료

### 주요 작업
1. 통합 임시 테이블 DDL 설계 (x01_if_event_unified)
2. Webhook API 구현 (EventWebhookController)
3. 기존 Worker 마이그레이션 (통합 테이블 사용)
4. 기존 임시 테이블 제거

---

## 참고 문서

- 기존 프로시저: `DDML/p_combine_event_zabbix_.sql`, `DDML/p_combine_event_zenius.sql`

---

**최종 업데이트**: 2026-01-30
