# Observability 연동 - 구현 가이드

> 작성일: 2026-01-20
> 기준: luppiter_web 기존 패턴 준수

---

## 목차

1. [프로젝트 구조](#1-프로젝트-구조)
2. [코딩 패턴](#2-코딩-패턴)
3. [기능별 구현 상세](#3-기능별-구현-상세)
   - 3.1 서비스/플랫폼 등록
   - 3.2 관제 대상 삭제 (탭 분리)
   - 3.3 예외 관리 (타입 선택 팝업)
   - 3.4 메인터넌스 관리 (타입 선택 팝업)
4. [API 엔드포인트 목록](#4-api-엔드포인트-목록)
5. [체크리스트](#5-체크리스트)

---

## 1. 프로젝트 구조

### 1.1 신규 파일 구조

```
src/main/java/com/ktc/luppiter/web/
├── controller/
│   └── ObsController.java                    # O11y 관련 컨트롤러 (신규)
├── service/
│   ├── ObsService.java                       # 인터페이스 (신규)
│   └── impl/
│       └── ObsServiceImpl.java               # 구현체 (신규)
├── mapper/
│   └── ObsMapper.java                        # 매퍼 인터페이스 (신규)
└── ...

src/main/resources/sqlmap/
└── sql-obs.xml                               # SQL 매핑 (신규)

src/main/webapp/WEB-INF/jsp/
└── obs/
    ├── serviceInventory.jsp                  # 서비스/플랫폼 등록 화면 (신규)
    ├── serviceInventoryPopup.jsp             # 등록 팝업 (신규)
    └── ...
```

### 1.2 기존 파일 수정

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

## 2. 코딩 패턴

### 2.1 Controller 패턴

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

### 2.2 Service 패턴

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

### 2.3 Mapper 패턴

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

### 2.4 SQL 매핑 패턴

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

## 3. 기능별 구현 상세

### 3.1 서비스/플랫폼 등록 (신규)

#### 3.1.1 화면 구성

| 구성요소 | 파일 | 비고 |
|---------|------|------|
| 메인 화면 | obs/serviceInventory.jsp | 목록 + 검색 |
| 등록 팝업 | obs/serviceInventoryPopup.jsp | 신규 등록 |
| 상세 팝업 | obs/serviceInventoryDetail.jsp | 조회/수정 |

#### 3.1.2 API 목록

| API | Method | Endpoint | 설명 |
|-----|--------|----------|------|
| 목록 조회 | POST | /api/obs/service/list | 페이징 포함 |
| 상세 조회 | POST | /api/obs/service/detail | 단건 조회 |
| 등록 | POST | /api/obs/service/save | 신규 등록 |
| 수정 | POST | /api/obs/service/update | 정보 수정 |
| 삭제 | POST | /api/obs/service/delete | 삭제 (use_yn='N') |

#### 3.1.3 입력 항목

| 항목 | 필드명 | 타입 | 필수 | 비고 |
|------|--------|------|------|------|
| 서비스 타입 | serviceType | String | Y | 'SERVICE' / 'PLATFORM' |
| 서비스명 | serviceNm | String | Y | |
| Namespace | namespace | String | Y | |
| 리전 | region | String | Y | 예: DX-G-SE |
| L1 (분류) | l1LayerCd | String | Y | 계위 코드 |
| L2 (도메인) | l2LayerCd | String | Y | 계위 코드 |
| L3 (표준서비스) | l3LayerCd | String | Y | 계위 코드 |
| Zone (L4) | zone | String | Y | |

#### 3.1.4 처리 로직

```
[등록 버튼 클릭]
    │
    ▼
[Validation]
  ├─ 필수값 체크
  └─ 중복 체크 (serviceNm + region)
    │
    ▼
[DB 저장]
  ├─ cmon_service_inventory_master INSERT
  └─ 호스트그룹 자동생성 (cmon_group_layer INSERT)
    │
    ▼
[응답 반환]
```

---

### 3.2 관제 대상 삭제 (탭 분리)

#### 3.2.1 화면 변경

**기존**: deleteHosts.jsp (Zabbix만)

**변경**: 탭 추가
- Tab 1: Zabbix (기존)
- Tab 2: Zenius (신규)
- Tab 3: Observability (신규)

#### 3.2.2 탭별 처리 로직

| 탭 | 장비 조회 | 삭제 처리 |
|----|----------|----------|
| Zabbix | inventory_master | DB 저장 + Zabbix API 삭제 |
| Zenius | inventory_master | DB 저장만 |
| O11y | cmon_service_inventory_master | DB 저장만 |

#### 3.2.3 API 추가/수정

| API | Method | Endpoint | 변경사항 |
|-----|--------|----------|---------|
| 삭제 처리 | POST | /api/mng/hostsMng/remove | monitorType 파라미터 추가 |

#### 3.2.4 파라미터 추가

```java
// 기존
map.put("requestType", "DEL");

// 변경 (monitorType 추가)
map.put("requestType", "DEL");
map.put("monitorType", "ZABBIX");  // ZABBIX / ZENIUS / O11Y
```

#### 3.2.5 Service 로직 수정

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

### 3.3 예외 관리 (타입 선택 팝업)

#### 3.3.1 화면 변경

**기존**: subEventExcpState.jsp (Infra만)

**변경**: 타입 선택 버튼 + 팝업 방식
- 버튼 클릭 시 팝업 표시
- 팝업 옵션:
  - Infra (Zabbix, Zenius, Observability)
  - Service (Observability)
  - Platform (Observability)
- 선택한 타입에 따라 컬럼 표시 분기

#### 3.3.2 탭별 조회 테이블

| 탭 | 장비 대상 조회 | 이벤트 목록 조회 | 저장 테이블 |
|----|--------------|-----------------|------------|
| Infra | inventory_master | Zabbix API (trigger) | cmon_exception_event_detail |
| Service | cmon_service_inventory_master | 인벤토리 + O11y API | cmon_exception_service_detail |
| Platform | cmon_service_inventory_master | 인벤토리 + O11y API | cmon_exception_service_detail |

#### 3.3.3 API 추가

| API | Method | Endpoint | 설명 |
|-----|--------|----------|------|
| 서비스 장비 조회 | POST | /api/evt/comm/serviceDeviceList | Service/Platform용 |
| 서비스 이벤트 조회 | POST | /api/evt/comm/serviceEventList | O11y API 연동 |
| 서비스 예외 등록 | POST | /api/evt/excp/saveService | Service/Platform용 |

#### 3.3.4 신규 Mapper 쿼리

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

### 3.4 메인터넌스 관리 (타입 선택 팝업)

#### 3.4.1 화면 변경

**기존**: subMaintenanceState.jsp (Infra만)

**변경**: 타입 선택 버튼 + 팝업 방식
- 버튼 클릭 시 팝업 표시
- 팝업 옵션:
  - Infra (Zabbix, Observability) - Zenius 미지원
  - Service (Observability)
  - Platform (Observability)
- 선택한 타입에 따라 컬럼 표시 분기

> **주의**: Zenius는 메인터넌스 미지원 (팝업 내 안내 문구 표시)

#### 3.4.2 탭별 API 연동

| 탭 | 메인터넌스 API |
|----|---------------|
| Infra (Zabbix) | Zabbix API 실제 중단 |
| Infra (O11y) | O11y API 실제 중단 |
| Service | O11y API 실제 중단 |
| Platform | O11y API 실제 중단 |

#### 3.4.3 API 추가

| API | Method | Endpoint | 설명 |
|-----|--------|----------|------|
| 서비스 메인터넌스 등록 | POST | /api/evt/maint/saveService | Service/Platform용 |
| O11y 메인터넌스 API 호출 | - | ObsApiService | 외부 API 연동 |

#### 3.4.4 O11y API 연동 서비스

```java
@Slf4j
@Service
public class ObsApiService {

    @Value("${obs.api.url}")
    private String obsApiUrl;

    @Value("${obs.api.timeout:30000}")
    private int timeout;

    /**
     * O11y 메인터넌스 등록
     */
    public Map<String, Object> createMaintenance(Map<String, Object> params) throws Exception {
        log.info("[O11y API] 메인터넌스 등록 요청: {}", params);

        // TODO: O11y API 스펙 확인 후 구현
        String endpoint = obsApiUrl + "/api/v1/maintenance";

        // API 호출 로직
        // ...

        return result;
    }

    /**
     * O11y 메인터넌스 해제
     */
    public Map<String, Object> deleteMaintenance(Map<String, Object> params) throws Exception {
        log.info("[O11y API] 메인터넌스 해제 요청: {}", params);

        // TODO: O11y API 스펙 확인 후 구현

        return result;
    }
}
```

---

## 4. API 엔드포인트 목록

### 4.1 신규 API

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

### 4.2 수정 API

| 기능 | Method | Endpoint | 변경사항 |
|------|--------|----------|---------|
| 관제삭제 | POST | /api/mng/hostsMng/remove | monitorType 파라미터 추가 |
| 예외 등록 | POST | /api/evt/excp/save | eventType 파라미터 추가 |
| 메인터넌스 등록 | POST | /api/evt/maint/save | eventType 파라미터 추가 |

---

## 5. 체크리스트

### 5.1 공통

- [ ] WebControllerHelper 상속
- [ ] super.setInit() 호출
- [ ] super.setResFail() 에러 처리
- [ ] @Transactional 적용 (CUD 작업)
- [ ] Logger 로깅 (시작/완료/에러)
- [ ] Map<String, Object> 파라미터 사용

### 5.2 서비스/플랫폼 등록

- [ ] ObsController.java 생성
- [ ] ObsService.java 인터페이스 생성
- [ ] ObsServiceImpl.java 구현체 생성
- [ ] ObsMapper.java 매퍼 생성
- [ ] sql-obs.xml SQL 매핑 생성
- [ ] serviceInventory.jsp 화면 생성
- [ ] serviceInventoryPopup.jsp 팝업 생성
- [ ] 호스트그룹 자동생성 로직

### 5.3 관제 대상 삭제

- [ ] deleteHosts.jsp 탭 추가
- [ ] monitorType 파라미터 처리
- [ ] Zenius/O11y 삭제 로직 (DB만)
- [ ] 삭제 테이블 분기 처리

### 5.4 예외 관리

- [ ] subEventExcpState.jsp 타입 선택 버튼/팝업 추가
- [ ] 타입별 컬럼 표시 분기 처리
- [ ] cmon_exception_service_detail 테이블 사용
- [ ] 서비스 장비 조회 API
- [ ] O11y 이벤트 조회 API

### 5.5 메인터넌스 관리

- [ ] subMaintenanceState.jsp 타입 선택 버튼/팝업 추가
- [ ] 타입별 컬럼 표시 분기 처리
- [ ] cmon_maintenance_service_detail 테이블 사용
- [ ] O11y API 연동 서비스
- [ ] Zenius 미지원 안내 문구

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
