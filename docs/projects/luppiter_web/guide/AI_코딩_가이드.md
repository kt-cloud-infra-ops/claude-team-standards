# Luppiter Web AI 코딩 가이드

## 개요

AI 도구(Cursor, Copilot, Claude)가 Luppiter Web 코드 작성 시 참고하는 프로젝트 고유 규칙.

> 공통 코딩 스타일은 `CLAUDE.md` 참조

---

## 설정 파일 위치

| 파일 | 용도 |
|------|------|
| `.cursorrules` | Cursor AI 규칙 |
| `.github/copilot-instructions.md` | GitHub Copilot 가이드 |
| `src/test/java/com/framework/test/TestTemplate.java` | 테스트 코드 템플릿 |

---

## 테스트 코드 작성 규칙

### 테스트 클래스 구조

```java
@ExtendWith(MockitoExtension.class)
@DisplayName("{Service명} 단위 테스트")
class {Service명}ImplTest {
    @Mock
    private {Mapper명} {mapper변수명};

    @InjectMocks
    private {Service명}Impl {service변수명};

    @BeforeEach
    void setUp() {
        // 공통 설정
    }
}
```

### 테스트 메서드 구조

```java
@Test
@DisplayName("그룹 목록 조회 - 정상 케이스")
void selectGroupList_Success() throws Exception {
    // Given: 테스트 데이터 준비
    Map<String, Object> params = TestDataBuilder.buildGroupParams();
    when(ctlMapper.selectGroupList(any())).thenReturn(expectedList);

    // When: 테스트 실행
    List<Map<String, Object>> result = ctlService.selectGroupList(params);

    // Then: 결과 검증
    assertThat(result).isNotNull();
    assertThat(result).hasSize(2);
    verify(ctlMapper).selectGroupList(any());
}
```

### 네이밍 규칙

| 항목 | 규칙 | 예시 |
|------|------|------|
| 테스트 메서드 | `{메서드명}_{시나리오}` | `selectGroupList_Success` |
| @DisplayName | 한글 설명 | `"그룹 목록 조회 - 정상 케이스"` |
| 테스트 클래스 | `{Service명}ImplTest` | `EvtServiceImplTest` |

---

## TestDataBuilder 사용

```java
// 기본 파라미터
Map<String, Object> params = TestDataBuilder.buildBasicParams();

// 이벤트 파라미터
Map<String, Object> eventParams = TestDataBuilder.buildEventParams();

// 페이징 파라미터
Map<String, Object> pagingParams = TestDataBuilder.buildPagingParams(1, 20);
```

---

## 프로젝트 구조

```
src/main/java/com/framework/
├── cmm/          # 공통
├── ctl/          # 사용자/그룹 관리
├── evt/          # 이벤트 관리
├── icd/          # 인시던트 관리
├── dashboard/    # 대시보드
├── mtn/          # 메인터넌스
└── spt/          # 지원 관리

src/test/java/com/framework/
├── evt/service/  # 이벤트 서비스 테스트
├── icd/service/  # 인시던트 서비스 테스트
└── test/         # 테스트 유틸 (TestDataBuilder 등)
```

---

## 주의사항

1. **Mapper는 Mock 처리**: DB 연결 없이 단위 테스트
2. **Given-When-Then 패턴 필수**: 주석으로 구분
3. **TestDataBuilder 활용**: 테스트 데이터 중복 방지
4. **@DisplayName 한글**: 테스트 목적 명확히

---

**최종 업데이트**: 2026-01-30
