# 세션 미완료 작업 체크리스트 (2026-01-28)

## 📋 요약

| 구분 | 항목 수 | 상태 | 우선순위 |
|------|--------|------|---------|
| 즉시 조치 | 14개 | ⏳ 대기 | 🔴 P1 |
| 단기 개선 | 8개 | ⏳ 대기 | 🟡 P2 |
| 장기 개선 | 12개 | ⏳ 대기 | 🟢 P3 |
| **합계** | **34개** | | |

---

## 🔴 즉시 조치 (이번 주) - 운영 안정화

### Phase 1: Zabbix 테이블 정리

#### 사전 작업
- [ ] DBA에게 실행 계획 검토 요청
- [ ] 운영팀과 실행 일정 협의 (가능한 트래픽 낮은 시간대 선택)
- [ ] 테스트 DB에서 사전 실행 및 검증

#### 실행 작업
- [ ] SQL 쿼리 1: Zabbix Job 중지 (ES0001~ES0005)
  ```sql
  UPDATE c01_batch_event SET use_yn = 'N'
  WHERE system_code IN ('ES0001', 'ES0002', 'ES0003', 'ES0004', 'ES0005');
  ```
- [ ] SQL 쿼리 2: x01_if_event_data DROP 및 재생성 (18줄)
  - 인덱스 3개 포함
- [ ] SQL 쿼리 3: Zabbix Job 재시작

#### 검증
- [ ] CombineEventServiceJob 실행 시간 모니터링 (30분)
- [ ] 취합 시간이 10초대로 개선됨 확인
- [ ] 에러 로그 확인

**소요 시간**: 약 1분
**담당**: DBA + 운영팀
**완료 기준**: 취합 시간 10초대

---

### Phase 2: Zenius 테이블 정리

#### 사전 작업
- [ ] Phase 1 완료 후 진행 (기존 트래픽이 정상화된 후)
- [ ] 운영팀 공지

#### 실행 작업
- [ ] SQL 쿼리 1: Zenius Job 중지 (ES0006)
  ```sql
  UPDATE c01_batch_event SET use_yn = 'N'
  WHERE system_code = 'ES0006';
  ```
- [ ] SQL 쿼리 2: x01_if_event_zenius DROP 및 재생성 (20줄)
  - **누락된 인덱스 2개 추가** (중요!)
- [ ] SQL 쿼리 3: Zenius Job 재시작

#### 검증
- [ ] CombineEventServiceJob 재확인 (30분)
- [ ] 알림 발송 상태 모니터링

**소요 시간**: 약 1분
**담당**: DBA + 운영팀
**완료 기준**: 취합 시간 유지 (10초대), 알림 누락 해소

---

### 공지 및 커뮤니케이션
- [ ] Slack #luppiter 채널에 작업 공지
  - 시작 시간
  - 예상 소요 시간 (2분)
  - 영향 범위 (알림 발송 지연 예상)
- [ ] 작업 완료 후 결과 공지
  - 취합 시간 개선 결과
  - 알림 누락 해소 확인

---

## 🟡 단기 개선 (2월 중) - 재발 방지

### CleanupIfEventDataJob 개발

#### 요구사항 정리
- [ ] 정리 대상 테이블 확정
  - x01_if_event_data
  - x01_if_event_zenius
- [ ] 보관 기간 정책 확인
  - 권장: 7일 (또는 30일 검토)
- [ ] 실행 시간 정책
  - 권장: 매일 03:00 (트래픽 낮은 시간)
- [ ] 실행 순서 확정
  - 데이터 삭제 → 통계 갱신(ANALYZE)

#### 구현 작업
- [ ] Java 클래스 작성: `CleanupIfEventDataJob`
  - AbstractBatchJob 상속
  - @Scheduled(cron = "0 0 3 * * ?")
  - execute() 메서드 구현
- [ ] Mapper SQL 작성 (3개)
  - deleteOldIfEventData(days)
  - deleteOldIfEventZenius(days)
  - analyzeIfEventTables()
- [ ] 설정 값 외부화
  - RETENTION_DAYS 상수화 또는 설정 파일

#### 테스트 작업
- [ ] 단위 테스트 작성
  - deleteOldIfEventData 호출 검증
  - deleteOldIfEventZenius 호출 검증
  - analyzeIfEventTables 호출 검증
- [ ] 통합 테스트 작성
  - 테스트 데이터 생성
  - 실제 삭제 동작 검증
  - 통계 갱신 후 성능 개선 확인

#### 코드 리뷰 및 배포
- [ ] 코드 리뷰 (보안, 성능, 가독성)
- [ ] 스케줄러 배포 계획에 포함
- [ ] STG 배포 및 1주 모니터링
- [ ] PRD 배포

**소요 시간**: 약 1일 (개발 + 테스트)
**담당**: 1명 (Senior/Mid Developer)
**참고 자료**: `docs/temp/luppiter-scheduler-event-combine-improvement.md` 라인 140~180

---

## 🟢 장기 개선 (2월 중순~) - 근본 개선

### Java 로직 전환 (프로시저 → Java)

#### 1단계: 인터페이스 설계

- [ ] `IEventCombineService` 인터페이스 정의
  - combine(systemCode) 메서드
  - CombineResult DTO 정의 (systemCode, newEventCount, resolvedEventCount, elapsedTimeMs, success, errorMessage)
- [ ] 디자인 패턴 결정 (Strategy pattern)

**소요 시간**: 0.5일
**참고**: `docs/temp/luppiter-scheduler-event-combine-improvement.md` 라인 215~235

---

#### 2단계: ZabbixEventCombineService 구현

- [ ] 클래스 구조 설계
  - @Service + @RequiredArgsConstructor 적용
  - @Slf4j로 로깅
  - @Transactional 처리
- [ ] processNewEvents() 메서드
  - 신규 이벤트 조회 (findNewEvents)
  - 인벤토리 매핑 (convertToEventInfo)
  - 배치 INSERT (batchInsert)
  - 대응관리 정보 입력 (insertRespManageInfo)
- [ ] processResolvedEvents() 메서드
  - recovery_dst_id 매칭으로 해소 처리
- [ ] 예외 처리 및 로깅
  - 인벤토리 미매칭 시 로깅
  - 에러 발생 시 CombineResult 반환

**소요 시간**: 3일
**참고**: `docs/temp/luppiter-scheduler-event-combine-improvement.md` 라인 269~385

---

#### 3단계: ZeniusEventCombineService 구현

- [ ] 클래스 구조 (ZabbixEventCombineService와 유사)
- [ ] processNewEvents() 메서드
  - Zenius 이벤트 특화 로직 (z_myip, z_myid 기반 매핑)
- [ ] processResolvedEvents() 메서드
  - "인터페이스 데이터 미존재 시 해소" 로직
- [ ] 예외 처리

**소요 시간**: 2일

---

#### 4단계: EventCombineOrchestrator 구현

- [ ] 병렬 처리 구현
  - CompletableFuture 사용
  - 6개 시스템 동시 처리
- [ ] combineAll(configs) 메서드
  - futures 스트림 생성
  - CompletableFuture.allOf()로 모두 완료 대기
  - 결과 리스트 반환
- [ ] 타임아웃 처리 (선택)
  - 시스템별 타임아웃 설정
  - 전체 타임아웃 설정

**소요 시간**: 1day
**참고**: `docs/temp/luppiter-scheduler-event-combine-improvement.md` 라인 240~267

---

#### 5단계: 테스트 작성

- [ ] 단위 테스트 (80%+ 커버리지)
  - ZabbixEventCombineService 테스트
  - ZeniusEventCombineService 테스트
  - EventCombineOrchestrator 테스트 (병렬 처리)
  - Mock 객체 사용 (Mapper, Service)
- [ ] 통합 테스트
  - DB 트랜잭션 처리 검증
  - 신규/해소 이벤트 처리 검증
- [ ] 성능 테스트
  - 병렬 vs 순차 시간 비교
  - 목표: 순차(36s) → 병렬(6~8s)

**소요 시간**: 2일

---

#### 6단계: STG 배포 및 검증

- [ ] STG 환경 배포
- [ ] 1주 모니터링
  - CombineEventServiceJob 실행 시간
  - 신규/해소 이벤트 처리 결과
  - 알림 발송 상태
- [ ] 성능 개선 정량 검증

**소요 시간**: 1day (실제는 1주 모니터링)

---

#### 7단계: PRD 배포

- [ ] 배포 전 체크리스트 확인
  - 모든 테스트 통과
  - 성능 개선 확인
  - 코드 리뷰 완료
- [ ] 배포 일정 협의 (운영팀)
- [ ] 배포 진행
- [ ] 배포 후 모니터링 (2시간)

**소요 시간**: 1day

---

### 전체 일정

| 주차 | 작업 | 기간 | 담당 |
|------|------|------|------|
| 2월 1~2주 | 클래스/메서드 설계 | 1일 | Developer |
| 2월 1~2주 | ZabbixEventCombineService | 3일 | Developer |
| 2월 2~3주 | ZeniusEventCombineService | 2일 | Developer |
| 2월 2주 | EventCombineOrchestrator | 1일 | Developer |
| 2월 2~3주 | 단위/통합 테스트 | 2일 | QA/Developer |
| 2월 3주 | STG 배포 + 검증 | 1day + 1week | QA/DevOps |
| 2월 4주 | PRD 배포 | 1day | DevOps |
| **전체** | | **11일** | **1 Senior Developer** |

---

### DB 파티션 검토 (병렬 진행)

- [ ] DBA와 협의 일정 확정
- [ ] 파티션 전략 논의
  - Range 파티션 (월별 vs 일별)
  - 보관 정책 (7일 vs 30일)
  - 성능 영향 분석
- [ ] 파티션 DDL 작성
- [ ] 테스트 환경에서 검증
- [ ] 프로덕션 적용 계획 수립

**상태**: 🔵 진행 중 (DBA 협의)
**담당**: DBA 주도
**완료 기한**: 2월 말

---

## 📊 미사용 테이블 정리 (부가 과제)

세션 중 식별된 미사용 테이블 24개 (총 78개 중 31%)

### 즉시 삭제 가능 (🟢 낮은 리스크)
- [ ] inventory_master_excel
- [ ] inventory_master_form
- [ ] cmon_refine_event_history
- [ ] cmon_login_log
- [ ] cmon_user_sessions
- [ ] event_received_message
- [ ] message_send_log
- [ ] sms_send_message
- [ ] agent_message
- [ ] cmon_agent_target_list
- [ ] cmon_event_group
- [ ] cmon_resp_lv_info
- [ ] p04_slack_event_targets
- [ ] cmon_incident_contact

**담당**: DBA
**우선순위**: 🟢 P4 (선택사항)
**참고**: `docs/temp/temp-db-table-analysis.md` 참고

---

## 📝 문서 참고

### 세션 분석 결과
- **주 분석 문서**: `/Users/jiwoong.kim/Documents/claude/docs/decisions/004-luppiter-scheduler-event-combine-performance-session.md`
- **상세 분석**: `docs/temp/luppiter-scheduler-issue-report.md`
- **구현 가이드**: `docs/temp/luppiter-scheduler-event-combine-improvement.md`
- **DB 테이블 분석**: `docs/temp/temp-db-table-analysis.md`

### 프로젝트 파일
| 파일 | 경로 | 용도 |
|------|------|------|
| CombineEventServiceJob.java | `luppiter_scheduler/.../CombineEventServiceJob.java` | 현재 구현 (순차 처리) |
| p_combine_event_zabbix.sql | `luppiter_scheduler/DDML/p_combine_event_zabbix.sql` | Zabbix 프로시저 (전환 대상) |
| p_combine_event_zenius.sql | `luppiter_scheduler/DDML/p_combine_event_zenius.sql` | Zenius 프로시저 (전환 대상) |
| [DDL]Luppiter_Scheduler.sql | `luppiter_scheduler/DDML/[DDL]Luppiter_Scheduler.sql` | 테이블 정의 |

---

## 🎯 성공 기준

### Phase 1~2 완료 (즉시 조치)
✅ **취합 시간**: 36s → 10초대
✅ **알림 누락**: 해소
✅ **운영 영향**: 최소 (전체 2분 중단)

### CleanupIfEventDataJob 배포 (단기)
✅ **임시 테이블 크기**: 안정적 유지 (일정 크기 이상 증가 안 함)
✅ **정리 Job**: 매일 자동 실행

### Java 로직 전환 완료 (장기)
✅ **취합 시간**: 10초대 → 6~8초
✅ **프로시저 의존도**: 0%
✅ **테스트 커버리지**: 80%+
✅ **배포 안정성**: 무중단 배포

---

## 📌 다음 세션 준비물

1. **DBA 검토 완료된 SQL 스크립트**
   - x01_if_event_data DROP/재생성 쿼리
   - x01_if_event_zenius DROP/재생성 쿼리

2. **CombineEventServiceJob 로그 준비**
   - 현재 실행 시간 기록 (기준선)
   - Phase 1 후 개선 정도 확인용

3. **CleanupIfEventDataJob 요구사항 명세**
   - 정리 대상, 보관 기간, 실행 시간 확정

4. **Java 로직 전환 우선순위**
   - Zabbix vs Zenius 중 먼저 할 시스템 결정

