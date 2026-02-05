# 메시지 발송 아키텍처 상세 설계

> **상태**: 설계 중
> **작성일**: 2026-02-04
> **참조**: [Confluence - 매체발송 기능 정리](https://ktcloud.atlassian.net/wiki/spaces/SREP/pages/1381466169)

---

## 1. 개요

### 1.1 변경 목적

- **발송 주체 통합**: Scheduler → Web으로 메시지 발송 로직 이전
- **발송 대상 변경**: 개인별 발송 → 호스트그룹 기준 발송
- **채널 발송 추가**: 협력사 Slack 채널로 그룹 단위 알림

### 1.2 아키텍처 변경

```
[AS-IS]
luppiter_scheduler ──────────────────> message_bridge ──> 외부
         │                                   │
         ├── EventAlarmServiceJob            ├── /sms/send
         ├── MaintenanceAlarmServiceJob      ├── /mail/send
         ├── ExceptionEventAlarmServiceJob   └── /slack/sendDirect
         └── HostManageAlarmServiceJob

[TO-BE]
luppiter_scheduler ──> luppiter_web ──> message_bridge ──> 외부
         │                   │
         └── POST /api/message/send
                             │
                             ├── 개인 발송 (SLACK DM, SMS)
                             └── 채널 발송 (호스트그룹별 Slack 채널)
```

> **message_bridge**: MGMT 환경에서 외부 네트워크로 메시지 발송하는 브릿지 서비스

---

## 2. 현재 구조 분석

### 2.1 메시지 발송 클래스 위치

| 프로젝트 | 경로 | 클래스 |
|---------|------|--------|
| luppiter_scheduler | `/media/message/` | MessageServiceSender.java |
| luppiter_scheduler | `/media/slack/` | SlackMessageSender.java, SlackMessageMaker.java |
| luppiter_web | `/external/media/` | MessageServiceSender.java, SlackMessageSender.java |

### 2.2 배치별 발송 현황

| 배치 | 경로 | 발송 매체 |
|------|------|----------|
| EventAlarmServiceJob | `/batch/task/common/` | SMS, Email, Slack |
| MaintenanceAlarmServiceJob | `/batch/task/common/` | SMS, Email, Slack |
| ExceptionEventAlarmServiceJob | `/batch/task/common/` | Email |
| HostManageAlarmServiceJob | `/batch/task/common/` | SMS, Slack |

### 2.3 Message Bridge (MGMT → 외부 발송)

> **message_bridge**: MGMT 환경에서 외부로 메시지를 발송하는 브릿지 서비스

| 매체 | 엔드포인트 | 설정 키 |
|------|-----------|---------|
| SMS | `{server.message.url}/sms/send` | `server.message.url` |
| LMS | `{server.message.url}/mms/send` | `server.message.url` |
| Email | `{server.email.url}/mail/send` | `server.email.url` |
| Slack DM | `{server.slack.url}/slack/sendDirect?email={email}` | `server.slack.url` |
| Slack Channel | `{server.slack.url}/slack/sendChannel?channel={channelId}` | `server.slack.url` |

---

## 3. Slack 채널 정보

### 3.1 시스템 채널 (고정)

| 용도 | 채널명 | 채널 ID |
|------|--------|---------|
| 미등록 이벤트 | `#luppiter-unregistered-events` | `C0ACCJENW23` |

### 3.2 호스트그룹별 채널 (네이밍 규칙)

```
#luppiter-{L1}-{L3}-alert
```

| 예시 | 채널명 |
|------|--------|
| 인프라-서버 | `#luppiter-infra-server-alert` |
| 인프라-네트워크 | `#luppiter-infra-network-alert` |
| 플랫폼-K8s | `#luppiter-plat-k8s-alert` |

---

## 4. DB 스키마 변경

### 3.1 cmon_group 테이블 변경

```sql
-- 설비권한그룹에 Slack 채널 ID 추가
ALTER TABLE cmon_group
ADD COLUMN slack_channel_id VARCHAR(50);

COMMENT ON COLUMN cmon_group.slack_channel_id
IS '호스트그룹 이벤트 발송 Slack 채널 ID (예: C0XXXXXXXXX)';

-- 인덱스 (선택)
CREATE INDEX idx_cmon_group_slack_channel
ON cmon_group(slack_channel_id)
WHERE slack_channel_id IS NOT NULL;
```

### 3.2 메시지 발송 로그 테이블 (신규)

```sql
CREATE TABLE cmon_message_log (
    log_seq             BIGSERIAL PRIMARY KEY,
    message_type        VARCHAR(20) NOT NULL,       -- SLACK, SMS, EMAIL
    target_type         VARCHAR(20) NOT NULL,       -- USER, CHANNEL, GROUP
    target_id           VARCHAR(100) NOT NULL,      -- 사용자ID/채널ID/그룹ID
    template_code       VARCHAR(50),                -- 템플릿 코드
    title               VARCHAR(500),               -- 제목
    body                TEXT,                       -- 본문
    status              VARCHAR(20) NOT NULL,       -- SUCCESS, FAILED
    error_message       TEXT,                       -- 에러 메시지
    request_id          VARCHAR(100),               -- 요청 추적 ID
    created_at          TIMESTAMP DEFAULT NOW(),
    updated_at          TIMESTAMP DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_cmon_message_log_status ON cmon_message_log(status);
CREATE INDEX idx_cmon_message_log_created ON cmon_message_log(created_at);
CREATE INDEX idx_cmon_message_log_request ON cmon_message_log(request_id);
```

### 3.3 설정 변경 (c00_system_properties)

```sql
-- AS-IS → TO-BE 설정 변경
UPDATE c00_system_properties
SET property_nm = 'media.xroshot.use'
WHERE property_nm = 'media.lms.use';

-- 미등록 이벤트 알림 채널 설정
-- 채널: #luppiter-unregistered-events (C0ACCJENW23)
INSERT INTO c00_system_properties (prop_key, prop_group, prop_nm, prop_val, use_yn, created_id)
VALUES ('SYSTEM_CONFIG', 'SLACK', 'slack.unregistered.channel', 'C0ACCJENW23', 'Y', 'system');
```

---

## 4. API 상세 설계

### 4.1 메시지 발송 API

#### 엔드포인트

```
POST /api/message/send
Content-Type: application/json
```

#### 요청 형식

```json
{
  "messageType": "SLACK",
  "targetType": "GROUP",
  "targetId": "그룹ID",
  "templateCode": "EVENT_ALARM",
  "title": "이벤트 발생 알림",
  "body": "메시지 본문 (템플릿 미사용 시)",
  "params": {
    "eventId": "EVT001",
    "hostname": "server01",
    "eventName": "CPU 사용률 초과"
  },
  "options": {
    "fallbackToUser": true
  }
}
```

#### 필드 설명

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| messageType | String | Y | SLACK, SMS, EMAIL, ALL |
| targetType | String | Y | USER, CHANNEL, GROUP |
| targetId | String | Y | 대상 ID |
| templateCode | String | N | 템플릿 코드 (없으면 body 사용) |
| title | String | N | 메시지 제목 |
| body | String | N | 메시지 본문 |
| params | Object | N | 템플릿 파라미터 |
| options.fallbackToUser | Boolean | N | 채널 미설정 시 개인 발송 여부 |

#### 응답 형식

```json
{
  "success": true,
  "requestId": "req-20260204-001",
  "results": [
    {
      "targetId": "user001",
      "messageType": "SLACK",
      "status": "SUCCESS"
    },
    {
      "targetId": "user002",
      "messageType": "SMS",
      "status": "FAILED",
      "error": "Invalid phone number"
    }
  ]
}
```

### 4.2 발송 대상 조회 API

#### 그룹 기준 발송 대상 조회

```
GET /api/message/targets?groupId={groupId}&messageType={SLACK|SMS|EMAIL}
```

#### 응답

```json
{
  "groupId": "GRP001",
  "groupName": "인프라운영팀",
  "slackChannelId": "C0XXXXXXXXX",
  "users": [
    {
      "userId": "user001",
      "userName": "홍길동",
      "email": "hong@kt.com",
      "phone": "010-1234-5678",
      "slackEnabled": true,
      "smsEnabled": true,
      "emailEnabled": false
    }
  ]
}
```

---

## 5. 시퀀스 다이어그램

### 5.1 이벤트 알림 발송 (TO-BE)

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│Scheduler│     │   Web   │     │   DB    │     │ 외부서버 │
└────┬────┘     └────┬────┘     └────┬────┘     └────┬────┘
     │               │               │               │
     │ POST /api/message/send        │               │
     │ {groupId, templateCode, ...}  │               │
     │──────────────>│               │               │
     │               │               │               │
     │               │ 그룹 정보 조회  │               │
     │               │──────────────>│               │
     │               │               │               │
     │               │ slack_channel_id, users       │
     │               │<──────────────│               │
     │               │               │               │
     │               │               │               │
     │               │               │               │
     │               │ ┌───────────────────────────┐ │
     │               │ │ 채널 발송 (slack_channel_id)│ │
     │               │ │ /slack/sendChannel        │ │
     │               │ └───────────────────────────┘ │
     │               │──────────────────────────────>│
     │               │               │               │
     │               │ ┌───────────────────────────┐ │
     │               │ │ 개인 발송 (users loop)    │ │
     │               │ │ /slack/sendDirect         │ │
     │               │ │ /sms/send                 │ │
     │               │ └───────────────────────────┘ │
     │               │──────────────────────────────>│
     │               │               │               │
     │               │ 로그 업데이트 (SUCCESS/FAILED)│
     │               │──────────────>│               │
     │               │               │               │
     │ 응답 (requestId, results)     │               │
     │<──────────────│               │               │
     │               │               │               │
```

---

## 6. 메시지 템플릿

### 6.1 템플릿 코드 목록

| 코드 | 용도 | 매체 |
|------|------|------|
| EVENT_ALARM | 이벤트 발생/해소 | Slack, SMS |
| EVENT_EXCEPTION | 예외 등록/시작/종료 | Email, Slack |
| MAINTENANCE | 메인터넌스 상태 변경 | Email, Slack, SMS |
| HOST_MANAGE | 관제 수용 상태 변경 | Slack, SMS |
| HOST_DELETE | 관제 삭제 알림 | Slack |
| UNREGISTERED_EVENT | 미등록 이벤트 알림 | Slack |

### 6.2 템플릿 예시 (Slack)

#### EVENT_ALARM

```json
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "🚨 이벤트 ${eventState}"
      }
    },
    {
      "type": "section",
      "fields": [
        {"type": "mrkdwn", "text": "*분류:* ${l1Nm}"},
        {"type": "mrkdwn", "text": "*도메인:* ${l2Nm}"},
        {"type": "mrkdwn", "text": "*표준서비스:* ${l3Nm}"},
        {"type": "mrkdwn", "text": "*Zone:* ${zone}"},
        {"type": "mrkdwn", "text": "*호스트:* ${hostname}"},
        {"type": "mrkdwn", "text": "*IP:* ${targetIp}"}
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*이벤트:* ${eventName}\n*등급:* ${eventLevel}\n*발생시간:* ${occuTime}"
      }
    }
  ]
}
```

#### UNREGISTERED_EVENT

```json
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "⚠️ 미등록 이벤트 발생"
      }
    },
    {
      "type": "section",
      "fields": [
        {"type": "mrkdwn", "text": "*타입:* ${type}"},
        {"type": "mrkdwn", "text": "*namespace:* ${namespace}"},
        {"type": "mrkdwn", "text": "*region:* ${region}"},
        {"type": "mrkdwn", "text": "*시간:* ${timestamp}"}
      ]
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*이벤트:* ${eventName}\n\n※ 서비스/플랫폼 관리 화면에서 등록 필요"
      }
    }
  ]
}
```

---

## 7. 화면 변경 상세

### 7.1 설비권한그룹-사용자 화면

#### 그룹 목록 (왼쪽 테이블) 변경

| 컬럼 | AS-IS | TO-BE |
|------|-------|-------|
| 그룹명 | O | O |
| 사용자 수 | O | O |
| Slack 채널 | X | O (신규) |

#### 그룹명 수정 팝업 변경

```
┌─────────────────────────────────┐
│ 그룹 정보 수정                   │
├─────────────────────────────────┤
│ 그룹명: [________________]       │
│                                  │
│ Slack 채널 ID: [________________]│
│ (예: C0XXXXXXXXX)                │
│                                  │
│         [취소]  [저장]           │
└─────────────────────────────────┘
```

### 7.2 SQL 변경

```sql
-- 그룹 목록 조회 (기존 쿼리에 컬럼 추가)
SELECT
    group_id,
    group_nm,
    group_user_count,
    slack_channel_id,  -- 추가
    cret_dt,
    cretr_id
FROM cmon_group
WHERE delete_yn = 'N'
ORDER BY group_nm;

-- 그룹 정보 수정 (기존 쿼리에 컬럼 추가)
UPDATE cmon_group
SET group_nm = #{groupNm},
    slack_channel_id = #{slackChannelId},  -- 추가
    amd_dt = NOW(),
    amdr_id = #{amdrId}
WHERE group_id = #{groupId};
```

---

## 8. 발송 대상 결정 로직

### 8.1 호스트그룹 기준 발송

```java
public List<MessageTarget> getTargets(String groupId, String messageType) {
    List<MessageTarget> targets = new ArrayList<>();

    // 1. 그룹 정보 조회
    Group group = groupMapper.selectGroup(groupId);

    // 2. 채널 발송 (Slack만)
    if ("SLACK".equals(messageType) && group.getSlackChannelId() != null) {
        targets.add(new MessageTarget(
            TargetType.CHANNEL,
            group.getSlackChannelId()
        ));
    }

    // 3. 개인 발송
    List<User> users = groupMapper.selectGroupUsers(groupId);
    for (User user : users) {
        // 사용자 수신 설정 확인
        if (isEnabled(user, messageType)) {
            targets.add(new MessageTarget(
                TargetType.USER,
                user.getUserId(),
                user.getEmail(),
                user.getPhone()
            ));
        }
    }

    return targets;
}
```

### 8.2 미등록 이벤트 발송

```java
public void sendUnregisteredEventAlert(ObsEvent event) {
    // 1. 호스트그룹 찾기 (L3 기준)
    String groupId = findGroupByL3(event.getL3LayerCd());

    if (groupId == null) {
        log.warn("미등록 이벤트 - 그룹 없음: {}", event);
        return;
    }

    // 2. 채널 ID 조회
    String channelId = groupMapper.selectSlackChannelId(groupId);

    if (channelId == null) {
        log.info("미등록 이벤트 - 채널 미설정, PASS: {}", groupId);
        return;
    }

    // 3. 채널로 발송
    MessageRequest request = MessageRequest.builder()
        .messageType(MessageType.SLACK)
        .targetType(TargetType.CHANNEL)
        .targetId(channelId)
        .templateCode("UNREGISTERED_EVENT")
        .params(Map.of(
            "type", event.getSvcType(),
            "namespace", event.getTargetName(),
            "region", event.getRegion(),
            "eventName", event.getEventName(),
            "timestamp", event.getOccuTime()
        ))
        .build();

    messageSender.send(request);
}
```

---

## 9. 구현 단계

### Phase 1: 기반 구축 (1주)

- [ ] `cmon_group.slack_channel_id` 컬럼 추가
- [ ] `cmon_message_log` 테이블 생성
- [ ] 설비권한그룹-사용자 화면 수정 (채널 ID 표시/수정)

### Phase 2: API 구현 (1주)

- [ ] `/api/message/send` API 구현
- [ ] `/api/message/targets` API 구현
- [ ] 메시지 로그 저장

### Phase 3: Scheduler 연동 (1주)

- [ ] EventAlarmServiceJob → Web API 호출로 변경
- [ ] MaintenanceAlarmServiceJob → Web API 호출로 변경
- [ ] HostManageAlarmServiceJob → Web API 호출로 변경
- [ ] 미등록 이벤트 알림 구현 (O11y)

### Phase 4: 정책 적용 (1주)

- [ ] 호스트그룹 기준 발송 로직 적용
- [ ] 협력사 채널 발송 구현
- [ ] 메시지 템플릿 정리/협의

### Phase 5: Decomm (Slack 채널 안정화 후)

- [ ] Email/SMS 발송 Off
- [ ] 레거시 발송 코드 제거
- [ ] `media.lms.use` → `media.xroshot.use` 변경

---

## 10. 관련 파일

| 구분 | 파일 |
|------|------|
| **Scheduler 배치** | `/batch/task/common/*AlarmServiceJob.java` |
| **Scheduler 메시지** | `/media/message/MessageServiceSender.java` |
| **Scheduler Slack** | `/media/slack/SlackMessageSender.java` |
| **Web 메시지** | `/external/media/MessageServiceSender.java` |
| **Web Slack** | `/external/media/SlackMessageSender.java` |
| **그룹 SQL** | `/sqlmap/sql-ctl.xml` |
| **설정 테이블** | `c00_system_properties` |

---

## 11. 논의 필요 사항

- [ ] 메시지 포맷 정리 (전체 목록 및 예제 확인)
- [ ] 신규 추가 항목 포맷 협의
- [ ] 개인 설정 영역 확장 여부 (이벤트 알림 외)
- [ ] 채널 미설정 시 fallback 정책 (개인 발송 vs PASS)

---

**최종 업데이트**: 2026-02-04
