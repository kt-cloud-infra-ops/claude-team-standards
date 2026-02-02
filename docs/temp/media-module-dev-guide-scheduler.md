# [luppiter_scheduler] 알림 발송 클라이언트 개발 가이드

## 문서 정보
- 작성일: 2026-01-23
- 프로젝트: luppiter_scheduler
- 역할: **메시지 발송 요청 클라이언트** (luppiter_web으로 발송 요청)

---

## 1. 개요

### 1.1 역할 분담

| 프로젝트 | 역할 |
|----------|------|
| luppiter_web | 메시지 발송 서버 (SMS, Email, Slack 처리) |
| **luppiter_scheduler** | 메시지 발송 요청 클라이언트 (본 문서) |

### 1.2 변경 사항

| 변경 전 | 변경 후 |
|---------|---------|
| scheduler에서 직접 SMS/Email/Slack 발송 | web API 호출로 발송 요청 |
| 각 Worker에 발송 로직 포함 | 공통 클라이언트로 통합 |

### 1.3 장점

- **발송 로직 일원화**: web에서만 관리
- **매체 추가/제거 용이**: scheduler 수정 불필요
- **설정 일원화**: web의 시스템 설정만 변경

---

## 2. 패키지 구조

```
com.ktc.luppiter.scheduler/
├── common/
│   └── client/
│       └── MessageClient.java          # 메시지 발송 클라이언트 (신규)
├── worker/
│   ├── EventAlarmWorker.java           # 이벤트 알람 (수정)
│   ├── MaintenanceAlarmWorker.java     # 메인터넌스 알람 (수정)
│   ├── ExceptionEventWorker.java       # 예외 이벤트 (수정)
│   └── ...
└── config/
    └── RestTemplateConfiguration.java  # RestTemplate 설정 (신규)
```

---

## 3. 상세 구현

### 3.1 RestTemplateConfiguration (신규)

```java
package com.ktc.luppiter.scheduler.config;

import org.springframework.boot.web.client.RestTemplateBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.client.RestTemplate;

import java.time.Duration;

@Configuration
public class RestTemplateConfiguration {

    @Bean
    public RestTemplate restTemplate(RestTemplateBuilder builder) {
        return builder
            .setConnectTimeout(Duration.ofSeconds(5))
            .setReadTimeout(Duration.ofSeconds(30))
            .build();
    }
}
```

### 3.2 MessageClient (신규)

```java
package com.ktc.luppiter.scheduler.common.client;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

import javax.annotation.PostConstruct;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Component
public class MessageClient {

    private static final Logger logger = LoggerFactory.getLogger(MessageClient.class);

    private final RestTemplate restTemplate;

    @Value("${luppiter.web.url:http://localhost:8080}")
    private String webBaseUrl;

    private String messageApiUrl;

    public MessageClient(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    @PostConstruct
    public void init() {
        this.messageApiUrl = webBaseUrl + "/media/request";
        logger.info("MessageClient initialized: url={}", messageApiUrl);
    }

    /**
     * 메시지 발송 요청
     *
     * @param templateCode 템플릿 코드 (LOGIN_OTP, EVENT_ALARM, ...)
     * @param title        메시지 제목 (nullable)
     * @param targetList   발송 대상 목록 (전화번호, 이메일 등)
     * @param params       템플릿 파라미터
     * @return 성공 여부
     */
    public boolean send(String templateCode, String title,
                        List<String> targetList, Map<String, Object> params) {

        String url = messageApiUrl + "/" + templateCode;

        try {
            // 요청 본문 생성
            Map<String, Object> requestBody = new HashMap<>();
            if (title != null) {
                requestBody.put("title", title);
            }
            requestBody.put("target_list", targetList);
            requestBody.put("params", params);

            // HTTP 헤더 설정
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(requestBody, headers);

            // API 호출
            logger.info("Sending message request: template={}, targets={}",
                templateCode, targetList.size());

            ResponseEntity<Map> response = restTemplate.exchange(
                url, HttpMethod.POST, entity, Map.class);

            // 응답 처리
            if (response.getStatusCode() == HttpStatus.OK) {
                Map<String, Object> body = response.getBody();
                String resultCode = body != null ? (String) body.get("resultCode") : null;

                if ("200".equals(resultCode)) {
                    logger.info("Message sent successfully: template={}", templateCode);
                    return true;
                } else {
                    logger.warn("Message send failed: template={}, response={}",
                        templateCode, body);
                    return false;
                }
            } else {
                logger.error("Message API error: template={}, status={}",
                    templateCode, response.getStatusCode());
                return false;
            }

        } catch (RestClientException e) {
            logger.error("Message API call failed: template={}, error={}",
                templateCode, e.getMessage(), e);
            return false;
        }
    }

    /**
     * 이벤트 알람 발송
     */
    public boolean sendEventAlarm(List<String> targetList, Map<String, Object> eventParams) {
        return send("EVENT_ALARM", null, targetList, eventParams);
    }

    /**
     * 메인터넌스 알람 발송
     */
    public boolean sendMaintenanceAlert(String title, List<String> targetList,
                                         Map<String, Object> params) {
        return send("MAINTENANCE_ALERT", title, targetList, params);
    }

    /**
     * 예외 이벤트 알람 발송
     */
    public boolean sendExceptionEvent(List<String> targetList, Map<String, Object> params) {
        return send("EVENT_EXCEPTION", null, targetList, params);
    }

    /**
     * 관제수용 알람 발송
     */
    public boolean sendHostRegister(String title, List<String> targetList,
                                     Map<String, Object> params) {
        return send("HOST_REGISTER", title, targetList, params);
    }
}
```

### 3.3 application.yml 설정 추가

```yaml
# application.yml
luppiter:
  web:
    url: http://luppiter-web:8080  # luppiter_web 서버 URL

# 또는 환경별 설정
---
spring:
  config:
    activate:
      on-profile: local

luppiter:
  web:
    url: http://localhost:8080

---
spring:
  config:
    activate:
      on-profile: dev

luppiter:
  web:
    url: http://dev-luppiter-web:8080

---
spring:
  config:
    activate:
      on-profile: prod

luppiter:
  web:
    url: http://prod-luppiter-web:8080
```

---

## 4. Worker 수정 예시

### 4.1 EventAlarmWorker (수정 전)

```java
// 수정 전: 직접 SMS 발송
@Service
public class EventAlarmWorker {

    private final SmsService smsService;
    private final SlackService slackService;

    public void process(EventInfo event) {
        // SMS 발송
        smsService.send(event.getPhoneNumbers(), event.getMessage());

        // Slack 발송
        slackService.send(event.getSlackChannels(), event.getMessage());
    }
}
```

### 4.2 EventAlarmWorker (수정 후)

```java
// 수정 후: MessageClient 사용
@Service
public class EventAlarmWorker {

    private static final Logger logger = LoggerFactory.getLogger(EventAlarmWorker.class);

    private final MessageClient messageClient;
    private final EventAlarmMapper eventAlarmMapper;

    public EventAlarmWorker(MessageClient messageClient,
                            EventAlarmMapper eventAlarmMapper) {
        this.messageClient = messageClient;
        this.eventAlarmMapper = eventAlarmMapper;
    }

    public void process(EventInfo event) {
        // 발송 대상 조회
        List<String> targetList = eventAlarmMapper.selectAlarmTargets(event.getEventId());

        if (targetList.isEmpty()) {
            logger.debug("No alarm targets for event: {}", event.getEventId());
            return;
        }

        // 파라미터 구성
        Map<String, Object> params = new HashMap<>();
        params.put("EVENT_ID", event.getEventId());
        params.put("EVENT_TITLE", event.getEventTitle());
        params.put("EVENT_LEVEL", event.getEventLevel());
        params.put("EVENT_OCCU_DT", event.getOccuTime());
        params.put("HOST_NAME", event.getHostName());
        params.put("HOST_TCP_IP", event.getTcpIp());
        // ... 기타 파라미터

        // luppiter_web으로 발송 요청
        boolean success = messageClient.sendEventAlarm(targetList, params);

        if (success) {
            logger.info("Event alarm sent: eventId={}", event.getEventId());
        } else {
            logger.error("Event alarm failed: eventId={}", event.getEventId());
        }
    }
}
```

### 4.3 MaintenanceAlarmWorker (수정 후)

```java
@Service
public class MaintenanceAlarmWorker {

    private final MessageClient messageClient;
    private final MaintenanceMapper maintenanceMapper;

    public void process(MaintenanceInfo maintenance) {
        List<String> targetList = maintenanceMapper.selectAlarmTargets(maintenance.getSeq());

        if (targetList.isEmpty()) {
            return;
        }

        Map<String, Object> params = new HashMap<>();
        params.put("STATUS", maintenance.getStatus());
        params.put("NAME", maintenance.getName());
        params.put("START_DT", maintenance.getStartDt());
        params.put("END_DT", maintenance.getEndDt());
        params.put("REASON", maintenance.getReason());
        params.put("REG_USER", maintenance.getRegUser());
        // ... 호스트 목록 등

        String title = "[메인터넌스] " + maintenance.getName();

        messageClient.sendMaintenanceAlert(title, targetList, params);
    }
}
```

### 4.4 ExceptionEventWorker (수정 후)

```java
@Service
public class ExceptionEventWorker {

    private final MessageClient messageClient;
    private final ExceptionEventMapper exceptionEventMapper;

    public void process(ExceptionEvent exception) {
        List<String> targetList = exceptionEventMapper.selectAlarmTargets(exception.getExcpSeq());

        if (targetList.isEmpty()) {
            return;
        }

        Map<String, Object> params = new HashMap<>();
        params.put("STATUS", exception.getStatus());
        params.put("TITLE", exception.getTitle());
        params.put("EXCEPTION_ID", exception.getExcpSeq());

        messageClient.sendExceptionEvent(targetList, params);
    }
}
```

---

## 5. 기존 코드 정리

### 5.1 삭제 대상

scheduler에서 더 이상 필요 없는 클래스:

| 클래스 | 설명 | 처리 |
|--------|------|------|
| SmsService | SMS 직접 발송 | 삭제 |
| SlackService | Slack 직접 발송 | 삭제 |
| EmailService | Email 직접 발송 | 삭제 |
| MessageTemplate | 템플릿 관리 | 삭제 (web으로 이관) |

### 5.2 삭제 전 확인

```bash
# 사용 여부 확인
grep -r "SmsService" src/
grep -r "SlackService" src/
grep -r "EmailService" src/
```

### 5.3 단계별 이관

1. **Phase 1**: MessageClient 추가, Worker에서 병행 사용
2. **Phase 2**: 기존 Service 호출을 MessageClient로 교체
3. **Phase 3**: 기존 Service 클래스 삭제

---

## 6. 에러 처리

### 6.1 재시도 로직 (선택)

```java
@Component
public class MessageClient {

    private static final int MAX_RETRY = 3;
    private static final long RETRY_DELAY_MS = 1000;

    public boolean sendWithRetry(String templateCode, String title,
                                  List<String> targetList, Map<String, Object> params) {

        for (int attempt = 1; attempt <= MAX_RETRY; attempt++) {
            try {
                boolean success = send(templateCode, title, targetList, params);
                if (success) {
                    return true;
                }

                if (attempt < MAX_RETRY) {
                    logger.warn("Retry {}/{}: template={}", attempt, MAX_RETRY, templateCode);
                    Thread.sleep(RETRY_DELAY_MS * attempt);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                break;
            }
        }

        logger.error("All retries failed: template={}", templateCode);
        return false;
    }
}
```

### 6.2 Fallback 처리 (선택)

```java
public boolean send(String templateCode, String title,
                    List<String> targetList, Map<String, Object> params) {
    try {
        // ... API 호출
    } catch (RestClientException e) {
        logger.error("API call failed, saving to fallback queue: {}", e.getMessage());

        // DB에 실패 건 저장 (나중에 재시도)
        saveFallbackMessage(templateCode, title, targetList, params);
        return false;
    }
}
```

---

## 7. 테스트

### 7.1 MessageClient 단위 테스트

```java
package com.ktc.luppiter.scheduler.common.client;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.*;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.web.client.RestClientException;
import org.springframework.web.client.RestTemplate;

/**
 * MessageClient 단위 테스트
 *
 * <h3>테스트 전략</h3>
 * <ul>
 *   <li>RestTemplate은 Mock으로 처리하여 외부 API 호출 없이 클라이언트 로직만 테스트</li>
 *   <li>각 템플릿 코드별 발송 메서드 테스트</li>
 *   <li>에러 처리 및 재시도 로직 검증</li>
 *   <li>Given-When-Then 패턴을 사용하여 테스트 가독성 향상</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("MessageClient 단위 테스트")
class MessageClientTest {

    private static final Logger log = LoggerFactory.getLogger(MessageClientTest.class);

    @Mock
    private RestTemplate restTemplate;

    private MessageClient messageClient;

    @BeforeEach
    void setUp() {
        messageClient = new MessageClient(restTemplate);
        ReflectionTestUtils.setField(messageClient, "webBaseUrl", "http://localhost:8080");
        messageClient.init();
    }

    @Nested
    @DisplayName("send 메서드 테스트")
    class SendTest {

        @Test
        @DisplayName("정상 케이스 - 메시지 발송 성공")
        void send_Success() {
            log.info("=== 테스트 시작: send - 메시지 발송 성공 ===");

            // Given: API 호출 성공 응답 설정
            Map<String, Object> responseBody = new HashMap<>();
            responseBody.put("resultCode", "200");
            responseBody.put("message", "Message sent to all enabled channels");
            ResponseEntity<Map> response = ResponseEntity.ok(responseBody);

            when(restTemplate.exchange(
                anyString(), eq(HttpMethod.POST), any(HttpEntity.class), eq(Map.class))
            ).thenReturn(response);

            log.info("Given: API 성공 응답 설정");

            // When: 메시지 발송
            log.info("When: send() 메서드 실행");
            boolean result = messageClient.send(
                "EVENT_ALARM",
                "테스트 제목",
                List.of("010-1234-5678"),
                Map.of("EVENT_ID", "EVT001"));

            // Then: 성공 검증
            log.info("Then: 발송 성공 검증");
            assertThat(result)
                .as("발송 성공 시 true 반환")
                .isTrue();

            verify(restTemplate, times(1)).exchange(
                anyString(), eq(HttpMethod.POST), any(HttpEntity.class), eq(Map.class));

            log.info("=== 테스트 완료: send - 발송 성공 확인 ===");
        }

        @Test
        @DisplayName("실패 케이스 - API 응답 코드 실패")
        void send_ApiResponseFail() {
            log.info("=== 테스트 시작: send - API 응답 실패 ===");

            // Given: API 실패 응답 설정
            Map<String, Object> responseBody = new HashMap<>();
            responseBody.put("resultCode", "500");
            responseBody.put("message", "Internal Server Error");
            ResponseEntity<Map> response = ResponseEntity.ok(responseBody);

            when(restTemplate.exchange(
                anyString(), eq(HttpMethod.POST), any(HttpEntity.class), eq(Map.class))
            ).thenReturn(response);

            log.info("Given: API 실패 응답(resultCode=500) 설정");

            // When: 메시지 발송
            log.info("When: send() 메서드 실행");
            boolean result = messageClient.send(
                "EVENT_ALARM", null, List.of("010-1234-5678"), Map.of("EVENT_ID", "EVT001"));

            // Then: 실패 검증
            log.info("Then: 발송 실패 검증");
            assertThat(result)
                .as("API 응답 실패 시 false 반환")
                .isFalse();

            log.info("=== 테스트 완료: send - API 응답 실패 확인 ===");
        }

        @Test
        @DisplayName("실패 케이스 - RestClientException 발생")
        void send_RestClientException() {
            log.info("=== 테스트 시작: send - RestClientException 발생 ===");

            // Given: RestClientException 발생 설정
            when(restTemplate.exchange(
                anyString(), eq(HttpMethod.POST), any(HttpEntity.class), eq(Map.class))
            ).thenThrow(new RestClientException("Connection refused"));

            log.info("Given: RestClientException 발생 설정");

            // When: 메시지 발송
            log.info("When: send() 메서드 실행");
            boolean result = messageClient.send(
                "EVENT_ALARM", null, List.of("010-1234-5678"), Map.of("EVENT_ID", "EVT001"));

            // Then: 예외 처리 및 false 반환 검증
            log.info("Then: 예외 처리 후 false 반환 검증");
            assertThat(result)
                .as("RestClientException 발생 시 false 반환")
                .isFalse();

            log.info("=== 테스트 완료: send - RestClientException 처리 확인 ===");
        }

        @Test
        @DisplayName("실패 케이스 - HTTP 상태 코드 에러")
        void send_HttpStatusError() {
            log.info("=== 테스트 시작: send - HTTP 상태 코드 에러 ===");

            // Given: HTTP 500 응답 설정
            ResponseEntity<Map> response = ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(null);

            when(restTemplate.exchange(
                anyString(), eq(HttpMethod.POST), any(HttpEntity.class), eq(Map.class))
            ).thenReturn(response);

            log.info("Given: HTTP 500 응답 설정");

            // When: 메시지 발송
            log.info("When: send() 메서드 실행");
            boolean result = messageClient.send(
                "EVENT_ALARM", null, List.of("010-1234-5678"), Map.of());

            // Then: 실패 검증
            log.info("Then: HTTP 에러 처리 검증");
            assertThat(result)
                .as("HTTP 500 응답 시 false 반환")
                .isFalse();

            log.info("=== 테스트 완료: send - HTTP 상태 에러 처리 확인 ===");
        }

        @Test
        @DisplayName("정상 케이스 - title이 null인 경우")
        void send_NullTitle_Success() {
            log.info("=== 테스트 시작: send - title null 처리 ===");

            // Given: title 없이 성공 응답
            Map<String, Object> responseBody = Map.of("resultCode", "200");
            ResponseEntity<Map> response = ResponseEntity.ok(responseBody);

            when(restTemplate.exchange(
                anyString(), eq(HttpMethod.POST), any(HttpEntity.class), eq(Map.class))
            ).thenReturn(response);

            log.info("Given: title=null 요청 준비");

            // When: title 없이 발송
            log.info("When: send(templateCode, null, targetList, params) 실행");
            boolean result = messageClient.send(
                "LOGIN_OTP",
                null,  // title이 null
                List.of("010-1234-5678"),
                Map.of("OTP_VALUE", "123456"));

            // Then: 성공 검증
            log.info("Then: title null도 정상 처리 검증");
            assertThat(result).isTrue();

            log.info("=== 테스트 완료: send - title null 정상 처리 확인 ===");
        }
    }

    @Nested
    @DisplayName("편의 메서드 테스트")
    class ConvenienceMethodsTest {

        @Test
        @DisplayName("sendEventAlarm - 이벤트 알람 발송")
        void sendEventAlarm_Success() {
            log.info("=== 테스트 시작: sendEventAlarm - 이벤트 알람 발송 ===");

            // Given
            Map<String, Object> responseBody = Map.of("resultCode", "200");
            ResponseEntity<Map> response = ResponseEntity.ok(responseBody);

            when(restTemplate.exchange(
                contains("/media/request/EVENT_ALARM"),
                eq(HttpMethod.POST),
                any(HttpEntity.class),
                eq(Map.class))
            ).thenReturn(response);

            log.info("Given: EVENT_ALARM API 성공 응답 설정");

            // When
            log.info("When: sendEventAlarm() 실행");
            boolean result = messageClient.sendEventAlarm(
                List.of("010-1234-5678"),
                Map.of(
                    "EVENT_ID", "EVT001",
                    "EVENT_TITLE", "테스트 이벤트",
                    "EVENT_LEVEL", "L1"
                )
            );

            // Then
            log.info("Then: 이벤트 알람 발송 성공 검증");
            assertThat(result).isTrue();

            log.info("=== 테스트 완료: sendEventAlarm - 발송 성공 확인 ===");
        }

        @Test
        @DisplayName("sendMaintenanceAlert - 메인터넌스 알림 발송")
        void sendMaintenanceAlert_Success() {
            log.info("=== 테스트 시작: sendMaintenanceAlert - 메인터넌스 알림 발송 ===");

            // Given
            Map<String, Object> responseBody = Map.of("resultCode", "200");
            ResponseEntity<Map> response = ResponseEntity.ok(responseBody);

            when(restTemplate.exchange(
                contains("/media/request/MAINTENANCE_ALERT"),
                eq(HttpMethod.POST),
                any(HttpEntity.class),
                eq(Map.class))
            ).thenReturn(response);

            log.info("Given: MAINTENANCE_ALERT API 성공 응답 설정");

            // When
            log.info("When: sendMaintenanceAlert() 실행");
            boolean result = messageClient.sendMaintenanceAlert(
                "[메인터넌스] 정기점검",
                List.of("010-1234-5678"),
                Map.of(
                    "NAME", "정기점검",
                    "START_DT", "2026-01-24 00:00",
                    "END_DT", "2026-01-24 06:00"
                )
            );

            // Then
            log.info("Then: 메인터넌스 알림 발송 성공 검증");
            assertThat(result).isTrue();

            log.info("=== 테스트 완료: sendMaintenanceAlert - 발송 성공 확인 ===");
        }

        @Test
        @DisplayName("sendExceptionEvent - 예외 이벤트 발송")
        void sendExceptionEvent_Success() {
            log.info("=== 테스트 시작: sendExceptionEvent - 예외 이벤트 발송 ===");

            // Given
            Map<String, Object> responseBody = Map.of("resultCode", "200");
            ResponseEntity<Map> response = ResponseEntity.ok(responseBody);

            when(restTemplate.exchange(
                contains("/media/request/EVENT_EXCEPTION"),
                eq(HttpMethod.POST),
                any(HttpEntity.class),
                eq(Map.class))
            ).thenReturn(response);

            log.info("Given: EVENT_EXCEPTION API 성공 응답 설정");

            // When
            log.info("When: sendExceptionEvent() 실행");
            boolean result = messageClient.sendExceptionEvent(
                List.of("010-1234-5678"),
                Map.of(
                    "STATUS", "등록",
                    "TITLE", "예외 처리",
                    "EXCEPTION_ID", "EXC001"
                )
            );

            // Then
            log.info("Then: 예외 이벤트 발송 성공 검증");
            assertThat(result).isTrue();

            log.info("=== 테스트 완료: sendExceptionEvent - 발송 성공 확인 ===");
        }
    }

    @Nested
    @DisplayName("파라미터 검증 테스트")
    class ParameterValidationTest {

        @Test
        @DisplayName("빈 target_list 처리")
        void send_EmptyTargetList() {
            log.info("=== 테스트 시작: send - 빈 target_list 처리 ===");

            // Given
            Map<String, Object> responseBody = Map.of("resultCode", "200");
            ResponseEntity<Map> response = ResponseEntity.ok(responseBody);

            when(restTemplate.exchange(
                anyString(), eq(HttpMethod.POST), any(HttpEntity.class), eq(Map.class))
            ).thenReturn(response);

            log.info("Given: 빈 target_list 요청");

            // When
            log.info("When: send() 실행 (빈 target_list)");
            boolean result = messageClient.send(
                "EVENT_ALARM", null, List.of(), Map.of("EVENT_ID", "EVT001"));

            // Then - 빈 리스트도 정상 처리 (web에서 처리)
            log.info("Then: 빈 target_list 정상 처리 검증");
            assertThat(result).isTrue();
            verify(restTemplate, times(1)).exchange(
                anyString(), eq(HttpMethod.POST), any(HttpEntity.class), eq(Map.class));

            log.info("=== 테스트 완료: send - 빈 target_list 처리 확인 ===");
        }

        @Test
        @DisplayName("빈 params 처리")
        void send_EmptyParams() {
            log.info("=== 테스트 시작: send - 빈 params 처리 ===");

            // Given
            Map<String, Object> responseBody = Map.of("resultCode", "200");
            ResponseEntity<Map> response = ResponseEntity.ok(responseBody);

            when(restTemplate.exchange(
                anyString(), eq(HttpMethod.POST), any(HttpEntity.class), eq(Map.class))
            ).thenReturn(response);

            log.info("Given: 빈 params 요청");

            // When
            log.info("When: send() 실행 (빈 params)");
            boolean result = messageClient.send(
                "EVENT_ALARM", null, List.of("010-1234-5678"), Map.of());

            // Then
            log.info("Then: 빈 params 정상 처리 검증");
            assertThat(result).isTrue();

            log.info("=== 테스트 완료: send - 빈 params 처리 확인 ===");
        }
    }
}
```

### 7.2 EventAlarmWorker 단위 테스트

```java
package com.ktc.luppiter.scheduler.worker;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.ktc.luppiter.scheduler.common.client.MessageClient;
import com.ktc.luppiter.scheduler.mapper.EventAlarmMapper;

/**
 * EventAlarmWorker 단위 테스트
 *
 * <h3>테스트 전략</h3>
 * <ul>
 *   <li>MessageClient와 Mapper는 Mock으로 처리</li>
 *   <li>Worker 비즈니스 로직 검증 (발송 대상 조회 → 메시지 발송)</li>
 *   <li>빈 대상 목록, 발송 실패 시 동작 검증</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("EventAlarmWorker 단위 테스트")
class EventAlarmWorkerTest {

    private static final Logger log = LoggerFactory.getLogger(EventAlarmWorkerTest.class);

    @Mock
    private MessageClient messageClient;

    @Mock
    private EventAlarmMapper eventAlarmMapper;

    @InjectMocks
    private EventAlarmWorker eventAlarmWorker;

    @Nested
    @DisplayName("process 메서드 테스트")
    class ProcessTest {

        @Test
        @DisplayName("정상 케이스 - 이벤트 알람 발송 성공")
        void process_Success() {
            log.info("=== 테스트 시작: process - 이벤트 알람 발송 성공 ===");

            // Given: 발송 대상 있음, 발송 성공
            EventInfo event = createTestEvent("EVT001");

            when(eventAlarmMapper.selectAlarmTargets("EVT001"))
                .thenReturn(List.of("010-1234-5678", "010-8765-4321"));
            when(messageClient.sendEventAlarm(anyList(), anyMap()))
                .thenReturn(true);

            log.info("Given: 이벤트 ID=EVT001, 발송 대상 2명");

            // When: 이벤트 처리
            log.info("When: process() 실행");
            eventAlarmWorker.process(event);

            // Then: MessageClient 호출 검증
            log.info("Then: MessageClient.sendEventAlarm() 호출 검증");
            verify(messageClient, times(1)).sendEventAlarm(
                eq(List.of("010-1234-5678", "010-8765-4321")),
                argThat(params ->
                    "EVT001".equals(params.get("EVENT_ID")) &&
                    "테스트 이벤트".equals(params.get("EVENT_TITLE"))
                )
            );

            log.info("=== 테스트 완료: process - 발송 성공 확인 ===");
        }

        @Test
        @DisplayName("빈 결과 - 발송 대상 없음")
        void process_NoTargets_NoSend() {
            log.info("=== 테스트 시작: process - 발송 대상 없음 ===");

            // Given: 발송 대상 없음
            EventInfo event = createTestEvent("EVT002");

            when(eventAlarmMapper.selectAlarmTargets("EVT002"))
                .thenReturn(List.of());

            log.info("Given: 이벤트 ID=EVT002, 발송 대상 없음");

            // When: 이벤트 처리
            log.info("When: process() 실행");
            eventAlarmWorker.process(event);

            // Then: MessageClient 호출되지 않음
            log.info("Then: MessageClient 미호출 검증");
            verify(messageClient, never()).sendEventAlarm(anyList(), anyMap());

            log.info("=== 테스트 완료: process - 발송 스킵 확인 ===");
        }

        @Test
        @DisplayName("실패 케이스 - 메시지 발송 실패")
        void process_SendFailed_LogError() {
            log.info("=== 테스트 시작: process - 메시지 발송 실패 ===");

            // Given: 발송 대상 있음, 발송 실패
            EventInfo event = createTestEvent("EVT003");

            when(eventAlarmMapper.selectAlarmTargets("EVT003"))
                .thenReturn(List.of("010-1234-5678"));
            when(messageClient.sendEventAlarm(anyList(), anyMap()))
                .thenReturn(false);

            log.info("Given: 이벤트 ID=EVT003, MessageClient 발송 실패 설정");

            // When: 이벤트 처리
            log.info("When: process() 실행");
            eventAlarmWorker.process(event);

            // Then: MessageClient 호출됨 (실패해도 예외 발생 안함)
            log.info("Then: MessageClient 호출 및 에러 로깅 확인");
            verify(messageClient, times(1)).sendEventAlarm(anyList(), anyMap());

            log.info("=== 테스트 완료: process - 발송 실패 처리 확인 ===");
        }
    }

    /**
     * 테스트용 EventInfo 생성
     */
    private EventInfo createTestEvent(String eventId) {
        EventInfo event = new EventInfo();
        event.setEventId(eventId);
        event.setEventTitle("테스트 이벤트");
        event.setEventLevel("L1");
        event.setOccuTime("2026-01-23 10:00:00");
        event.setHostName("test-host");
        event.setTcpIp("10.2.14.100");
        return event;
    }
}
```

### 7.3 통합 테스트

```java
package com.ktc.luppiter.scheduler.common.client;

import static org.assertj.core.api.Assertions.*;

import java.util.List;
import java.util.Map;

import org.junit.jupiter.api.Disabled;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;

/**
 * MessageClient 통합 테스트
 *
 * <h3>테스트 전략</h3>
 * <ul>
 *   <li>실제 luppiter_web 서버와 통신 테스트</li>
 *   <li>로컬/개발 환경에서만 실행 (@Disabled)</li>
 *   <li>각 템플릿별 발송 테스트</li>
 * </ul>
 */
@SpringBootTest
@ActiveProfiles("test")
@DisplayName("MessageClient 통합 테스트")
class MessageClientIntegrationTest {

    private static final Logger log = LoggerFactory.getLogger(MessageClientIntegrationTest.class);

    @Autowired
    private MessageClient messageClient;

    @Test
    @DisplayName("이벤트 알람 발송 - 실제 API 호출")
    @Disabled("실제 서버 필요 - 로컬 테스트 시 활성화")
    void sendEventAlarm_Integration() {
        log.info("=== 통합 테스트 시작: 이벤트 알람 발송 ===");

        // When: 실제 API 호출
        boolean result = messageClient.sendEventAlarm(
            List.of("010-1234-5678"),
            Map.of(
                "EVENT_ID", "TEST-001",
                "EVENT_TITLE", "통합 테스트 이벤트",
                "EVENT_LEVEL", "L1",
                "HOST_NAME", "test-host",
                "HOST_TCP_IP", "10.2.14.100"
            )
        );

        // Then: 발송 성공 검증
        assertThat(result)
            .as("이벤트 알람 발송 성공")
            .isTrue();

        log.info("=== 통합 테스트 완료: 이벤트 알람 발송 성공 ===");
    }

    @Test
    @DisplayName("메인터넌스 알림 발송 - 실제 API 호출")
    @Disabled("실제 서버 필요 - 로컬 테스트 시 활성화")
    void sendMaintenanceAlert_Integration() {
        log.info("=== 통합 테스트 시작: 메인터넌스 알림 발송 ===");

        // When: 실제 API 호출
        boolean result = messageClient.sendMaintenanceAlert(
            "[메인터넌스] 통합 테스트",
            List.of("010-1234-5678"),
            Map.of(
                "NAME", "통합 테스트 점검",
                "START_DT", "2026-01-24 00:00",
                "END_DT", "2026-01-24 06:00",
                "STATUS", "등록"
            )
        );

        // Then: 발송 성공 검증
        assertThat(result)
            .as("메인터넌스 알림 발송 성공")
            .isTrue();

        log.info("=== 통합 테스트 완료: 메인터넌스 알림 발송 성공 ===");
    }

    @Test
    @DisplayName("예외 이벤트 발송 - 실제 API 호출")
    @Disabled("실제 서버 필요 - 로컬 테스트 시 활성화")
    void sendExceptionEvent_Integration() {
        log.info("=== 통합 테스트 시작: 예외 이벤트 발송 ===");

        // When: 실제 API 호출
        boolean result = messageClient.sendExceptionEvent(
            List.of("010-1234-5678"),
            Map.of(
                "STATUS", "등록",
                "TITLE", "통합 테스트 예외 처리",
                "EXCEPTION_ID", "EXC-TEST-001"
            )
        );

        // Then: 발송 성공 검증
        assertThat(result)
            .as("예외 이벤트 발송 성공")
            .isTrue();

        log.info("=== 통합 테스트 완료: 예외 이벤트 발송 성공 ===");
    }
}

---

## 8. 구현 체크리스트

### 8.1 신규 추가

- [ ] RestTemplateConfiguration 생성
- [ ] MessageClient 생성
- [ ] application.yml에 luppiter.web.url 설정 추가

### 8.2 Worker 수정

- [ ] EventAlarmWorker - MessageClient 사용으로 변경
- [ ] MaintenanceAlarmWorker - MessageClient 사용으로 변경
- [ ] ExceptionEventWorker - MessageClient 사용으로 변경
- [ ] HostRegisterWorker - MessageClient 사용으로 변경 (있는 경우)

### 8.3 기존 코드 정리

- [ ] SmsService 삭제
- [ ] SlackService 삭제
- [ ] EmailService 삭제
- [ ] 관련 Mapper/Config 정리

### 8.4 테스트 구현

- [ ] MessageClientTest - send() 메서드 단위 테스트
- [ ] MessageClientTest - 편의 메서드 테스트 (sendEventAlarm 등)
- [ ] MessageClientTest - 파라미터 검증 테스트
- [ ] EventAlarmWorkerTest - process() 정상 케이스
- [ ] EventAlarmWorkerTest - 발송 대상 없음 케이스
- [ ] MaintenanceAlarmWorkerTest - 단위 테스트
- [ ] ExceptionEventWorkerTest - 단위 테스트
- [ ] MessageClientIntegrationTest - 통합 테스트 (실서버 연동)

---

## 9. 배포 순서

1. **luppiter_web 먼저 배포**: 메시지 API 준비
2. **luppiter_scheduler 배포**: MessageClient 사용
3. **검증**: 발송 로그 확인
4. **정리**: scheduler 기존 발송 코드 삭제
