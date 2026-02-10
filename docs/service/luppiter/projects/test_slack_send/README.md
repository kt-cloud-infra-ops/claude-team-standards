# Test Slack Send

Slack Block Kit 메시지 포맷 테스트 프로젝트. 7종 관제 메시지 + OTP 인증 메시지를 Block Kit으로 구현하고 message_bridge를 통해 전송한다.

## 기술 스택

| 항목 | 내용 |
|------|------|
| 언어 | Java 17 |
| 프레임워크 | Spring Boot 3.2.0 |
| 빌드 | Maven |
| 포트 | 8090 |

## 주요 기능

### 8종 Block Kit 메시지 빌더

| # | 메시지 유형 | 빌더 클래스 | DTO |
|---|-----------|------------|-----|
| 1 | 이벤트 (발생/해소) | EventMessageBuilder | EventAlarmData |
| 2 | 미등록이벤트 | UnregisteredEventMessageBuilder | UnregisteredEventData |
| 3 | 메인터넌스 | MaintenanceMessageBuilder | MaintenanceData |
| 4 | 이벤트예외 | EventExceptionMessageBuilder | EventExceptionData |
| 5 | 관제수용 | AcceptanceMessageBuilder | AcceptanceData |
| 6 | 관제삭제 | DeletionMessageBuilder | DeletionData |
| 7 | OTP인증 | OtpMessageBuilder | OtpData |

### Block Kit 요소 (BlockKitHelper)

- `sectionMrkdwn()` - 마크다운 섹션
- `richTextSection()` - 볼드 라벨 + 값
- `bulletListElement()` - 들여쓰기 지원 불릿 리스트
- `richTextBlock()` - rich_text 블록
- `context()` / `divider()` - 컨텍스트, 구분선

## 프로젝트 구조

```
src/main/java/com/example/slacktest/
├── controller/
│   └── BlockKitMessageController.java   # 메시지별 전송 + 일괄 테스트
├── service/
│   ├── MessageBridgeClient.java         # RestTemplate → message_bridge
│   └── MessageTestService.java          # 샘플 데이터 로드 + 일괄 전송
├── blockkit/
│   ├── BlockKitHelper.java              # Block Kit 요소 유틸
│   └── *MessageBuilder.java (7개)       # 메시지별 빌더
└── model/
    └── *Data.java (7개)                 # 메시지별 DTO
```

## API 명세

### 개별 전송

```
POST /api/blockkit/{type}/send?email=xxx      (DM)
POST /api/blockkit/{type}/send?channelId=xxx   (채널)
```

type: `event`, `unregistered-event`, `maintenance`, `event-exception`, `acceptance`, `deletion`, `otp`

### 일괄 테스트 전송

```
POST /api/blockkit/test/send-all?email=xxx
POST /api/blockkit/test/send-all?channelId=xxx
```

### JSON 미리보기

```
GET /api/blockkit/event/preview
```

## 전송 흐름

```
test_slack_send (8090)
    ↓ MessageBridgeClient (RestTemplate)
message_bridge (8282) /slack/sendDirect/blockkit
    ↓ Slack SDK (chatPostMessage + blocksAsString)
Slack API
```

## 실행

```bash
cd test_slack_send && mvn spring-boot:run
```

테스트:
```bash
# DM 전송
curl -X POST "http://localhost:8090/api/blockkit/test/send-all?email=jiwoong.kim@kt.com"

# 채널 전송
curl -X POST "http://localhost:8090/api/blockkit/test/send-all?channelId=C0ACCJENW23"
```

## 관련 문서

- Confluence: Slack Block Kit 메시지 포맷 정의서 (page 1708818683)

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-02-09 | message_bridge 경유로 전환 (SlackService 직접 호출 제거) |
| 2026-02-09 | channelId 파라미터 지원 추가 |
| 2026-02-09 | 컨트롤러 정리 (SlackTestController 삭제) |
| 2026-02-09 | 메인터넌스 이벤트를 대상 하위 리스트로 변경 |
| 2026-02-09 | 미등록이벤트에 hostName/ip 필드 추가 |

---

**최종 업데이트**: 2026-02-09
