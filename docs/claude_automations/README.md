# 자동화 패턴 (Automation Patterns)

세션 중 발견되고 반복되는 작업들을 분석하여 자동화 가능한 패턴으로 문서화합니다.

## 발견 현황

| # | 패턴 | 설명 | 우선순위 | 상태 | 예상 효과 |
|---|------|------|---------|------|---------|
| 001 | SQL 프로시저 분석 | 프로시저의 구조와 성능 특성 자동 분석 | **HIGH** | 설계 완료 | 80% 시간 단축 |
| 002 | Java Job 분석 | 배치 작업 클래스의 복잡도와 안전성 분석 | **HIGH** | 설계 완료 | 70% 시간 단축 |
| 003 | 성능 이슈 문서 | 성능 이슈 분석 보고서 템플릿 | **MEDIUM** | 설계 완료 | 66% 시간 단축 |
| 004 | SQL DDL 생성 | 테이블 DDL 자동 생성 및 마이그레이션 | **HIGH** | 설계 완료 | 90% 시간 단축 |
| 005 | Playwright E2E 테스트 | 테스트 워크플로우 및 스크린샷/트레이스 관리 | **MEDIUM** | 설계 완료 | 75% 시간 단축 |
| 006 | 규칙 파일 교차참조 | 루트 규칙 파일 간 자동 관계 매핑 및 동기화 | **MEDIUM** | 설계 완료 | 95% 시간 단축 |

## 세션 통계

### 활동 패턴
```
📅 최근 10일 세션 분포
  2026-01-19: 39 sessions
  2026-01-20: 38 sessions
  2026-01-21: 27 sessions
  2026-01-23: 39 sessions
  2026-01-27: 36 sessions

⏰ 시간대별 활동 (전체 196개 이벤트)
  오전 (08-11): ████████████████████ 53% (104개)
  오후 (12-16): ██████████ 32% (62개)
  저녁 (17-19): █████ 15% (30개)

📊 프로젝트별 활동
  projects (claude): 3,508 entries (93.7MB)
  일반 프로젝트: 944 entries
  총합: 4,452 entries
```

## 다음 단계

### Phase 1: 우선순위 HIGH (1주)
1. SQL 프로시저 분석 도구 개발
   - [ ] 파이썬 분석 스크립트 작성
   - [ ] 슬래시 커맨드 통합
   - [ ] 테스트 (p_combine_event_obs)

2. Java Job 분석 체크리스트 준비
   - [ ] 체크리스트 템플릿 마크다운화
   - [ ] 정적 분석 스크립트 개발
   - [ ] ObservabilityEventWorker 테스트

3. SQL DDL 생성 도구 개발
   - [ ] Python 스크립트 완성
   - [ ] 마이그레이션 자동화
   - [ ] 검증 쿼리 생성

### Phase 2: 우선순위 MEDIUM (2주)
1. 성능 이슈 분석 자동화
   - [ ] 슬래시 커맨드 개발
   - [ ] 지라 이슈 템플릿 연동
   - [ ] 메트릭 자동 수집

2. 통합 CLI 도구 개발
   - [ ] 모든 도구 통합
   - [ ] 웹 UI 개발 (선택)
   - [ ] 결과 저장소 구축

## 패턴별 상세 정보

### 001 - SQL 프로시저 분석
**파일**: [`001-sql-procedure-analysis.md`](./001-sql-procedure-analysis.md)

세션 중 동일한 구조의 프로시저를 여러 개 분석:
- 프로시저 파일 파싱
- 테이블 의존성 추출
- 성능 특성 분석 (LOOP 개수, JOIN 수)
- Markdown 보고서 생성

**예시**: `p_combine_event_zabbix`, `p_combine_event_zenius`, `p_combine_event_obs`

### 002 - Java Job 분석
**파일**: [`002-java-job-analysis.md`](./002-java-job-analysis.md)

배치 작업 클래스의 체계적 분석:
- 구조 파악 (메서드, 의존성)
- 복잡도 계산
- 외부 호출 분석
- 에러 처리 검증
- 리소스 정리 확인

**예시**: `CombineEventServiceJob`, `EventAlarmServiceJob`, `ObservabilityEventWorker`

### 003 - 성능 이슈 문서
**파일**: [`003-performance-issue-doc.md`](./003-performance-issue-doc.md)

표준화된 성능 이슈 분석 템플릿:
- 시스템 컨텍스트
- 타임라인 (발생 ~ 해결)
- 5W1H 원인 분석
- 즉시 조치 항목
- 장기 개선 계획
- 모니터링 규칙

**예시**: 이벤트 결합 timeout 문제

### 004 - SQL DDL 생성
**파일**: [`004-sql-ddl-generator.md`](./004-sql-ddl-generator.md)

데이터베이스 테이블 자동 생성 및 관리:
- 스키마 분석
- CREATE/DROP 문 생성
- 마이그레이션 스크립트 작성
- 검증 쿼리 생성
- 정리(cleanup) 작업 자동화

**예시**: `cmon_event_info`, `cmon_service_inventory_master` 테이블 정리

### 005 - Playwright E2E 테스트 워크플로우
**파일**: [`005-playwright-e2e-test-workflow.md`](./005-playwright-e2e-test-workflow.md)

엔드투엔드 테스트 자동화 및 결과 관리:
- 테스트 케이스 템플릿 생성
- 스크린샷 자동 캡처
- 트레이스 파일 관리
- 비디오 녹화 자동화
- 아티팩트 업로드/정리

**예시**: luppiter_web 인증 흐름 E2E 테스트

### 006 - 규칙 파일 교차참조 및 동기화
**파일**: [`006-cross-reference-rules-automation.md`](./006-cross-reference-rules-automation.md)

Claude Code 규칙 파일 간 자동 관계 매핑 및 동기화:
- 규칙 파일 간 "Related Rules" 섹션 자동 생성
- 키워드 기반 관계 매핑
- 양방향 파일 동기화 (홈 ↔ 프로젝트)
- 관계 맵 메타데이터 관리

**패턴**:
- 8개 규칙 파일에 동일 구조의 교차참조 섹션 추가
- `related-rules-map.json` 메타데이터 생성
- 자동 동기화 스크립트로 일관성 유지

**예시**: `agents.md`, `testing.md`, `security.md` 간 관계 정의

## 활용 방법

### 슬래시 커맨드 사용 (향후)
```bash
# SQL 프로시저 분석
/analyze-sql-proc p_combine_event_obs

# Java Job 분석
/analyze-java-job src/main/java/com/kt/job/ObservabilityEventWorker.java

# 성능 이슈 문서
/analyze-perf-issue --title "Event Timeout" --component CombineEventServiceJob

# DDL 생성
/generate-ddl cmon_event_info cleanup
```

### 수동 스크립트 사용 (현재)
```bash
# SQL 프로시저 분석
python3 sql_procedure_analyzer.py src/main/resources/sql/p_combine_event_obs.sql

# Java Job 분석
python3 job_analyzer.py src/main/java/com/kt/job/ObservabilityEventWorker.java

# DDL 생성
python3 ddl_generator.py analyze cmon_event_info
```

## 관련 프로젝트

- **luppiter-web**: Java 배치 처리, 이벤트 통합
- **luppiter_scheduler**: 프로시저 기반 스케줄 작업
- **morning_report**: 성능 최적화 필요
- **zabbix_api**: 모니터링 데이터 수집

## 문서 구조

```
docs/claude_automations/
├── README.md (이 파일)
├── 000-template.md (템플릿)
├── 001-sql-procedure-analysis.md
├── 002-java-job-analysis.md
├── 003-performance-issue-doc.md
├── 004-sql-ddl-generator.md
├── 005-playwright-e2e-test-workflow.md
├── 006-cross-reference-rules-automation.md
├── 007-implementation-guide.md
└── 008-session-analysis.md
```

## 기여 방법

새로운 패턴 발견 시:
1. `000-template.md` 복사
2. 파일명: `NNN-pattern-name.md` 형식
3. 상세 정보 작성
4. 이 README 업데이트

## 참고 자료

- **메인 프로젝트 지침**: `CLAUDE.md`
- **학습 내용**: `docs/claude_lessons_learned/`
- **의사결정 기록**: `docs/decisions/`
- **서비스 문서**: `docs/service/`

---

**마지막 업데이트**: 2026-01-30
**다음 검토 예정**: 2026-02-06 (일주일 후)
