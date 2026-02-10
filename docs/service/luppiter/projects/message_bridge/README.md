# Message Bridge

Slack 메시지 전송을 위한 프록시 서비스. 내부 시스템이 Slack 토큰을 직접 관리하지 않고, message_bridge를 통해 메시지를 전달한다.

> 향후 Hermes(메시징/알림) 서비스로 이관될 수 있음 (미정)

## 기술 스택

| 항목 | 내용 |
|------|------|
| 언어 | Java 11 |
| 프레임워크 | Spring Boot 2.7.5 |
| 빌드 | Maven |
| Slack SDK | slack-api-client 1.20.2 |
| 포트 | 8282 |

## 주요 기능

- Slack DM 전송 (Attachment 포맷) - `/slack/sendDirect`
- Slack DM 전송 (Markdown 포맷) - `/slack/sendDirect/mrkdwn`
- Slack Block Kit 전송 (email/channelId) - `/slack/sendDirect/blockkit`
- Slack 채널 전송 (Webhook) - `/slack/sendChannel`
- SMS/MMS 전송 (xroshot SDK) - `/sms/send`, `/mms/send`

## API 명세

### Block Kit 전송

```
POST /slack/sendDirect/blockkit
```

| 파라미터 | 타입 | 필수 | 설명 |
|----------|------|------|------|
| email | query | email/channelId 중 하나 | 수신자 이메일 (DM) |
| channelId | query | email/channelId 중 하나 | 채널 ID (채널 전송) |

**Request Body:**
```json
{
  "text": "폴백 텍스트",
  "blocks": [ ... Block Kit JSON ... ]
}
```

**동작:**
- `channelId` 있으면 → 채널로 직접 전송
- `email` 있으면 → userId 조회 후 DM 전송
- 실패 시 1초 후 1회 재시도

## 아키텍처

```
클라이언트 (luppiter_web, test_slack_send 등)
    ↓ HTTP (email/channelId + payload)
message_bridge (8282)
    ↓ Slack SDK (chatPostMessage)
Slack API
```

## 로컬 개발 설정

로컬에서 실행 시 다음 설정 필요:
- `application-local.properties`에서 DB 설정 비활성화
- `DataSourceAutoConfiguration` 제외
- `DatabaseConfiguration`에 `@ConditionalOnProperty` 추가
- `xroshot_openapi_sdk` 의존성 주석 처리

```bash
cd message_bridge && mvn spring-boot:run -Dspring-boot.run.profiles=local
```

## 변경 이력

| 날짜 | 내용 |
|------|------|
| 2026-02-09 | Block Kit 엔드포인트 추가 (`/slack/sendDirect/blockkit`) |
| 2026-02-09 | channelId 파라미터 지원 추가 (email과 선택적 사용) |
| 2026-02-09 | 로컬 개발 환경 설정 (DB/SMS 비활성화) |

---

**최종 업데이트**: 2026-02-09
