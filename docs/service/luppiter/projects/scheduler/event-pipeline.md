# 학습: Luppiter Scheduler 이벤트 처리 파이프라인 아키텍처

## 날짜
2026-01-28

## 세션/프로젝트
Observability 연동 프로젝트 - luppiter_scheduler 개발

## 배운 것

### 1. 3단계 이벤트 처리 파이프라인

Luppiter Scheduler는 외부 이벤트를 처리할 때 3개의 독립적 Job으로 구성된 파이프라인 패턴을 사용합니다.

**파이프라인 흐름**:
```
매분 :00 → 수집 Job (CollectingJob)
         ↓
      임시 테이블 (cmon_event_info_tmp)
         ↓
매분 :20 → 취합 Job (CombiningJob)
         ↓
      메인 테이블 (cmon_event_info)
         ↓
매분 :50 → 알림 Job (NotificationJob)
         ↓
    Slack/Email 발송
```

**각 단계별 역할**:

| 단계 | Job | 시간 | 입력 | 처리 | 출력 |
|------|-----|------|------|------|------|
| 1 | Collecting | :00 | 외부 API | 데이터 정제/매핑 | cmon_event_info_tmp |
| 2 | Combining | :20 | cmon_event_info_tmp | SQL 프로시저 호출 | cmon_event_info |
| 3 | Notification | :50 | cmon_event_info | 시간 조건 필터링 | 알림 발송 |

### 2. 임시 테이블 설계의 이점

**왜 임시 테이블을 사용하는가?**

- **실패 격리**: 수집 실패 시 기존 데이터 유지
- **재처리 가능**: 임시 테이블에 데이터가 남아있으면 재처리 가능
- **성능**: 메인 테이블 락 시간 최소화
- **복잡한 로직 분리**: 정제 로직(Java)과 취합 로직(SQL)을 별개로 처리

**구현 패턴**:
```java
// Job 1: 외부 API → 임시 테이블
@Scheduled(cron = "0 0 * * * *")  // 매분 :00
public void collectEvents() {
    // 1. 외부 API 호출
    List<ExternalEvent> events = externalApiClient.getEvents();

    // 2. 데이터 정제/매핑
    List<CmonEventInfoTmp> mappedEvents = events.stream()
        .map(this::mapEvent)
        .toList();

    // 3. 임시 테이블에 INSERT
    cmonEventInfoTmpRepository.saveAll(mappedEvents);
}

// Job 2: 프로시저 호출
@Scheduled(cron = "0 20 * * * *")  // 매분 :20
public void combineEvents() {
    // 프로시저: cmon_event_info_tmp → cmon_event_info
    jdbcTemplate.execute("CALL p_combine_event_obs()");
}

// Job 3: 알림 발송
@Scheduled(cron = "0 50 * * * *")  // 매분 :50
public void notifyEvents() {
    // 최근 추가된 이벤트만 조회
    List<CmonEventInfo> recentEvents =
        cmonEventInfoRepository.findByLastOccuTime(getCurrentMinute());

    recentEvents.forEach(this::sendNotification);
}
```

### 3. 시간 조건 처리 시 주의사항

**문제 상황**: last_occu_time = 현재 분(YYYYMMDDHH24MI) 조건으로 인한 이벤트 누락

**원인 분석**:
```sql
-- 위험한 쿼리
SELECT * FROM cmon_event_info
WHERE last_occu_time = DATE_FORMAT(NOW(), '%Y%m%d%H%i');  -- 30초 이상 경과 시 누락

-- 안전한 쿼리
SELECT * FROM cmon_event_info
WHERE last_occu_time >= DATE_FORMAT(NOW() - INTERVAL 1 MINUTE, '%Y%m%d%H%i')
  AND last_occu_time < DATE_FORMAT(NOW(), '%Y%m%d%H%i');
```

**해결 방안**:
- **범위 조건 사용**: 정확한 일치(=) 대신 >= 와 < 사용
- **타임스탬프 활용**: DATETIME 컬럼 추가 (정밀도 향상)
- **상태 플래그**: 이미 발송한 이벤트는 notified_yn = 'N' 조건 추가
- **재시도 로직**: 누락된 이벤트를 따로 처리하는 별도 Job

**권장 방식**:
```java
// 상태 플래그 기반 처리
List<CmonEventInfo> eventsToNotify =
    cmonEventInfoRepository.findByNotifiedYnAndCreatedAtAfter(
        'N',  // 아직 알림 발송 안 함
        LocalDateTime.now().minusMinutes(2)  // 2분 이내 생성된 이벤트
    );

eventsToNotify.forEach(event -> {
    sendNotification(event);
    markAsNotified(event.getId());  // 발송 후 상태 변경
});
```

### 4. @Transactional 없이 프로시저 호출 시 auto-commit 동작

**핵심**: Spring의 @Transactional이 없으면 각 SQL 문이 자동 커밋됨

**예시 코드와 문제**:
```java
// 위험: @Transactional 없음
public void combineEvents() {
    // 1. DELETE 자동 커밋
    jdbcTemplate.execute("DELETE FROM cmon_event_info_tmp WHERE processed_yn = 'Y'");

    // 2. 프로시저 호출 자동 커밋
    jdbcTemplate.execute("CALL p_combine_event_obs()");

    // 3. 여기서 예외 발생 시 위 2개 작업은 이미 커밋됨
    throw new RuntimeException("Unexpected error");
}
```

**안전한 처리**:
```java
@Transactional  // 모든 작업이 한 트랜잭션으로 처리됨
public void combineEvents() {
    try {
        jdbcTemplate.execute("TRUNCATE TABLE cmon_event_info_tmp");
        jdbcTemplate.execute("CALL p_combine_event_obs()");
        // 성공 시 자동 커밋
    } catch (Exception e) {
        // 실패 시 자동 롤백
        log.error("Failed to combine events", e);
        throw new ProcessingException("Event combining failed", e);
    }
}
```

**추가 고려사항**:
- 프로시저가 자신의 트랜잭션을 관리하면 @Transactional과 별개 처리됨
- DDL (CREATE, ALTER, DROP)은 자동 커밋되므로 프로시저 내에서는 주의
- 프로시저 내 에러 처리가 중요 (RAISE EXCEPTION 사용)

## 적용 가능한 상황

1. **배치/스케줄러 개발**: 외부 데이터 수집 및 정제 작업
2. **실시간 알림 시스템**: 시간 기반 필터링이 필요한 경우
3. **대용량 데이터 처리**: 임시 테이블 + 프로시저 조합으로 성능 최적화
4. **트랜잭션 관리**: Spring @Transactional 동작 이해 필요
5. **타이밍 이슈 디버깅**: 시간 조건 필터링 문제 해결

## 핵심 체크리스트

Luppiter Scheduler 유형의 이벤트 처리 Job 작성 시:

- [ ] 외부 데이터는 임시 테이블로 수집 (재처리 가능성)
- [ ] 시간 조건은 정확한 일치 대신 범위 조건 사용
- [ ] 상태 플래그(notified_yn) 추가로 중복 발송 방지
- [ ] 모든 Job에 @Transactional 및 적절한 예외 처리
- [ ] 프로시저 내부에도 에러 처리 로직 포함
- [ ] Job 간 시간 간격 설정 확인 (:00 → :20 → :50)
- [ ] 로그: 각 단계 시작/완료 및 처리 건수 기록

## 참고 자료

- Observability 이벤트 스키마: `docs/learnings/007-observability-event-schema.md`
- Observability 설계문서: `docs/o11y/01-design.md`
- Observability DDL: `docs/o11y/02-ddl.sql`
- Observability ADR: `docs/decisions/003-observability-integration-design.md`
- Spring @Transactional: https://spring.io/guides/gs/managing-transactions/
