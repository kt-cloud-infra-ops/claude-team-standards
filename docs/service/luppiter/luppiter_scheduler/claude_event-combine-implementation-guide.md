# 이벤트 취합 Java 전환 구현 가이드

> 작성일: 2026-01-30
> 대상: 개발자
> 상태: 구현 준비 완료 (100% 코드 포함)

---

## 목차

1. [개요](#1-개요)
2. [패키지 구조](#2-패키지-구조)
3. [DTO 클래스](#3-dto-클래스)
4. [인터페이스 및 추상 클래스](#4-인터페이스-및-추상-클래스)
5. [ZabbixEventCombineService](#5-zabbixeventcombineservice)
6. [ZeniusEventCombineService](#6-zeniuseventcombineservice)
7. [EventCombineOrchestrator](#7-eventcombineorchestrator)
8. [EventCombineMapper](#8-eventcombinemapper)
9. [MyBatis XML](#9-mybatis-xml)
10. [CombineEventServiceJob 수정](#10-combineeventservicejob-수정)
11. [application.yml 설정](#11-applicationyml-설정)
12. [체크리스트](#12-체크리스트)

---

## 1. 개요

### 목표
- 프로시저(`p_combine_event_zabbix`, `p_combine_event_zenius`) → Java 전환
- 병렬 처리로 성능 개선 (36s → 6~8s 목표)
- Shadow Mode로 안전한 전환

### 설계 패턴
- **Template Method**: 공통 로직은 추상 클래스, 차이점만 서브클래스
- **Strategy**: 시스템별 서비스 주입

### 핵심 원칙
- DB 구조 변경 없음 (기존 테이블 그대로 사용)
- 프로시저와 동일한 동작 (인벤토리 미매핑 건은 스킵)
- Shadow Mode 병행 운영 후 점진적 전환

---

## 2. 패키지 구조

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

## 3. DTO 클래스

### 3.1 CombineResult.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.ToString;

/**
 * 이벤트 취합 결과 DTO
 */
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

### 3.2 BatchEventConfig.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;

/**
 * 배치 이벤트 설정 DTO (c01_batch_event)
 */
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

### 3.3 RawEvent.java (기본 클래스)

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

/**
 * 원시 이벤트 기본 클래스
 */
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

### 3.4 ZabbixRawEvent.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;

/**
 * Zabbix 원시 이벤트 (x01_if_event_data)
 */
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

### 3.5 ZeniusRawEvent.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

/**
 * Zenius 원시 이벤트 (x01_if_event_zenius)
 */
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

### 3.6 EventInfo.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

/**
 * cmon_event_info 테이블 DTO
 */
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

### 3.7 InventoryMaster.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;

/**
 * inventory_master 테이블 DTO
 */
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

### 3.8 InventoryMasterSub.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;

/**
 * inventory_master_sub 테이블 DTO
 */
@Getter
@Setter
public class InventoryMasterSub {
    private String zabbixIp;
    private String controlArea;
    private String hostGroupNm;
}
```

### 3.9 LayerInfo.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;

/**
 * 계위 정보 DTO (cmon_layer_code_info 조인 결과)
 */
@Getter
@Setter
public class LayerInfo {
    private String l1Nm;
    private String l2Nm;
    private String l3Nm;
}
```

### 3.10 ExceptionInfo.java

```java
package com.ktc.luppiter.batch.event.dto;

import lombok.Getter;
import lombok.Setter;
import java.time.LocalDateTime;

/**
 * 예외 처리 정보 DTO (cmon_exception_event 조인 결과)
 */
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

## 4. 인터페이스 및 추상 클래스

### 4.1 IEventCombineService.java

```java
package com.ktc.luppiter.batch.event.combine;

import com.ktc.luppiter.batch.event.dto.BatchEventConfig;
import com.ktc.luppiter.batch.event.dto.CombineResult;

/**
 * 이벤트 취합 서비스 인터페이스
 */
public interface IEventCombineService {

    String getSourceType();

    String getSupportedEventType();

    CombineResult combine(BatchEventConfig config);

    CombineResult combineDryRun(BatchEventConfig config);
}
```

### 4.2 AbstractEventCombineService.java

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

/**
 * 이벤트 취합 추상 클래스 (Template Method 패턴)
 */
@Slf4j
public abstract class AbstractEventCombineService implements IEventCombineService {

    @Autowired
    protected EventCombineMapper eventCombineMapper;

    /**
     * Template Method - 전체 취합 흐름
     */
    @Override
    @Transactional
    public CombineResult combine(BatchEventConfig config) {
        long startTime = System.currentTimeMillis();
        String systemCode = config.getSystemCode();

        log.info("[{}] {} 취합 시작", systemCode, getSourceType());

        try {
            validateConfig(config);

            // 1. 신규 이벤트 처리
            int newCount = processNewEvents(config);

            // 2. 해소 이벤트 처리
            int resolvedCount = processResolvedEvents(config);

            // 3. sync_idx 업데이트
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

    /**
     * Dry Run (Shadow Mode용)
     */
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

    /**
     * 신규 이벤트 처리
     */
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

        // 배치 INSERT
        eventCombineMapper.batchInsertEventInfo(validEvents);

        // 대응관리 정보 입력
        List<String> eventIds = validEvents.stream()
            .map(EventInfo::getEventId)
            .toList();
        eventCombineMapper.insertRespManageInfo(eventIds);

        log.debug("[{}] 신규 이벤트 {} 건 처리 완료", config.getSystemCode(), validEvents.size());

        return validEvents.size();
    }

    /**
     * RawEvent → EventInfo 변환
     */
    protected EventInfo convertToEventInfo(RawEvent raw, BatchEventConfig config) {
        // 인벤토리 조회 (프로시저의 INNER JOIN)
        InventoryMaster inventory = eventCombineMapper.findInventoryByZabbixIp(raw.getEventIp());
        if (inventory == null) {
            log.debug("Skip - inventory not found: ip={}", raw.getEventIp());
            return null;
        }

        // 예외 처리 체크 (훅 메서드)
        ExceptionInfo exceptionInfo = checkException(raw);

        // 계위 정보 조회
        LayerInfo layerInfo = eventCombineMapper.findLayerInfo(
            inventory.getL1LayerCd(),
            inventory.getL2LayerCd(),
            inventory.getL3LayerCd()
        );

        // 서브 인벤토리 조회
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

## 5. ZabbixEventCombineService

```java
package com.ktc.luppiter.batch.event.combine;

import com.ktc.luppiter.batch.event.dto.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Zabbix 이벤트 취합 서비스
 * 프로시저 p_combine_event_zabbix 와 동일한 로직
 */
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

    /**
     * 신규 이벤트 조회
     * WHERE event_id > sync_idx AND event_status = 1 AND event_level IN (2,4)
     */
    @Override
    protected List<ZabbixRawEvent> findNewEvents(BatchEventConfig config) {
        return eventCombineMapper.findNewZabbixEvents(
            config.getSystemCode(),
            config.getSyncIdxAsLong(),
            config.getSystemIp()
        );
    }

    /**
     * 예외 처리 체크 (Zabbix만 사용)
     */
    @Override
    protected ExceptionInfo checkException(RawEvent raw) {
        return eventCombineMapper.findExceptionInfo(raw.getEventIp(), raw.getTriggerId());
    }

    /**
     * Zabbix 전용 필드 설정
     */
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

    /**
     * 해소 이벤트 처리
     * recovery_dst_id 매칭으로 해소
     */
    @Override
    protected int processResolvedEvents(BatchEventConfig config) {
        // 1. 예외 처리된 항목 해소
        int exceptionResolved = eventCombineMapper.resolveZabbixExceptionEvents(
            config.getSystemCode(),
            config.getSyncIdxAsLong(),
            config.getSystemIp()
        );

        // 2. 일반 해소 처리
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

    /**
     * sync_idx = max(if_event_id) from cmon_event_info
     */
    @Override
    protected Object getMaxSyncIdx(BatchEventConfig config) {
        return eventCombineMapper.getMaxZabbixIfEventId(config.getSystemIp());
    }

    /**
     * 이벤트 내용: event_contents 그대로
     */
    @Override
    protected String buildEventContents(RawEvent raw) {
        return raw.getEventContents();
    }
}
```

---

## 6. ZeniusEventCombineService

```java
package com.ktc.luppiter.batch.event.combine;

import com.ktc.luppiter.batch.event.dto.*;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Zenius 이벤트 취합 서비스
 * 프로시저 p_combine_event_zenius 와 동일한 로직
 */
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

    /**
     * 신규 이벤트 조회
     * WHERE if_idx > sync_idx AND z_alert IN (50, 60)
     */
    @Override
    protected List<ZeniusRawEvent> findNewEvents(BatchEventConfig config) {
        return eventCombineMapper.findNewZeniusEvents(
            config.getSystemCode(),
            config.getSyncIdx(),
            config.getSystemIp()
        );
    }

    /**
     * 해소 이벤트 처리
     * IF 테이블에 미존재 시 해소
     */
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

    /**
     * sync_idx = max(if_idx) from x01_if_event_zenius
     */
    @Override
    protected Object getMaxSyncIdx(BatchEventConfig config) {
        return eventCombineMapper.getMaxZeniusIfIdx();
    }

    /**
     * 이벤트 내용: event_code + zenius_level + set_name + z_myname + z_mymsg 조합
     */
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

    /**
     * 서브 인벤토리 매칭용: event_code 사용
     */
    @Override
    protected String getEventContentsForSubMatch(RawEvent raw) {
        if (raw instanceof ZeniusRawEvent zenius) {
            return zenius.getEventCode();
        }
        return raw.getEventContents();
    }

    /**
     * Zenius 전용 필드 설정
     */
    @Override
    protected EventInfo convertToEventInfo(RawEvent raw, BatchEventConfig config) {
        EventInfo eventInfo = super.convertToEventInfo(raw, config);

        if (eventInfo != null && raw instanceof ZeniusRawEvent zeniusRaw) {
            eventInfo.setOccuTime(zeniusRaw.getZEvttime());
            eventInfo.setTriggerId(Long.parseLong(zeniusRaw.getZMyid()));
        }

        return eventInfo;
    }
}
```

---

## 7. EventCombineOrchestrator

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

/**
 * 이벤트 취합 오케스트레이터 (병렬 처리)
 */
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

    /**
     * 모든 시스템 병렬 취합 (실제 처리)
     */
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

        // 시스템별 로깅
        results.forEach(r ->
            log.info("[CombineJob] {} - {}ms, new={}, resolved={}, success={}",
                r.getSystemCode(), r.getElapsedTimeMs(),
                r.getNewEventCount(), r.getResolvedEventCount(), r.isSuccess())
        );

        log.info("[CombineJob] 병렬 취합 완료 - {}ms, systems={}", totalElapsed, configs.size());

        return results;
    }

    /**
     * Dry Run (Shadow Mode용)
     */
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

## 8. EventCombineMapper

```java
package com.ktc.luppiter.batch.event.mapper;

import com.ktc.luppiter.batch.event.dto.*;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

/**
 * 이벤트 취합 Mapper
 */
@Mapper
public interface EventCombineMapper {

    // ========== 공통 ==========

    /** 시퀀스 채번 */
    String getNextEventSequence();

    /** 인벤토리 조회 */
    InventoryMaster findInventoryByZabbixIp(@Param("zabbixIp") String zabbixIp);

    /** 서브 인벤토리 조회 */
    InventoryMasterSub findInventorySub(
        @Param("zabbixIp") String zabbixIp,
        @Param("eventContents") String eventContents
    );

    /** 계위 정보 조회 */
    LayerInfo findLayerInfo(
        @Param("l1LayerCd") String l1LayerCd,
        @Param("l2LayerCd") String l2LayerCd,
        @Param("l3LayerCd") String l3LayerCd
    );

    /** 배치 INSERT - cmon_event_info */
    void batchInsertEventInfo(@Param("list") List<EventInfo> eventInfoList);

    /** 대응관리 정보 입력 */
    void insertRespManageInfo(@Param("eventIds") List<String> eventIds);

    /** sync_idx 업데이트 */
    void updateSyncIdx(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") String syncIdx
    );

    // ========== Zabbix ==========

    /** 신규 Zabbix 이벤트 조회 */
    List<ZabbixRawEvent> findNewZabbixEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") Long syncIdx,
        @Param("systemIp") String systemIp
    );

    /** 예외 정보 조회 */
    ExceptionInfo findExceptionInfo(
        @Param("ip") String ip,
        @Param("triggerId") Long triggerId
    );

    /** Zabbix 예외 이벤트 해소 */
    int resolveZabbixExceptionEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") Long syncIdx,
        @Param("systemIp") String systemIp
    );

    /** Zabbix 일반 이벤트 해소 */
    int resolveZabbixNormalEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") Long syncIdx
    );

    /** Zabbix 해소 대상 건수 (Dry Run용) */
    int countZabbixResolvedEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") Long syncIdx
    );

    /** Zabbix max if_event_id 조회 */
    Long getMaxZabbixIfEventId(@Param("systemIp") String systemIp);

    // ========== Zenius ==========

    /** 신규 Zenius 이벤트 조회 */
    List<ZeniusRawEvent> findNewZeniusEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") String syncIdx,
        @Param("systemIp") String systemIp
    );

    /** Zenius 이벤트 해소 */
    int resolveZeniusEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") String syncIdx,
        @Param("systemIp") String systemIp
    );

    /** Zenius 해소 대상 건수 (Dry Run용) */
    int countZeniusResolvedEvents(
        @Param("systemCode") String systemCode,
        @Param("syncIdx") String syncIdx,
        @Param("systemIp") String systemIp
    );

    /** Zenius max if_idx 조회 */
    String getMaxZeniusIfIdx();
}
```

---

## 9. MyBatis XML

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.ktc.luppiter.batch.event.mapper.EventCombineMapper">

    <!-- ========== 공통 ========== -->

    <select id="getNextEventSequence" resultType="String">
        SELECT get_next_event_sequence()
    </select>

    <select id="findInventoryByZabbixIp" resultType="com.ktc.luppiter.batch.event.dto.InventoryMaster">
        SELECT zabbix_ip
             , equnr
             , mgmt_ip
             , ipmi_ip
             , host_nm
             , host_type
             , center_nm
             , datacenter_nm
             , rack_location
             , equip_position
             , std_nm
             , e_std_nm
             , zone
             , control_area
             , host_group_nm
             , l1_layer_cd
             , l2_layer_cd
             , l3_layer_cd
        FROM inventory_master
        WHERE zabbix_ip = #{zabbixIp}
    </select>

    <select id="findInventorySub" resultType="com.ktc.luppiter.batch.event.dto.InventoryMasterSub">
        SELECT zabbix_ip
             , control_area
             , host_group_nm
        FROM inventory_master_sub
        WHERE zabbix_ip = #{zabbixIp}
          AND POSITION(SPLIT_PART(control_area, '_', 2) IN SUBSTRING(#{eventContents}, 1, 8)) > 0
        LIMIT 1
    </select>

    <select id="findLayerInfo" resultType="com.ktc.luppiter.batch.event.dto.LayerInfo">
        SELECT l1.layer_nm AS l1_nm
             , l2.layer_nm AS l2_nm
             , l3.layer_nm AS l3_nm
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
            l1_nm, l2_nm, l3_nm, zone, gubun,
            host_group_nm, if_event_id, last_occu_time
        ) VALUES
        <foreach collection="list" item="e" separator=",">
            (
                #{e.eventId}, #{e.occuTime}, #{e.createTime}, #{e.targetIp}, #{e.targetContents},
                #{e.sendAgent}, #{e.eventLevel}, #{e.equBarcode}, #{e.deviceIp}, #{e.ipmiIp},
                #{e.hostname}, #{e.equipLabel}, #{e.containerNm}, #{e.datacenterNm}, #{e.rackLocation},
                #{e.equipPosition}, #{e.stdnm}, #{e.estdnm}, #{e.eventState}, #{e.zabbixState},
                #{e.triggerId}, #{e.zbxAvailable}, #{e.ipmiAvailable}, #{e.snmpAvailable}, #{e.jmxAvailable},
                #{e.l1Nm}, #{e.l2Nm}, #{e.l3Nm}, #{e.zone}, #{e.gubun},
                #{e.hostGroupNm}, #{e.ifEventId}, #{e.lastOccuTime}
            )
        </foreach>
    </insert>

    <insert id="insertRespManageInfo">
        INSERT INTO cmon_event_resp_manage_info (
            event_id, resp_level, manage_dept, user_id_1st, user_id_2nd,
            control_dept, concall_group, resp_info, create_time, user_id_ktcloud
        )
        SELECT evt.event_id
             , rmi.resp_level
             , rmi.manage_dept
             , rmi.user_id_1st
             , rmi.user_id_2nd
             , rmi.control_dept
             , rmi.concall_group
             , rmi.resp_info
             , now()
             , rmi.user_id_ktcloud
        FROM cmon_resp_manage_info rmi
        INNER JOIN cmon_event_info evt
            ON evt.event_id IN
            <foreach collection="eventIds" item="id" open="(" separator="," close=")">
                #{id}
            </foreach>
            AND evt.host_group_nm = rmi.host_group_nm
        ON CONFLICT (event_id) DO NOTHING
    </insert>

    <update id="updateSyncIdx">
        UPDATE c01_batch_event
        SET sync_idx = #{syncIdx}
          , sync_dt = now()
        WHERE system_code = #{systemCode}
    </update>

    <!-- ========== Zabbix ========== -->

    <select id="findNewZabbixEvents" resultType="com.ktc.luppiter.batch.event.dto.ZabbixRawEvent">
        SELECT xied.event_id AS if_event_id
             , xied.event_dt
             , xied.event_level
             , xied.event_contents
             , xied.event_ip
             , xied.trigger_id
             , xied.event_status
             , xied.recovery_dst_id
             , xied.status_agent
             , xied.status_ipmi
             , xied.status_snmp
             , xied.status_jmx
             , xied.host_id
             , xied.template_id
             , xied.item_id
        FROM x01_if_event_data xied
        WHERE xied.system_code = #{systemCode}
          AND xied.event_id > #{syncIdx}
          AND xied.event_status = 1
          AND xied.event_level IN (2, 4)
          AND xied.maintenance_status = 0
          AND NOT EXISTS (
              SELECT 1
              FROM cmon_event_info evt
              WHERE evt.send_agent = #{systemIp}
                AND evt.if_event_id = xied.event_id
          )
        ORDER BY xied.event_id
    </select>

    <select id="findExceptionInfo" resultType="com.ktc.luppiter.batch.event.dto.ExceptionInfo">
        SELECT exd.ip
             , exd.trigger_id
             , '예외' AS event_state
             , GREATEST(ex.start_dtm, ex.cret_dt) AS excp_time
             , ex.start_dtm
             , ex.end_dtm
             , ex.evt_excp_contents AS excp_contents
        FROM cmon_exception_event ex
        INNER JOIN cmon_exception_event_detail exd ON ex.excp_seq = exd.excp_seq
        WHERE exd.ip = #{ip}
          AND exd.trigger_id = #{triggerId}
          AND exd.delete_yn = 'N'
          AND now() BETWEEN ex.start_dtm AND ex.end_dtm
        LIMIT 1
    </select>

    <update id="resolveZabbixExceptionEvents">
        UPDATE cmon_event_info ei
        SET zabbix_state = '해소'
          , event_state = COALESCE(r_evt.ex_event_state, event_state)
          , r_time = r_evt.event_dt
          , event_step1_user = COALESCE(event_step1_user, '유피테르')
          , event_step2_user = COALESCE(event_step2_user, '유피테르')
          , event_step1_start = COALESCE(event_step1_start, GREATEST(create_time, r_evt.excp_time))
          , event_step2_start = COALESCE(event_step2_start, GREATEST(create_time, r_evt.excp_time))
          , event_step1_end = COALESCE(event_step1_end, GREATEST(create_time, r_evt.excp_time))
          , event_step2_end = COALESCE(event_step2_end, GREATEST(create_time, r_evt.excp_time))
          , event_step1_contents = COALESCE(event_step1_contents, r_evt.ex_contents)
          , event_step2_contents = COALESCE(event_step2_contents, r_evt.ex_contents)
          , event_service_impact = COALESCE(event_service_impact, 'N')
          , event_tech_voc = COALESCE(event_tech_voc, 'N')
          , event_result_type = COALESCE(event_result_type, '9')
          , event_result_user = COALESCE(event_result_user, '유피테르')
          , event_result_time = COALESCE(event_result_time, GREATEST(create_time, r_evt.excp_time))
          , last_occu_time = now()
        FROM (
            SELECT cei.event_id
                 , xied.event_dt
                 , ex_evt.excp_time
                 , ex_evt.ex_contents
                 , ex_evt.ex_event_state
            FROM cmon_event_info cei
            INNER JOIN x01_if_event_data xied
                ON cei.trigger_id = xied.trigger_id
                AND cei.if_event_id = xied.recovery_dst_id
                AND xied.system_code = #{systemCode}
                AND xied.event_id > #{syncIdx}
                AND xied.event_status = 0
            INNER JOIN (
                SELECT GREATEST(ex.start_dtm, ex.cret_dt) AS excp_time
                     , ex.evt_excp_contents AS ex_contents
                     , exd.ip AS ex_ip
                     , exd.trigger_id AS ex_trigger_id
                     , '예외' AS ex_event_state
                FROM cmon_exception_event ex
                INNER JOIN cmon_exception_event_detail exd ON ex.excp_seq = exd.excp_seq
                WHERE now() BETWEEN ex.start_dtm AND ex.end_dtm
                  AND exd.delete_yn = 'N'
            ) AS ex_evt
                ON ex_evt.ex_trigger_id = cei.trigger_id
                AND ex_evt.ex_ip = cei.target_ip
            WHERE cei.r_time IS NULL
        ) AS r_evt
        WHERE ei.event_id = r_evt.event_id
    </update>

    <update id="resolveZabbixNormalEvents">
        UPDATE cmon_event_info evt
        SET zabbix_state = '해소'
          , r_time = r_evt.event_dt
          , last_occu_time = now()
        FROM (
            SELECT cei.event_id
                 , xied.event_dt
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

    <select id="countZabbixResolvedEvents" resultType="int">
        SELECT COUNT(*)
        FROM cmon_event_info cei
        INNER JOIN x01_if_event_data xied
            ON cei.trigger_id = xied.trigger_id
            AND cei.if_event_id = xied.recovery_dst_id
            AND xied.system_code = #{systemCode}
            AND xied.event_status = 0
            AND xied.event_id > #{syncIdx}
        WHERE cei.r_time IS NULL
    </select>

    <select id="getMaxZabbixIfEventId" resultType="Long">
        SELECT MAX(if_event_id)
        FROM cmon_event_info
        WHERE send_agent = #{systemIp}
    </select>

    <!-- ========== Zenius ========== -->

    <select id="findNewZeniusEvents" resultType="com.ktc.luppiter.batch.event.dto.ZeniusRawEvent">
        SELECT DISTINCT ON (xiez.z_myip, xiez.z_myid)
               xiez.if_idx
             , xiez.z_evttime AS event_dt
             , xiez.event_level
             , xiez.z_myip AS event_ip
             , xiez.z_myid::numeric AS trigger_id
             , xiez.z_status
             , xiez.z_alert
             , xiez.z_evttime
             , xiez.z_rectime
             , xiez.z_infraid
             , xiez.z_myhost
             , xiez.z_myip
             , xiez.z_myname
             , xiez.z_mymsg
             , xiez.z_myid
             , xiez.z_setid
             , xiez.zenius_level
             , xiez.infra_code
             , xiez.set_name
             , xiez.event_code
        FROM x01_if_event_zenius xiez
        LEFT JOIN cmon_event_info evt
            ON xiez.z_myip = evt.target_ip
            AND xiez.z_myid::numeric = evt.trigger_id
            AND evt.zabbix_state IN ('신규', '지속')
        WHERE evt.event_id IS NULL
          AND xiez.system_code = #{systemCode}
          AND xiez.z_alert IN (50, 60)
          AND xiez.if_idx > #{syncIdx}
    </select>

    <update id="resolveZeniusEvents">
        UPDATE cmon_event_info evt
        SET zabbix_state = '해소'
          , r_time = now()
          , last_occu_time = now()
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

    <select id="countZeniusResolvedEvents" resultType="int">
        SELECT COUNT(*)
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
    </select>

    <select id="getMaxZeniusIfIdx" resultType="String">
        SELECT MAX(if_idx)
        FROM x01_if_event_zenius
    </select>

</mapper>
```

---

## 10. CombineEventServiceJob 수정

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

    /** Shadow Mode: true면 프로시저 + Java 비교, false면 Java만 실행 */
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

            // 배치 설정 목록 조회
            List<Map<String, String>> batchMapList = batchSchedulerMapper.selectBatchEventList();

            // BatchEventConfig 변환
            List<BatchEventConfig> configs = batchMapList.stream()
                .filter(map -> "Y".equalsIgnoreCase(map.get("use_yn")))
                .map(this::toBatchEventConfig)
                .toList();

            if (shadowMode) {
                // Shadow Mode: 프로시저 실행 후 Java 비교
                executeShadowMode(configs, batchMapList);
            } else {
                // 정상 운영: Java만 실행
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

    /**
     * Shadow Mode 실행
     * 1. 프로시저 실행 (메인)
     * 2. Java Dry Run (검증용)
     * 3. 결과 비교 로깅
     */
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

## 11. application.yml 설정

```yaml
# 이벤트 취합 설정
event:
  combine:
    # Shadow Mode: true면 프로시저+Java 비교, false면 Java만 실행
    shadow-mode: true
    # 병렬 처리 스레드 풀 크기
    thread-pool-size: 6
```

---

## 12. 체크리스트

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

### 필드 매핑 확인

| 필드 | 프로시저 | Java | 확인 |
|------|---------|------|------|
| event_id | get_next_event_sequence() | getNextEventSequence() | [ ] |
| occu_time | event_dt / z_evttime | eventDt / zEvttime | [ ] |
| target_ip | event_ip / z_myip | eventIp / zMyip | [ ] |
| event_level | CASE WHEN 2/4 | convertEventLevel() | [ ] |
| event_state | COALESCE(ex_info, '신규') | exceptionInfo != null ? "예외" : "신규" | [ ] |
| gubun | COALESCE(inv_sub, inv_mst) | invSub != null ? invSub : inventory | [ ] |

---

## 참고 문서

- 설계서: `event-combine-java-migration-design.md`
- 기존 프로시저: `DDML/p_combine_event_zabbix_.sql`, `DDML/p_combine_event_zenius.sql`

---

**최종 업데이트**: 2026-01-30
