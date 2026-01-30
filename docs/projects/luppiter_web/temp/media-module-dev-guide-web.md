# [luppiter_web] 알림 발송 모듈 개발 가이드

## 문서 정보
- 작성일: 2026-01-23
- 프로젝트: luppiter_web
- 패키지: `com.ktc.luppiter.external.media`
- 역할: **메시지 발송 서버** (SMS, Email, Slack 발송 처리)

---

## 1. 개요

### 1.1 역할 분담

| 프로젝트 | 역할 |
|----------|------|
| **luppiter_web** | 메시지 발송 서버 (본 문서) |
| luppiter_scheduler | 메시지 발송 요청 클라이언트 |

### 1.2 핵심 요구사항

| 항목 | 설명 |
|------|------|
| **기본 동작** | 메시지 발송 시 모든 활성화된 매체(SMS, Slack, Email)로 동시 발송 |
| **매체별 ON/OFF** | 시스템 설정에서 각 매체를 독립적으로 ON/OFF 가능 |
| **느슨한 결합** | 특정 매체를 OFF하거나 코드를 제거해도 다른 매체에 영향 없음 |

### 1.3 동작 시나리오

```
[OTP 인증 발송 요청]

시스템 설정:
- media.sms.use = Y
- media.slack.use = Y
- media.email.use = N

결과:
- SMS → 발송 ✅
- Slack → 발송 ✅
- Email → 스킵 ⏭️ (비활성화)
```

---

## 2. 패키지 구조

### 2.1 변경 후 구조

```
com.ktc.luppiter.external.media/
├── controller/
│   └── MessageController.java          # REST API 엔드포인트
├── rest/
│   └── RestClientService.java          # 외부 API 호출 클라이언트
├── service/
│   ├── MessageChannel.java             # Enum (EMAIL, SMS, SLACK)
│   ├── MessageRequest.java             # 요청 DTO
│   ├── MessageSender.java              # Interface
│   ├── MessageService.java             # 서비스 레이어
│   ├── MessageSenderFacade.java        # Facade (채널별 라우팅)
│   ├── AbstractMessageSender.java      # 공통 로직 추상 클래스
│   └── impl/
│       ├── EmailSender.java
│       ├── SmsSender.java
│       └── SlackSender.java
└── template/
    ├── Template.java
    ├── TemplateCode.java               # Enum (템플릿 코드)
    ├── TemplateManager.java
    ├── TemplateRepository.java
    ├── EmailTemplates.java
    ├── SMSTemplates.java
    └── SlackTemplates.java
```

---

## 3. 상세 구현

### 3.1 MessageSender 인터페이스

```java
package com.ktc.luppiter.external.media.service;

public interface MessageSender {

    /**
     * 채널 타입 반환
     */
    MessageChannel getChannel();

    /**
     * 활성화 여부 반환
     */
    boolean isEnabled();

    /**
     * 메시지 발송
     */
    void send(MessageRequest request) throws Exception;
}
```

### 3.2 AbstractMessageSender (신규)

```java
package com.ktc.luppiter.external.media.service;

import com.ktc.luppiter.external.media.rest.RestClientService;
import com.ktc.luppiter.external.media.template.TemplateManager;
import com.ktc.luppiter.external.media.template.TemplateRepository;
import com.ktc.luppiter.web.common.service.CommonService;
import com.ktc.luppiter.web.util.CryptoUtil;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;
import java.util.Map;

public abstract class AbstractMessageSender implements MessageSender {

    protected final Logger logger = LoggerFactory.getLogger(getClass());

    protected final RestClientService restClientService;
    protected final TemplateManager templateManager;
    protected final CommonService commonService;
    protected final CryptoUtil cryptoUtil;

    protected String url;
    protected boolean enabled;

    protected AbstractMessageSender(
            TemplateRepository templates,
            RestClientService restClientService,
            CommonService commonService,
            CryptoUtil cryptoUtil) {
        this.templateManager = new TemplateManager(templates);
        this.restClientService = restClientService;
        this.commonService = commonService;
        this.cryptoUtil = cryptoUtil;
    }

    @Override
    public boolean isEnabled() {
        return enabled;
    }

    /**
     * 시스템 설정 로드
     */
    protected void loadConfig(String urlKey, String useKey) {
        try {
            List<Map<String, Object>> configs =
                commonService.getSystemPropertiesList("SYSTEM_CONFIG");

            this.url = getConfigValue(configs, urlKey, "");
            this.enabled = "Y".equalsIgnoreCase(getConfigValue(configs, useKey, "N"));

            logger.info("[{}] Config loaded - url: {}, enabled: {}",
                getChannel(), url, enabled);

        } catch (Exception e) {
            logger.error("[{}] Failed to load config: {}", getChannel(), e.getMessage());
            this.enabled = false;
        }
    }

    private String getConfigValue(List<Map<String, Object>> configs,
                                   String key, String defaultValue) {
        return configs.stream()
            .filter(m -> key.equals(m.get("prop_key")))
            .map(m -> String.valueOf(m.get("prop_val")))
            .findFirst()
            .orElse(defaultValue);
    }

    /**
     * 발송 대상 복호화
     */
    protected List<String> decryptTargetList(List<String> targetList) {
        List<String> decrypted = new java.util.ArrayList<>(targetList);
        decrypted.replaceAll(cryptoUtil::decrypt);
        return decrypted;
    }
}
```

### 3.3 MessageRequest

```java
package com.ktc.luppiter.external.media.service;

import com.ktc.luppiter.external.media.template.TemplateCode;
import lombok.Data;

import java.util.List;
import java.util.Map;

@Data
public class MessageRequest {

    private TemplateCode templateCode;
    private String title;
    private List<String> targetList;
    private Map<String, Object> params;

}
```

### 3.4 MessageSenderFacade

```java
package com.ktc.luppiter.external.media.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.EnumMap;
import java.util.List;
import java.util.Map;

@Service
public class MessageSenderFacade {

    private static final Logger logger = LoggerFactory.getLogger(MessageSenderFacade.class);

    private final Map<MessageChannel, MessageSender> senders;

    public MessageSenderFacade(List<MessageSender> senderList) {
        this.senders = new EnumMap<>(MessageChannel.class);
        senderList.forEach(sender -> {
            senders.put(sender.getChannel(), sender);
            logger.info("Registered MessageSender: {} (enabled: {})",
                sender.getChannel(), sender.isEnabled());
        });
    }

    /**
     * 모든 활성화된 채널로 발송
     */
    public void sendAll(MessageRequest request) {
        logger.info("Sending message to all enabled channels: template={}",
            request.getTemplateCode());

        int successCount = 0;
        int failCount = 0;
        int skipCount = 0;

        for (MessageSender sender : senders.values()) {
            MessageChannel channel = sender.getChannel();

            if (!sender.isEnabled()) {
                logger.debug("Channel {} is disabled, skipping", channel);
                skipCount++;
                continue;
            }

            try {
                sender.send(request);
                logger.info("Message sent successfully via {}", channel);
                successCount++;
            } catch (Exception e) {
                logger.error("Failed to send via {}: {}", channel, e.getMessage(), e);
                failCount++;
            }
        }

        logger.info("Send complete: success={}, fail={}, skip={}",
            successCount, failCount, skipCount);
    }

    /**
     * 특정 채널로만 발송
     */
    public void send(MessageChannel channel, MessageRequest request) {
        MessageSender sender = senders.get(channel);

        if (sender == null) {
            logger.warn("No sender registered for channel: {}", channel);
            return;
        }

        if (!sender.isEnabled()) {
            logger.warn("Channel {} is disabled", channel);
            return;
        }

        try {
            sender.send(request);
        } catch (Exception e) {
            logger.error("Failed to send via {}: {}", channel, e.getMessage(), e);
        }
    }
}
```

### 3.5 MessageService

```java
package com.ktc.luppiter.external.media.service;

import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class MessageService {

    private static final Logger logger = LoggerFactory.getLogger(MessageService.class);

    private final MessageSenderFacade messageSenderFacade;

    /**
     * 모든 활성 채널로 발송 (기본)
     */
    public void sendAll(MessageRequest request) {
        logger.info("MessageService.sendAll: template={}", request.getTemplateCode());
        messageSenderFacade.sendAll(request);
    }

    /**
     * 특정 채널로만 발송
     */
    public void send(MessageChannel channel, MessageRequest request) {
        logger.info("MessageService.send: channel={}, template={}",
            channel, request.getTemplateCode());
        messageSenderFacade.send(channel, request);
    }
}
```

### 3.6 MessageController

```java
package com.ktc.luppiter.external.media.controller;

import com.ktc.luppiter.external.media.service.MessageRequest;
import com.ktc.luppiter.external.media.service.MessageService;
import com.ktc.luppiter.external.media.template.TemplateCode;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/media")
public class MessageController {

    private static final Logger logger = LoggerFactory.getLogger(MessageController.class);

    private final MessageService messageService;

    public MessageController(MessageService messageService) {
        this.messageService = messageService;
    }

    /**
     * 메시지 발송 (모든 활성 채널)
     */
    @PostMapping("/request/{template_code}")
    public ResponseEntity<Map<String, Object>> request(
            @RequestBody Map<String, Object> req,
            @PathVariable String template_code) {

        Map<String, Object> result = new HashMap<>();

        try {
            TemplateCode templateCode = TemplateCode.valueOf(template_code.toUpperCase());

            MessageRequest messageRequest = new MessageRequest();
            messageRequest.setTemplateCode(templateCode);

            Optional.ofNullable((String) req.get("title"))
                    .ifPresent(messageRequest::setTitle);

            Optional.ofNullable((List<String>) req.get("target_list"))
                    .ifPresent(messageRequest::setTargetList);

            Optional.ofNullable((Map<String, Object>) req.get("params"))
                    .ifPresent(messageRequest::setParams);

            messageService.sendAll(messageRequest);

            result.put("resultCode", "200");
            result.put("message", "Message sent to all enabled channels");

        } catch (IllegalArgumentException e) {
            logger.warn("Invalid template_code: {}", template_code);
            result.put("resultCode", "400");
            result.put("message", "Invalid template_code: " + template_code);
            return ResponseEntity.badRequest().body(result);
        } catch (Exception e) {
            logger.error("Failed to send message: {}", e.getMessage(), e);
            result.put("resultCode", "500");
            result.put("message", "Internal server error");
            return ResponseEntity.internalServerError().body(result);
        }

        return ResponseEntity.ok(result);
    }
}
```

### 3.7 SmsSender 구현 예시

```java
package com.ktc.luppiter.external.media.service.impl;

import com.ktc.luppiter.external.media.rest.RestClientService;
import com.ktc.luppiter.external.media.service.*;
import com.ktc.luppiter.external.media.template.SMSTemplates;
import com.ktc.luppiter.web.common.service.CommonService;
import com.ktc.luppiter.web.util.CryptoUtil;
import org.springframework.boot.configurationprocessor.json.JSONObject;
import org.springframework.stereotype.Service;

import javax.annotation.PostConstruct;
import java.util.List;

@Service
public class SmsSender extends AbstractMessageSender {

    public SmsSender(SMSTemplates templates,
                     RestClientService restClientService,
                     CommonService commonService,
                     CryptoUtil cryptoUtil) {
        super(templates, restClientService, commonService, cryptoUtil);
    }

    @PostConstruct
    public void init() {
        loadConfig("server.message.url", "media.sms.use");
    }

    @Override
    public MessageChannel getChannel() {
        return MessageChannel.SMS;
    }

    @Override
    public void send(MessageRequest request) throws Exception {
        List<String> targetList = request.getTargetList();
        if (targetList == null || targetList.isEmpty()) {
            logger.warn("SMS target list is empty");
            return;
        }

        List<String> decryptedTargets = decryptTargetList(targetList);
        StringBuilder content = templateManager.render(request.getTemplateCode(), request);

        JSONObject requestJson = new JSONObject();
        requestJson.put("Content", content.toString());
        requestJson.put("Receivers", decryptedTargets);

        JSONObject apiResult = restClientService.callApi(url, requestJson);

        if ("200".equals(apiResult.optString("resultCode"))) {
            logger.info("SMS sent successfully: targets={}", targetList.size());
        } else {
            throw new RuntimeException("SMS send failed: " + apiResult.optString("message"));
        }
    }
}
```

---

## 4. REST API 사양

### 4.1 메시지 발송

```
POST /media/request/{template_code}
Content-Type: application/json

Request:
{
    "title": "메시지 제목",
    "target_list": ["010-1234-5678", "user@example.com"],
    "params": {
        "OTP_VALUE": "123456",
        "USER_NAME": "홍길동"
    }
}

Response (성공):
{
    "resultCode": "200",
    "message": "Message sent to all enabled channels"
}

Response (실패):
{
    "resultCode": "400",
    "message": "Invalid template_code: INVALID_CODE"
}
```

### 4.2 템플릿 코드

| 코드 | 용도 | 필수 파라미터 |
|------|------|--------------|
| LOGIN_OTP | 로그인 OTP | OTP_VALUE |
| USER_REGISTER | 사용자 등록 | - |
| EVENT_ALARM | 이벤트 알람 | EVENT_ID, EVENT_TITLE, ... |
| MAINTENANCE_ALERT | 메인터넌스 알림 | NAME, START_DT, END_DT, ... |
| EVENT_EXCEPTION | 예외 이벤트 | STATUS, TITLE, EXCEPTION_ID |
| HOST_REGISTER | 관제수용 | REQ_ID, REQ_TITLE, ... |
| HOST_GROUP_MAPPING | 호스트그룹 매핑 | REQ_ID, HOST_GROUP_LIST |

---

## 5. 시스템 설정

### 5.1 DB 설정 (c00_system_properties)

| group_code | prop_key | prop_val | 설명 |
|------------|----------|----------|------|
| SYSTEM_CONFIG | server.message.url | http://... | SMS/Email API URL |
| SYSTEM_CONFIG | server.slack.url | http://... | Slack API URL |
| SYSTEM_CONFIG | media.sms.use | Y/N | SMS 활성화 |
| SYSTEM_CONFIG | media.email.use | Y/N | Email 활성화 |
| SYSTEM_CONFIG | media.slack.use | Y/N | Slack 활성화 |

### 5.2 매체 비활성화

```sql
-- Email 비활성화
UPDATE c00_system_properties
SET prop_val = 'N'
WHERE group_code = 'SYSTEM_CONFIG' AND prop_key = 'media.email.use';

-- 결과: 모든 발송에서 Email 스킵
```

---

## 6. 내부 호출 (web 내부에서)

```java
@Service
@RequiredArgsConstructor
public class SomeService {

    private final MessageService messageService;

    public void sendNotification() {
        MessageRequest request = new MessageRequest();
        request.setTemplateCode(TemplateCode.EVENT_ALARM);
        request.setTargetList(List.of("010-1234-5678"));
        request.setParams(Map.of("EVENT_ID", "12345"));

        messageService.sendAll(request);  // 모든 활성 채널로
    }
}
```

---

## 7. 테스트 코드

### 7.1 테스트 데이터 빌더 (TestDataBuilder 확장)

```java
package com.framework.testdata;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class TestDataBuilder {

    // ... 기존 코드 ...

    /**
     * 메시지 요청 테스트 데이터 생성
     */
    public static Map<String, Object> buildMessageRequestParams() {
        Map<String, Object> params = new HashMap<>();
        params.put("template_code", "EVENT_ALARM");
        params.put("title", "테스트 알림");
        params.put("target_list", List.of("010-1234-5678", "test@example.com"));
        params.put("params", Map.of("EVENT_ID", "EVT001", "EVENT_TITLE", "테스트 이벤트"));
        return params;
    }

    /**
     * 메시지 요청 테스트 데이터 생성 (템플릿 코드 지정)
     */
    public static Map<String, Object> buildMessageRequestParams(String templateCode) {
        Map<String, Object> params = buildMessageRequestParams();
        params.put("template_code", templateCode);
        return params;
    }
}
```

### 7.2 MessageSenderFacade 단위 테스트

```java
package com.ktc.luppiter.external.media.service;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import java.util.List;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.ktc.luppiter.external.media.template.TemplateCode;

/**
 * MessageSenderFacade 단위 테스트
 *
 * <h3>테스트 전략</h3>
 * <ul>
 *   <li>각 MessageSender는 Mock으로 처리하여 Facade 로직만 테스트</li>
 *   <li>sendAll() 메서드의 채널별 라우팅 및 에러 처리 검증</li>
 *   <li>Given-When-Then 패턴을 사용하여 테스트 가독성 향상</li>
 * </ul>
 */
@ExtendWith(MockitoExtension.class)
@DisplayName("MessageSenderFacade 단위 테스트")
class MessageSenderFacadeTest {

    private static final Logger log = LoggerFactory.getLogger(MessageSenderFacadeTest.class);

    @Mock
    private MessageSender smsSender;

    @Mock
    private MessageSender emailSender;

    @Mock
    private MessageSender slackSender;

    private MessageSenderFacade messageSenderFacade;

    @BeforeEach
    void setUp() {
        // 채널 타입 설정
        when(smsSender.getChannel()).thenReturn(MessageChannel.SMS);
        when(emailSender.getChannel()).thenReturn(MessageChannel.EMAIL);
        when(slackSender.getChannel()).thenReturn(MessageChannel.SLACK);

        messageSenderFacade = new MessageSenderFacade(
            List.of(smsSender, emailSender, slackSender));
    }

    @Nested
    @DisplayName("sendAll 메서드 테스트")
    class SendAllTest {

        @Test
        @DisplayName("정상 케이스 - 모든 채널 활성화, 모두 성공")
        void sendAll_AllEnabled_AllSuccess() throws Exception {
            log.info("=== 테스트 시작: sendAll - 모든 채널 활성화, 모두 성공 ===");

            // Given: 모든 채널 활성화
            when(smsSender.isEnabled()).thenReturn(true);
            when(emailSender.isEnabled()).thenReturn(true);
            when(slackSender.isEnabled()).thenReturn(true);

            MessageRequest request = new MessageRequest();
            request.setTemplateCode(TemplateCode.EVENT_ALARM);
            request.setTargetList(List.of("010-1234-5678"));

            log.info("Given: 모든 채널 활성화 상태");

            // When: sendAll 호출
            log.info("When: sendAll() 메서드 실행");
            messageSenderFacade.sendAll(request);

            // Then: 모든 채널의 send 메서드 호출 검증
            log.info("Then: 모든 채널 send() 호출 검증");
            verify(smsSender, times(1)).send(any(MessageRequest.class));
            verify(emailSender, times(1)).send(any(MessageRequest.class));
            verify(slackSender, times(1)).send(any(MessageRequest.class));

            log.info("=== 테스트 완료: sendAll - 모든 채널 발송 성공 ===");
        }

        @Test
        @DisplayName("정상 케이스 - SMS만 활성화")
        void sendAll_OnlySmsEnabled() throws Exception {
            log.info("=== 테스트 시작: sendAll - SMS만 활성화 ===");

            // Given: SMS만 활성화
            when(smsSender.isEnabled()).thenReturn(true);
            when(emailSender.isEnabled()).thenReturn(false);
            when(slackSender.isEnabled()).thenReturn(false);

            MessageRequest request = new MessageRequest();
            request.setTemplateCode(TemplateCode.EVENT_ALARM);

            log.info("Given: SMS만 활성화 상태");

            // When: sendAll 호출
            log.info("When: sendAll() 메서드 실행");
            messageSenderFacade.sendAll(request);

            // Then: SMS만 호출, 나머지는 스킵
            log.info("Then: SMS만 호출, 나머지 스킵 검증");
            verify(smsSender, times(1)).send(any(MessageRequest.class));
            verify(emailSender, never()).send(any(MessageRequest.class));
            verify(slackSender, never()).send(any(MessageRequest.class));

            log.info("=== 테스트 완료: sendAll - SMS만 발송 ===");
        }

        @Test
        @DisplayName("예외 케이스 - 일부 채널 실패해도 다른 채널 계속 발송")
        void sendAll_PartialFailure_ContinueOthers() throws Exception {
            log.info("=== 테스트 시작: sendAll - 일부 채널 실패 시 나머지 계속 발송 ===");

            // Given: 모든 채널 활성화, SMS에서 예외 발생
            when(smsSender.isEnabled()).thenReturn(true);
            when(emailSender.isEnabled()).thenReturn(true);
            when(slackSender.isEnabled()).thenReturn(true);

            doThrow(new RuntimeException("SMS 발송 실패"))
                .when(smsSender).send(any(MessageRequest.class));

            MessageRequest request = new MessageRequest();
            request.setTemplateCode(TemplateCode.EVENT_ALARM);

            log.info("Given: 모든 채널 활성화, SMS에서 예외 발생 설정");

            // When: sendAll 호출
            log.info("When: sendAll() 메서드 실행");
            messageSenderFacade.sendAll(request);

            // Then: SMS 실패해도 Email, Slack 계속 발송
            log.info("Then: SMS 실패 후 Email, Slack 발송 검증");
            verify(smsSender, times(1)).send(any(MessageRequest.class));
            verify(emailSender, times(1)).send(any(MessageRequest.class));
            verify(slackSender, times(1)).send(any(MessageRequest.class));

            log.info("=== 테스트 완료: sendAll - 부분 실패 시 계속 발송 확인 ===");
        }

        @Test
        @DisplayName("빈 결과 - 모든 채널 비활성화")
        void sendAll_AllDisabled_NoSend() throws Exception {
            log.info("=== 테스트 시작: sendAll - 모든 채널 비활성화 ===");

            // Given: 모든 채널 비활성화
            when(smsSender.isEnabled()).thenReturn(false);
            when(emailSender.isEnabled()).thenReturn(false);
            when(slackSender.isEnabled()).thenReturn(false);

            MessageRequest request = new MessageRequest();
            request.setTemplateCode(TemplateCode.EVENT_ALARM);

            log.info("Given: 모든 채널 비활성화 상태");

            // When: sendAll 호출
            log.info("When: sendAll() 메서드 실행");
            messageSenderFacade.sendAll(request);

            // Then: 어떤 채널도 호출되지 않음
            log.info("Then: 모든 채널 send() 미호출 검증");
            verify(smsSender, never()).send(any(MessageRequest.class));
            verify(emailSender, never()).send(any(MessageRequest.class));
            verify(slackSender, never()).send(any(MessageRequest.class));

            log.info("=== 테스트 완료: sendAll - 모든 채널 스킵 확인 ===");
        }
    }

    @Nested
    @DisplayName("send 메서드 테스트 (특정 채널)")
    class SendSingleChannelTest {

        @Test
        @DisplayName("정상 케이스 - 지정된 채널로 발송")
        void send_SpecificChannel_Success() throws Exception {
            log.info("=== 테스트 시작: send - 지정된 채널로 발송 ===");

            // Given: SMS 채널 활성화
            when(smsSender.isEnabled()).thenReturn(true);

            MessageRequest request = new MessageRequest();
            request.setTemplateCode(TemplateCode.LOGIN_OTP);

            log.info("Given: SMS 채널 활성화 상태");

            // When: SMS 채널로 발송
            log.info("When: send(SMS, request) 메서드 실행");
            messageSenderFacade.send(MessageChannel.SMS, request);

            // Then: SMS만 호출
            log.info("Then: SMS만 호출 검증");
            verify(smsSender, times(1)).send(any(MessageRequest.class));
            verify(emailSender, never()).send(any(MessageRequest.class));
            verify(slackSender, never()).send(any(MessageRequest.class));

            log.info("=== 테스트 완료: send - 지정 채널 발송 확인 ===");
        }

        @Test
        @DisplayName("실패 케이스 - 채널 비활성화")
        void send_ChannelDisabled_NoSend() throws Exception {
            log.info("=== 테스트 시작: send - 채널 비활성화 ===");

            // Given: SMS 채널 비활성화
            when(smsSender.isEnabled()).thenReturn(false);

            MessageRequest request = new MessageRequest();
            request.setTemplateCode(TemplateCode.LOGIN_OTP);

            log.info("Given: SMS 채널 비활성화 상태");

            // When: SMS 채널로 발송 시도
            log.info("When: send(SMS, request) 메서드 실행");
            messageSenderFacade.send(MessageChannel.SMS, request);

            // Then: 발송되지 않음
            log.info("Then: SMS send() 미호출 검증");
            verify(smsSender, never()).send(any(MessageRequest.class));

            log.info("=== 테스트 완료: send - 비활성화 채널 스킵 확인 ===");
        }
    }
}
```

### 7.3 MessageService 단위 테스트

```java
package com.ktc.luppiter.external.media.service;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.ktc.luppiter.external.media.template.TemplateCode;

import java.util.List;
import java.util.Map;

@ExtendWith(MockitoExtension.class)
@DisplayName("MessageService 단위 테스트")
class MessageServiceTest {

    private static final Logger log = LoggerFactory.getLogger(MessageServiceTest.class);

    @Mock
    private MessageSenderFacade messageSenderFacade;

    @InjectMocks
    private MessageService messageService;

    @Test
    @DisplayName("sendAll - Facade의 sendAll 호출 검증")
    void sendAll_DelegatesToFacade() {
        log.info("=== 테스트 시작: sendAll - Facade 위임 검증 ===");

        // Given
        MessageRequest request = new MessageRequest();
        request.setTemplateCode(TemplateCode.EVENT_ALARM);
        request.setTargetList(List.of("010-1234-5678"));
        request.setParams(Map.of("EVENT_ID", "EVT001"));
        log.info("Given: MessageRequest 준비 - template={}", request.getTemplateCode());

        // When
        log.info("When: messageService.sendAll() 실행");
        messageService.sendAll(request);

        // Then
        log.info("Then: Facade.sendAll() 호출 검증");
        verify(messageSenderFacade, times(1)).sendAll(request);

        log.info("=== 테스트 완료: sendAll - Facade 위임 확인 ===");
    }

    @Test
    @DisplayName("send - 특정 채널로 Facade의 send 호출 검증")
    void send_DelegatesToFacade() {
        log.info("=== 테스트 시작: send - Facade 위임 검증 ===");

        // Given
        MessageRequest request = new MessageRequest();
        request.setTemplateCode(TemplateCode.LOGIN_OTP);
        log.info("Given: MessageRequest 준비 - template={}", request.getTemplateCode());

        // When
        log.info("When: messageService.send(SMS, request) 실행");
        messageService.send(MessageChannel.SMS, request);

        // Then
        log.info("Then: Facade.send(SMS, request) 호출 검증");
        verify(messageSenderFacade, times(1)).send(MessageChannel.SMS, request);

        log.info("=== 테스트 완료: send - Facade 위임 확인 ===");
    }
}
```

### 7.4 MessageController API 테스트

```java
package com.ktc.luppiter.external.media.controller;

import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.ktc.luppiter.external.media.service.MessageService;

import java.util.List;
import java.util.Map;

@ExtendWith(MockitoExtension.class)
@DisplayName("MessageController API 테스트")
class MessageControllerTest {

    private static final Logger log = LoggerFactory.getLogger(MessageControllerTest.class);

    @Mock
    private MessageService messageService;

    @InjectMocks
    private MessageController messageController;

    private MockMvc mockMvc;
    private ObjectMapper objectMapper;

    @BeforeEach
    void setUp() {
        mockMvc = MockMvcBuilders.standaloneSetup(messageController).build();
        objectMapper = new ObjectMapper();
    }

    @Nested
    @DisplayName("POST /media/request/{template_code}")
    class SendMessageTest {

        @Test
        @DisplayName("정상 케이스 - EVENT_ALARM 템플릿 발송")
        void request_EventAlarm_Success() throws Exception {
            log.info("=== 테스트 시작: 메시지 발송 API - EVENT_ALARM 정상 케이스 ===");

            // Given
            Map<String, Object> requestBody = Map.of(
                "title", "테스트 알림",
                "target_list", List.of("010-1234-5678"),
                "params", Map.of("EVENT_ID", "EVT001", "EVENT_TITLE", "테스트 이벤트")
            );
            log.info("Given: 요청 데이터 준비 - template=EVENT_ALARM");

            // When & Then
            log.info("When: POST /media/request/EVENT_ALARM 호출");
            mockMvc.perform(post("/media/request/EVENT_ALARM")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.resultCode").value("200"))
                .andExpect(jsonPath("$.message").exists());

            verify(messageService, times(1)).sendAll(any());
            log.info("=== 테스트 완료: 메시지 발송 API - 정상 응답 확인 ===");
        }

        @Test
        @DisplayName("정상 케이스 - LOGIN_OTP 템플릿 발송")
        void request_LoginOtp_Success() throws Exception {
            log.info("=== 테스트 시작: 메시지 발송 API - LOGIN_OTP 정상 케이스 ===");

            // Given
            Map<String, Object> requestBody = Map.of(
                "target_list", List.of("010-1234-5678"),
                "params", Map.of("OTP_VALUE", "123456")
            );
            log.info("Given: 요청 데이터 준비 - template=LOGIN_OTP");

            // When & Then
            log.info("When: POST /media/request/LOGIN_OTP 호출");
            mockMvc.perform(post("/media/request/LOGIN_OTP")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.resultCode").value("200"));

            verify(messageService, times(1)).sendAll(any());
            log.info("=== 테스트 완료: 메시지 발송 API - 정상 응답 확인 ===");
        }

        @Test
        @DisplayName("실패 케이스 - 잘못된 템플릿 코드")
        void request_InvalidTemplateCode_BadRequest() throws Exception {
            log.info("=== 테스트 시작: 메시지 발송 API - 잘못된 템플릿 코드 ===");

            // Given
            Map<String, Object> requestBody = Map.of(
                "target_list", List.of("010-1234-5678")
            );
            log.info("Given: 잘못된 템플릿 코드 - INVALID_TEMPLATE");

            // When & Then
            log.info("When: POST /media/request/INVALID_TEMPLATE 호출");
            mockMvc.perform(post("/media/request/INVALID_TEMPLATE")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.resultCode").value("400"))
                .andExpect(jsonPath("$.message").value("Invalid template_code: INVALID_TEMPLATE"));

            verify(messageService, never()).sendAll(any());
            log.info("=== 테스트 완료: 메시지 발송 API - 400 응답 확인 ===");
        }

        @Test
        @DisplayName("실패 케이스 - 서비스 예외 발생")
        void request_ServiceException_InternalError() throws Exception {
            log.info("=== 테스트 시작: 메시지 발송 API - 서비스 예외 발생 ===");

            // Given
            doThrow(new RuntimeException("발송 실패"))
                .when(messageService).sendAll(any());

            Map<String, Object> requestBody = Map.of(
                "target_list", List.of("010-1234-5678")
            );
            log.info("Given: 서비스에서 예외 발생 설정");

            // When & Then
            log.info("When: POST /media/request/EVENT_ALARM 호출");
            mockMvc.perform(post("/media/request/EVENT_ALARM")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isInternalServerError())
                .andExpect(jsonPath("$.resultCode").value("500"));

            log.info("=== 테스트 완료: 메시지 발송 API - 500 응답 확인 ===");
        }

        @Test
        @DisplayName("정상 케이스 - 소문자 템플릿 코드 (대소문자 무관)")
        void request_LowercaseTemplateCode_Success() throws Exception {
            log.info("=== 테스트 시작: 메시지 발송 API - 소문자 템플릿 코드 ===");

            // Given
            Map<String, Object> requestBody = Map.of(
                "target_list", List.of("010-1234-5678")
            );
            log.info("Given: 소문자 템플릿 코드 - event_alarm");

            // When & Then
            log.info("When: POST /media/request/event_alarm 호출");
            mockMvc.perform(post("/media/request/event_alarm")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.resultCode").value("200"));

            verify(messageService, times(1)).sendAll(any());
            log.info("=== 테스트 완료: 메시지 발송 API - 대소문자 무관 확인 ===");
        }
    }

    @Nested
    @DisplayName("입력 검증 테스트")
    class InputValidationTest {

        @Test
        @DisplayName("빈 요청 본문 처리")
        void request_EmptyBody() throws Exception {
            log.info("=== 테스트 시작: 메시지 발송 API - 빈 요청 본문 ===");

            // When & Then
            log.info("When: POST /media/request/EVENT_ALARM 호출 (빈 본문)");
            mockMvc.perform(post("/media/request/EVENT_ALARM")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content("{}"))
                .andExpect(status().isOk());

            log.info("=== 테스트 완료: 메시지 발송 API - 빈 본문 처리 확인 ===");
        }

        @Test
        @DisplayName("특수 문자 포함 파라미터 처리")
        void request_SpecialCharacters() throws Exception {
            log.info("=== 테스트 시작: 메시지 발송 API - 특수 문자 처리 ===");

            // Given
            Map<String, Object> requestBody = Map.of(
                "title", "테스트<script>alert('XSS')</script>",
                "target_list", List.of("010-1234-5678"),
                "params", Map.of("EVENT_ID", "EVT001'; DROP TABLE events; --")
            );
            log.info("Given: 특수 문자 포함 요청 데이터");

            // When & Then
            log.info("When: POST /media/request/EVENT_ALARM 호출 (특수 문자 포함)");
            mockMvc.perform(post("/media/request/EVENT_ALARM")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(requestBody)))
                .andExpect(status().isOk());

            verify(messageService, times(1)).sendAll(any());
            log.info("=== 테스트 완료: 메시지 발송 API - 특수 문자 처리 확인 ===");
        }
    }
}
```

### 7.5 SmsSender 단위 테스트

```java
package com.ktc.luppiter.external.media.service.impl;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.Mockito.*;

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
import org.springframework.boot.configurationprocessor.json.JSONObject;
import org.springframework.test.util.ReflectionTestUtils;

import com.ktc.luppiter.external.media.rest.RestClientService;
import com.ktc.luppiter.external.media.service.MessageChannel;
import com.ktc.luppiter.external.media.service.MessageRequest;
import com.ktc.luppiter.external.media.template.SMSTemplates;
import com.ktc.luppiter.external.media.template.TemplateCode;
import com.ktc.luppiter.web.common.service.CommonService;
import com.ktc.luppiter.web.util.CryptoUtil;

@ExtendWith(MockitoExtension.class)
@DisplayName("SmsSender 단위 테스트")
class SmsSenderTest {

    private static final Logger log = LoggerFactory.getLogger(SmsSenderTest.class);

    @Mock
    private SMSTemplates smsTemplates;

    @Mock
    private RestClientService restClientService;

    @Mock
    private CommonService commonService;

    @Mock
    private CryptoUtil cryptoUtil;

    private SmsSender smsSender;

    @BeforeEach
    void setUp() {
        smsSender = new SmsSender(smsTemplates, restClientService, commonService, cryptoUtil);

        // 테스트용 설정 주입
        ReflectionTestUtils.setField(smsSender, "url", "http://test-sms-api.com");
        ReflectionTestUtils.setField(smsSender, "enabled", true);
    }

    @Test
    @DisplayName("getChannel - SMS 채널 반환")
    void getChannel_ReturnsSms() {
        log.info("=== 테스트 시작: getChannel - SMS 채널 반환 ===");

        assertThat(smsSender.getChannel())
            .as("SmsSender의 채널은 SMS여야 함")
            .isEqualTo(MessageChannel.SMS);

        log.info("=== 테스트 완료: getChannel - SMS 확인 ===");
    }

    @Nested
    @DisplayName("send 메서드 테스트")
    class SendTest {

        @Test
        @DisplayName("정상 케이스 - SMS 발송 성공")
        void send_Success() throws Exception {
            log.info("=== 테스트 시작: send - SMS 발송 성공 ===");

            // Given
            MessageRequest request = new MessageRequest();
            request.setTemplateCode(TemplateCode.EVENT_ALARM);
            request.setTargetList(List.of("encrypted_phone_1", "encrypted_phone_2"));
            request.setParams(Map.of("EVENT_ID", "EVT001"));

            when(cryptoUtil.decrypt("encrypted_phone_1")).thenReturn("010-1234-5678");
            when(cryptoUtil.decrypt("encrypted_phone_2")).thenReturn("010-8765-4321");

            JSONObject successResponse = new JSONObject();
            successResponse.put("resultCode", "200");
            when(restClientService.callApi(anyString(), any(JSONObject.class)))
                .thenReturn(successResponse);

            log.info("Given: 암호화된 전화번호 2건 준비");

            // When
            log.info("When: send() 실행");
            smsSender.send(request);

            // Then
            log.info("Then: API 호출 검증");
            verify(cryptoUtil, times(2)).decrypt(anyString());
            verify(restClientService, times(1)).callApi(anyString(), any(JSONObject.class));

            log.info("=== 테스트 완료: send - SMS 발송 성공 확인 ===");
        }

        @Test
        @DisplayName("실패 케이스 - 대상 목록 비어있음")
        void send_EmptyTargetList_NoSend() throws Exception {
            log.info("=== 테스트 시작: send - 대상 목록 비어있음 ===");

            // Given
            MessageRequest request = new MessageRequest();
            request.setTemplateCode(TemplateCode.EVENT_ALARM);
            request.setTargetList(List.of());  // 빈 목록

            log.info("Given: 빈 대상 목록");

            // When
            log.info("When: send() 실행");
            smsSender.send(request);

            // Then - API 호출되지 않음
            log.info("Then: API 미호출 검증");
            verify(restClientService, never()).callApi(anyString(), any(JSONObject.class));

            log.info("=== 테스트 완료: send - 빈 목록 스킵 확인 ===");
        }

        @Test
        @DisplayName("실패 케이스 - API 응답 실패")
        void send_ApiFailure_ThrowsException() throws Exception {
            log.info("=== 테스트 시작: send - API 응답 실패 ===");

            // Given
            MessageRequest request = new MessageRequest();
            request.setTemplateCode(TemplateCode.EVENT_ALARM);
            request.setTargetList(List.of("encrypted_phone"));

            when(cryptoUtil.decrypt(anyString())).thenReturn("010-1234-5678");

            JSONObject failResponse = new JSONObject();
            failResponse.put("resultCode", "500");
            failResponse.put("message", "Internal Error");
            when(restClientService.callApi(anyString(), any(JSONObject.class)))
                .thenReturn(failResponse);

            log.info("Given: API 500 응답 설정");

            // When & Then
            log.info("When & Then: 예외 발생 검증");
            assertThatThrownBy(() -> smsSender.send(request))
                .as("API 실패 시 RuntimeException이 발생해야 함")
                .isInstanceOf(RuntimeException.class)
                .hasMessageContaining("SMS send failed");

            log.info("=== 테스트 완료: send - API 실패 예외 확인 ===");
        }

        @Test
        @DisplayName("실패 케이스 - 대상 목록 null")
        void send_NullTargetList_NoSend() throws Exception {
            log.info("=== 테스트 시작: send - 대상 목록 null ===");

            // Given
            MessageRequest request = new MessageRequest();
            request.setTemplateCode(TemplateCode.EVENT_ALARM);
            request.setTargetList(null);  // null

            log.info("Given: null 대상 목록");

            // When
            log.info("When: send() 실행");
            smsSender.send(request);

            // Then - API 호출되지 않음
            log.info("Then: API 미호출 검증");
            verify(restClientService, never()).callApi(anyString(), any(JSONObject.class));

            log.info("=== 테스트 완료: send - null 목록 스킵 확인 ===");
        }
    }
}
```

---

## 8. 구현 체크리스트

### 8.1 코드 구현
- [ ] MessageSender 인터페이스에 `isEnabled()` 추가
- [ ] AbstractMessageSender 생성
- [ ] MessageRequest에서 channel 필드 제거
- [ ] MessageSenderFacade를 service 패키지로 이동
- [ ] MessageSenderFacade에 `sendAll()` 추가
- [ ] MessageController API 변경 (채널 파라미터 제거)
- [ ] 각 Sender 구현체 수정 (AbstractMessageSender 상속)
- [ ] WebMvcConfiguration 인터셉터 제외 경로 확인

### 8.2 테스트 구현
- [ ] MessageSenderFacade 단위 테스트
- [ ] MessageService 단위 테스트
- [ ] MessageController API 테스트
- [ ] SmsSender 단위 테스트
- [ ] EmailSender 단위 테스트
- [ ] SlackSender 단위 테스트
