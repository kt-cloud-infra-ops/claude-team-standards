# 세션 정리: Luppiter Scheduler 이벤트 취합 성능 이슈 (2026-01-28)

## 세션 요약

Luppiter Scheduler의 `CombineEventServiceJob` 성능 저하 문제에 대해 분석하고 즉시/장기 개선 방안을 수립한 세션입니다.

**기간**: 2026-01-28
**주제**: 이벤트 취합 Job 실행시간 증가(13.9s → 28.2s → 36s) 및 알림 누락 이슈
**상태**: 분석 완료, 즉시 조치 대기, 장기 개선 계획 수립

---

## 1. 문제 정의

### 현황
- **Job**: CombineEventServiceJob (매분 :20 실행)
- **정상 소요시간**: 10~15초
- **현재 소요시간**: 28초 → 36초 (증가 추세)
- **영향**: 알림 발송 지연/누락 (취합/알림 시간 겹침)

### 원인 (3가지)
1. **순차 처리**: 6개 시스템을 순차적으로 처리 (병렬 처리 안 함)
2. **임시 테이블 누적**: ~7GB씩 계속 증가 (정기 정리 없음)
3. **누락된 인덱스**: x01_if_event_zenius에 인덱스 없음

---

## 2. 미완료 작업 (TODO)

### Track 1: 즉시 조치 (DB 작업) - 우선순위 🔴 높음

#### Phase 1: Zabbix 테이블 정리
- [ ] Zabbix Job만 중지 (ES0001~ES0005)
- [ ] `x01_if_event_data` DROP 및 재생성
  - 새 인덱스 3개 포함
  - 소요시간: ~1분
- [ ] Zabbix Job 재시작
- [ ] CombineEventServiceJob 실행 시간 확인

**실행 시점**: 최대한 빠르게 (운영 안정성 우선)
**담당**: DBA + 운영팀

#### Phase 2: Zenius 테이블 정리
- [ ] Zenius Job만 중지 (ES0006)
- [ ] `x01_if_event_zenius` DROP 및 재생성
  - 인덱스 추가 (현재 없음)
  - 소요시간: ~1분
- [ ] Zenius Job 재시작

**실행 시점**: Phase 1 완료 후 진행
**담당**: DBA + 운영팀

**예상 효과**:
- 임시 테이블 크기 초기화
- 취합 소요시간: 36초 → 10초대로 개선
- 알림 누락 즉시 해소

---

### Track 2: 장기 개선 (개발 작업) - 우선순위 🟡 중간

#### 2.1 주기적 정리 Job 개발
- [ ] `CleanupIfEventDataJob` 구현
  - 매일 03:00 실행
  - x01_if_event_data, x01_if_event_zenius에서 7일 이상 데이터 삭제
  - 테이블 통계 갱신 (ANALYZE)
- [ ] Mapper/SQL 작성
- [ ] 테스트

**적용 시점**: 스케줄러 다음 배포 시
**관련 파일**: `docs/temp/luppiter-scheduler-event-combine-improvement.md` 참고
**소요시간**: 1일 (개발 + 테스트)

#### 2.2 DB 파티션 검토
- [ ] DBA와 협의 진행
  - 대상: x01_if_event_data, x01_if_event_zenius
  - 전략: Range 파티션 (일별/월별)
  - 장점: DROP으로 즉시 정리, 파티션 프루닝 성능 향상
- [ ] 파티션 DDL 작성 및 검증

**상태**: 🔵 진행 중 (DBA 협의 중)
**담당**: DBA 주도
**기간**: 미정

#### 2.3 Java 로직 전환 (프로시저 → Java)
- [ ] `IEventCombineService` 인터페이스 정의
- [ ] `ZabbixEventCombineService` 구현
  - p_combine_event_zabbix 로직 전환
  - 신규/해소 이벤트 처리
  - 인벤토리 매핑, 예외 처리 포함
- [ ] `ZeniusEventCombineService` 구현
  - p_combine_event_zenius 로직 전환
- [ ] `EventCombineOrchestrator` 구현
  - CompletableFuture로 병렬 처리
  - 6개 시스템 동시 실행

**기대 효과**:
- 속도 3~4배 개선
- 단위 테스트 가능
- 유지보수성 향상

**구현 계획** (상세 일정):
| 단계 | 작업 | 기간 |
|-----|------|------|
| 1 | 인터페이스 설계 | 1일 |
| 2 | ZabbixEventCombineService | 3일 |
| 3 | ZeniusEventCombineService | 2일 |
| 4 | EventCombineOrchestrator + 병렬 | 1일 |
| 5 | 단위/통합 테스트 | 2일 |
| 6 | STG 배포 + 검증 | 1일 |
| 7 | PRD 배포 | 1일 |
| **전체** | | **11일** |

**소요 리소스**: 1명 (Senior Developer)

---

## 3. 발견된 개선점

### 3.1 순차 처리 문제
```java
// AS-IS: 순차 처리
for(Map<String, String> map : batchMapList) {  // 6개 시스템
    eventBatchMapper.combineEventForZabbix(combineParams);
}

// TO-BE: 병렬 처리 (목표)
CompletableFuture.allOf(
    futures.stream()
        .map(config -> CompletableFuture.supplyAsync(() ->
            combineService.combine(config.getSystemCode())
        ))
        .toArray(new CompletableFuture[0])
).join();
```

**예상 성능**: 순차(36s) → 병렬(6~8s)

### 3.2 임시 테이블 관리 전략
**현재**: 정리 없이 누적 (계속 증가)
**개선**:
1. 단기: DROP/재생성 (즉시 조치)
2. 중기: 주기적 정리 Job (CleanupIfEventDataJob)
3. 장기: DB 파티션 (DBA 협의)

### 3.3 기술 부채
- 프로시저 기반 로직 → Java 서비스로 전환 필요
- 이유: 테스트 어려움, 유지보수성 낮음, 성능 최적화 제한

---

## 4. 다음 세션 우선순위

### 🔴 P1: 즉시 조치 (이번 주)
1. Phase 1: Zabbix 테이블 DROP/재생성 실행
2. Phase 2: Zenius 테이블 DROP/재생성 실행
3. 모니터링: CombineEventServiceJob 실행 시간 확인

**담당**: DBA + 운영팀
**완료 기준**: 취합 시간이 10초대로 돌아옴

---

### 🟡 P2: 단기 개선 (2월)
1. CleanupIfEventDataJob 개발 및 테스트
2. 스케줄러 배포 시 함께 적용

**담당**: 개발팀
**완료 기준**: 임시 테이블이 일정 크기 이상 증가 안 함

---

### 🟢 P3: 장기 개선 (2월 중순~)
1. DBA와 파티션 구현 협의
2. Java 로직 전환 계획 수립
3. EventCombineOrchestrator 설계/구현

**담당**: 개발팀 + DBA
**완료 기준**: 프로시저 의존도 제거, 병렬 처리 구현

---

## 5. 참고 자료

### 생성된 문서
- `docs/temp/luppiter-scheduler-issue-report.md` - 상세 분석 및 즉시 조치 SQL
- `docs/temp/luppiter-scheduler-event-combine-improvement.md` - 장기 개선 계획 및 구현 코드 스켈레톤
- `docs/temp/temp-db-table-analysis.md` - DB 테이블 현황 분석 (미사용 테이블 24개 식별)

### 주요 관련 파일 (프로젝트)
| 파일 | 경로 | 용도 |
|------|------|------|
| CombineEventServiceJob | `luppiter_scheduler/.../CombineEventServiceJob.java` | 현재 구현 |
| p_combine_event_zabbix | `luppiter_scheduler/DDML/p_combine_event_zabbix.sql` | 프로시저 (전환 대상) |
| p_combine_event_zenius | `luppiter_scheduler/DDML/p_combine_event_zenius.sql` | 프로시저 (전환 대상) |
| DDL | `luppiter_scheduler/DDML/[DDL]Luppiter_Scheduler.sql` | 테이블 정의 |

---

## 6. 예상 효과 (Timeline)

```
현재(2026-01-28)
  ↓ [즉시 조치]
이번 주 (2026-02-03)
  - 취합 시간: 36s → 10s ✅
  - 알림 누락: 해소 ✅
  ↓ [단기 개선]
2월 중순 (2026-02-13)
  - CleanupIfEventDataJob 배포
  - 임시 테이블 크기 제어 ✅
  ↓ [장기 개선]
2월 말 (2026-02-27)
  - 파티션 검토 완료
  - Java 로직 전환 시작
  ↓ [최종]
3월 (2026-03-00)
  - 프로시저 → Java 전환 완료
  - 병렬 처리 구현
  - 성능: 10s → 6~8s 예상 ✅
```

---

## 7. 체크리스트

### 즉시 조치
- [ ] DBA에게 SQL 검토 요청
- [ ] 운영팀과 실행 일정 협의
- [ ] 테스트 DB에서 사전 실행
- [ ] 본 DB DROP/재생성 (Phase 1)
- [ ] CombineEventServiceJob 모니터링 (30분)
- [ ] Phase 2 실행
- [ ] 재모니터링 (30분)
- [ ] Slack 공지 (완료)

### 장기 개선 - CleanupIfEventDataJob
- [ ] 요구사항 정리
- [ ] Mapper/SQL 코딩
- [ ] 단위 테스트 작성
- [ ] 통합 테스트
- [ ] 코드 리뷰
- [ ] 스케줄러 배포에 포함

### 장기 개선 - Java 로직 전환
- [ ] IEventCombineService 인터페이스 설계
- [ ] ZabbixEventCombineService 구현
- [ ] ZeniusEventCombineService 구현
- [ ] EventCombineOrchestrator 구현
- [ ] 단위 테스트 (80%+ 커버리지)
- [ ] STG 배포 및 검증
- [ ] PRD 배포

---

## 부록: 미사용 테이블 정리 계획

세션 중 식별된 미사용 테이블 24개 (총 78개 테이블 중 31%)

**권장 조치**:
1. 🟢 낮은 리스크 14개 - 즉시 삭제 가능
2. 🟡 중간 리스크 7개 - 외부 시스템 담당자 확인 후 삭제
3. 🟠 높은 리스크 3개 - FK 확인 후 순서대로 삭제

자세한 내용: `docs/temp/temp-db-table-analysis.md` 참고

