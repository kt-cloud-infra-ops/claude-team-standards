# 학습: Luppiter Web 코딩 표준

## 날짜
2026-01-19

## 프로젝트
luppiter-web, luppiter_web

## 출처 문서
- `projects/luppiter-web/docs/AI_CODING_GUIDELINES.md`
- `projects/luppiter_web/docs/Claude_코딩_룰북.md`
- `projects/luppiter_web/docs/README.md`

---

## 핵심 원칙

### 1. 모듈화 우선 (Modularity First)
- **단일 책임 원칙(SRP)**: 각 클래스/메서드는 하나의 책임만
- **도메인별 분리**: 기능별로 명확히 분리된 패키지 구조
- **의존성 최소화**: 모듈 간 의존성은 최소화하고 명확하게 정의

### 2. 레이어드 아키텍처
```
Controller → Service → Mapper → Database
    ↓          ↓         ↓
  DTO       Domain    Entity
```

### 3. 도메인 패키지 구조
```
com.framework
├── ctl          # 관제 관리
├── evt          # 이벤트 관리
├── icd          # 인시던트 관리
├── cst          # 고객 관리
├── dsb          # 대시보드
├── wrk          # 작업 관리
├── cmm          # 공통
└── web          # 웹 관련
```

---

## 코딩 규칙

### 네이밍
| 대상 | 규칙 | 예시 |
|------|------|------|
| 클래스 | PascalCase | `EvtServiceImpl` |
| 메서드 | camelCase + 동사 시작 | `selectEventList` |
| 변수 | camelCase | `eventList` |
| 상수 | UPPER_SNAKE_CASE | `SUCCESS_RES_CODE` |

### 메서드 설계
- **길이**: 최대 50줄
- **파라미터**: 최대 5개 (초과 시 DTO)
- **동사 구분**: `get`(캐시 등) vs `select`(DB 조회)

### 클래스 템플릿
```java
@Slf4j
@Service
@RequiredArgsConstructor
public class {Service명}Impl implements {Service명} {
    private final {Mapper명} {mapper변수명};

    @Override
    public {반환타입} {메서드명}({파라미터}) throws Exception {
        // 1. 파라미터 검증
        // 2. 비즈니스 로직
        // 3. 데이터 조회/저장
        // 4. 결과 반환
    }
}
```

---

## 테스트 규칙

### 테스트 피라미드
- **단위 테스트 (60%)**: Service, Controller
- **통합 테스트 (30%)**: 전체 플로우
- **E2E 테스트 (10%)**: 유저스토리 기반

### 테스트 구조
```java
@ExtendWith(MockitoExtension.class)
@DisplayName("{Service명} 단위 테스트")
class {Service명}ImplTest {
    @Mock
    private {Mapper명} mapper;

    @InjectMocks
    private {Service명}Impl service;

    @Test
    @DisplayName("그룹 목록 조회 - 정상 케이스")
    void selectGroupList_Success() throws Exception {
        // Given: 테스트 데이터 준비
        // When: 테스트 실행
        // Then: 결과 검증
    }
}
```

### 필수 테스트 케이스
1. `_Success` - 정상 케이스
2. `_Exception` - 예외 케이스
3. `_EmptyResult` - 빈 결과
4. `_Null`, `_Empty` - 경계값

### 검증 방법
- AssertJ: `assertThat(result).isNotNull()`
- Mock 호출: `verify(mapper, times(1)).selectList(any())`

---

## 예외 처리

```java
try {
    return evtMapper.selectEventList(map);
} catch (DataAccessException e) {
    log.error("이벤트 목록 조회 실패: {}", map, e);
    throw new BusinessException("이벤트 목록 조회 중 오류가 발생했습니다.", e);
}
```

---

## 로깅 레벨
- **ERROR**: 예외 발생, 시스템 오류
- **WARN**: 경고 상황, 비정상적인 상태
- **INFO**: 중요한 비즈니스 이벤트
- **DEBUG**: 디버깅 정보 (개발 환경에서만)

---

## 적용 시점
- luppiter-web 관련 프로젝트 작업 시 이 규칙 적용
- 새로운 Service/Controller 생성 시 템플릿 참고
- 테스트 코드 작성 시 필수 케이스 확인
