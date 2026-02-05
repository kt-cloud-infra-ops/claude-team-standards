# 세션 요약: 설비권한그룹 E2E 테스트 개발 (2026-01-30)

## 개요

**Luppiter Web E2E 프로젝트**에서 설비권한그룹(Permission Group) 관리 기능에 대한 포괄적인 E2E 테스트를 구현하고, UI/데이터 상태 검증을 위한 유틸리티를 개선했습니다.

**테스트 결과**: 108개 테스트 통과 / 12개 스킵 / **1개 버그 검출**

---

## 완료된 작업

### 1. 설비권한그룹 CRUD 테스트 구현

**파일**: `/Users/jiwoong.kim/Documents/claude/projects/luppiter_web_e2e/tests/e2e/permission-group.spec.ts`

설비권한그룹 관리의 전체 생명주기를 검증하는 4개의 테스트 케이스를 추가했습니다:

#### 1.1 그룹 생성 테스트 (Create)
- **테스트명**: "1. 설비권한그룹 등록 (생성)"
- **검증 항목**:
  - 그룹 등록 버튼 (왼쪽 패널) 표시 확인
  - 팝업에서 그룹명 입력 가능 여부
  - 그룹 저장 성공 여부
  - 저장 후 팝업 자동 닫힘 확인

#### 1.2 사용자 추가 테스트 (Create/Add)
- **테스트명**: "2. 설비권한그룹에 사용자 추가 - 팝업 사용자 목록 검증"
- **검증 항목**:
  - 그룹 선택 후 오른쪽 패널에 사용자 추가 버튼 표시 확인
  - 사용자 추가 팝업 열림 확인
  - **핵심**: 팝업 내 사용자 목록(테이블)이 정상적으로 렌더링되는지 확인
  - 사용자 목록이 최소 1개 이상의 행을 포함해야 함을 검증

#### 1.3 버그 검출 테스트 (Read with Bug Detection)
- **테스트명**: "3. [BUG] 그룹 선택 시 오른쪽 사용자 목록 표시 검증"
- **검증 항목**:
  - 사용자가 있는 그룹(예: "Cloud NW운영팀-EPC-NW", 6명) 선택
  - 오른쪽 패널에 해당 그룹의 사용자 목록이 표시되는지 확인
  - "No data" 메시지 표시 여부 감지 (버그 신호)
  - **버그 발견**: 그룹을 선택해도 사용자 목록이 표시되지 않고 "No data"로 나타남

#### 1.4 사용자 목록 확인 테스트 (Read)
- **테스트명**: "4. 설비권한그룹 사용자 목록 확인"
- **검증 항목**:
  - 그룹 선택 후 오른쪽 패널의 TUI Grid에서 사용자 수 조회
  - `getTableRowCount()` 유틸리티 함수 활용

### 2. 기존 테스트 스위트 강화

설비권한그룹 관리의 기본 기능을 검증하는 6개의 기존 테스트를 유지:

- "설비권한그룹-사용자 페이지 접근 확인"
- "설비권한그룹 목록 조회"
- "설비권한그룹 선택 시 사용자 목록 표시"
- "설비권한그룹에 사용자 추가 및 팝업 사용자 목록 검증"
- "설비권한그룹에서 사용자 삭제 버튼 확인"
- "설비권한그룹 등록 버튼 확인"
- "이력조회 버튼 동작 확인"

### 3. 권한별 데이터 접근 테스트 추가

4개의 권한별 테스트를 구현하여 설비권한그룹이 데이터 접근 제어에 정상 작동하는지 검증:

| 사용자 역할 | 테스트명 | 검증 목표 |
|-----------|---------|---------|
| 관제담당자 | "관제담당자로 이벤트 조회 - 전체 데이터" | 전체 이벤트 조회 가능 |
| 관제자 | "관제자로 이벤트 조회 - 전체 데이터" | 관제담당자와 동일 그룹(전체 조회) |
| 운영담당자 | "운영담당자로 이벤트 조회 - 제한된 데이터" | 할당된 호스트그룹만 조회 |
| 일반사용자 | "일반사용자로 이벤트 조회 - 최소 데이터" | 최소한의 데이터만 조회 |

### 4. 유틸리티 함수 개선

**파일**: `/Users/jiwoong.kim/Documents/claude/projects/luppiter_web_e2e/utils/validation.ts`

#### 수정 사항: `getTableRowCount()` 함수 개선
- **문제**: 그리드가 숨겨져 있거나 로드 중일 때 에러 발생
- **해결책**:
  - 그리드 가시성 확인 추가 (`.isVisible()`)
  - 최대 5초 대기 로직 추가 (`.waitFor()`)
  - 에러 발생 시 0 반환하는 안전장치 추가
  - Try-catch 블록으로 모든 경우 처리

**개선 전**:
```typescript
// 그리드가 숨겨져 있으면 에러 발생
export async function getTableRowCount(page: Page): Promise<number> {
  const grid = page.locator(gridSelector).first()
  const data = await extractTuiGridData(page, gridSelector)
  return data.length
}
```

**개선 후**:
```typescript
// 그리드 상태 확인 후 안전하게 처리
export async function getTableRowCount(page: Page, gridSelector: string = '.tui-grid-container'): Promise<number> {
  try {
    const grid = page.locator(gridSelector).first()
    const isVisible = await grid.isVisible().catch(() => false)

    if (!isVisible) {
      await grid.waitFor({ state: 'visible', timeout: 5000 }).catch(() => {})
    }

    const data = await extractTuiGridData(page, gridSelector)
    return data.length
  } catch {
    return 0
  }
}
```

---

## 발견된 버그

### 버그: 설비권한그룹-사용자 페이지에서 그룹 선택 시 사용자 목록 미표시

**심각도**: HIGH

**증상**:
- 사용자가 있는 그룹(예: "Cloud NW운영팀-EPC-NW", 포함 사용자 수: 6명)을 선택해도 오른쪽 패널에 "No data"가 표시됨
- 예상 결과: 해당 그룹에 속한 6명의 사용자 목록이 TUI Grid에 표시되어야 함

**영향**:
- 사용자는 그룹을 선택했을 때 그룹에 속한 사용자를 확인할 수 없음
- 권한 관리 시 데이터 검증이 어려움
- 사용자 추가/삭제 작업이 불가능해질 수 있음

**원인 추정**:
1. 그룹 선택 후 사용자 조회 API가 호출되지 않음
2. API 응답이 정상적으로 처리되지 않음
3. UI 상태 관리에서 사용자 목록 데이터가 업데이트되지 않음
4. 셀렉터/바인딩 오류로 사용자 데이터가 테이블에 바인딩되지 않음

**검증 증거**:
- 스크린샷: `artifacts/BUG-user-list-not-showing.png`
- 테스트: `tests/e2e/permission-group.spec.ts` 라인 474-537 (test 3)

---

## 테스트 결과

### 전체 결과
```
Total: 121 테스트
- 통과: 108개 (89.3%)
- 스킵: 12개 (9.9%)
- 실패: 1개 (0.8%) ← 버그 검출
```

### 실패한 테스트
**테스트**: "3. [BUG] 그룹 선택 시 오른쪽 사용자 목록 표시 검증"
```
Expected: hasNoData = false (사용자 목록이 표시되어야 함)
Actual: hasNoData = true ("No data" 메시지 표시)

Error message:
❌ 그룹 "Cloud NW운영팀-EPC-NW"에 사용자 6명이 있지만
"No data"가 표시됨. 사용자 조회 API 문제!
```

### 스킵된 테스트 (12개)
- 테스트 계정 미설정 (테스트 환경 설정 필요)
- 테스트 권한 부족 (특정 사용자 권한 필요)

---

## 변경된 파일 상세

### 1. `/Users/jiwoong.kim/Documents/claude/projects/luppiter_web_e2e/tests/e2e/permission-group.spec.ts`

**라인**: 1-760 (전체)

**주요 추가 사항**:

#### 설비권한그룹 CRUD 테스트 스위트 (라인 253-565)
```typescript
test.describe('설비권한그룹 CRUD 테스트', () => {
  const TEST_GROUP_NAME = `E2E_테스트그룹_${Date.now()}`

  test('1. 설비권한그룹 등록 (생성)', async ({ page }) => { ... })
  test('2. 설비권한그룹에 사용자 추가 - 팝업 사용자 목록 검증', async ({ page }) => { ... })
  test('3. [BUG] 그룹 선택 시 오른쪽 사용자 목록 표시 검증', async ({ page }) => { ... })
  test('4. 설비권한그룹 사용자 목록 확인', async ({ page }) => { ... })
})
```

#### 권한별 데이터 접근 테스트 스위트 (라인 664-759)
```typescript
test.describe('권한 그룹별 데이터 접근 테스트', () => {
  test('관제담당자로 이벤트 조회 - 전체 데이터', async ({ page }) => { ... })
  test('관제자로 이벤트 조회 - 전체 데이터', async ({ page }) => { ... })
  test('운영담당자로 이벤트 조회 - 제한된 데이터', async ({ page }) => { ... })
  test('일반사용자로 이벤트 조회 - 최소 데이터', async ({ page }) => { ... })
  test('권한별 이벤트 건수 비교', async ({ page }) => { ... })
})
```

**주요 특징**:
- 동적 팝업 셀렉터 사용 (여러 가능한 클래스명 지원)
- 강건한 에러 처리 및 폴백 로직
- 상세한 콘솔 로깅으로 테스트 추적 용이
- 스크린샷 자동 캡처로 문제 재현 가능

### 2. `/Users/jiwoong.kim/Documents/claude/projects/luppiter_web_e2e/utils/validation.ts`

**라인**: 241-256

**개선 사항**:
```typescript
/**
 * 테이블 행 수 확인
 * TUI Grid가 없거나 hidden일 경우 0 반환
 */
export async function getTableRowCount(
  page: Page,
  gridSelector: string = '.tui-grid-container'
): Promise<number> {
  try {
    const grid = page.locator(gridSelector).first()
    const isVisible = await grid.isVisible().catch(() => false)

    if (!isVisible) {
      // 데이터 로드 대기 (최대 5초)
      await grid.waitFor({ state: 'visible', timeout: 5000 }).catch(() => {})
    }

    const data = await extractTuiGridData(page, gridSelector)
    return data.length
  } catch {
    return 0
  }
}
```

**수정 사항**:
1. 가시성 확인 (`.isVisible()`)
2. 로드 대기 (`.waitFor()`)
3. 에러 처리 (try-catch)
4. 안전한 폴백 (0 반환)

---

## 구조 및 설계 원칙

### 테스트 구성

**Describe 블록 (4개)**:
1. "설비권한그룹 관리 테스트" - 기본 기능 검증 (7개 테스트)
2. "설비권한그룹 CRUD 테스트" - 전체 생명주기 (4개 테스트)
3. "설비권한그룹 변경 테스트" - 데이터 변경 반영 (1개 테스트)
4. "권한 그룹별 데이터 접근 테스트" - 접근 제어 검증 (5개 테스트)

### 셀렉터 전략

**강건한 다중 셀렉터 사용**:
```typescript
// 여러 가능한 클래스명/텍스트를 시도
const addUserBtn = page.locator(
  '.rightPanel button:has-text("추가"), ' +
  '.rightPanel button:has-text("등록"), ' +
  'button:has-text("사용자 추가"), ' +
  '[class*="right"] button:has-text("추가")'
).first()
```

**장점**:
- UI 변경에 유연함
- 다양한 HTML 구조 지원
- 첫 번째 매칭 요소 선택

### 에러 처리

**포괄적 예외 처리**:
```typescript
const isVisible = await element.isVisible().catch(() => false)
// 요소가 없거나 에러가 발생하면 false 반환
```

### 로깅

**상세한 콘솔 출력**:
```typescript
console.log(`설비권한그룹 개수: ${groupCount}`)
console.log(`그룹 내 사용자 수: ${userData.length}`)
console.error('❌ 팝업에 사용자 목록이 비어있음')
```

---

## 권장 다음 단계

### 1. 버그 수정 (즉시)
**우선순위**: CRITICAL

버그 원인 조사 및 수정:
- 그룹 선택 이벤트 핸들러 확인
- 사용자 조회 API 호출 확인 (Network 탭)
- 응답 데이터 확인
- UI 상태 관리 로직 확인

### 2. 테스트 계정 설정 (단기)
**우선순위**: HIGH

12개의 스킵된 테스트를 활성화하기 위해:
- `fixtures/test-data.ts`에 테스트 계정 설정
- 각 사용자 역할별 계정 생성 (관제담당자, 관제자, 운영담당자, 일반사용자)

### 3. 통합 테스트 확대 (중기)
**우선순위**: MEDIUM

- 그룹-사용자 추가/삭제 작업 후 실제 데이터 변경 검증
- 권한 그룹 변경 후 대시보드 데이터 새로고침 확인
- 다중 사용자 시나리오 (A 그룹 ↔ B 그룹 전환)

### 4. 성능 테스트 (중기)
**우선순위**: MEDIUM

- 대량 사용자 그룹(1000+ 행) 렌더링 성능
- 그룹 선택 시 응답 시간 (목표: < 2초)
- 권한 조회 API 응답 시간

---

## 실행 방법

### 테스트 실행
```bash
# 전체 테스트 실행
npm run test

# 특정 테스트 파일 실행
npm run test permission-group.spec.ts

# 특정 테스트 케이스 실행
npm run test -- -g "설비권한그룹 CRUD"

# GUI 모드로 실행 (대화형)
npm run test:ui
```

### 결과 확인
```bash
# 테스트 결과 리포트 보기
open test-results/index.html

# 아티팩트(스크린샷) 확인
open artifacts/
```

---

## 요약

이 세션에서는 **설비권한그룹 관리 기능**에 대한 포괄적인 E2E 테스트를 구현했습니다.

**핵심 성과**:
- ✅ CRUD 테스트 4개 추가 (생성, 읽기, 사용자 추가)
- ✅ 권한별 데이터 접근 테스트 5개 추가
- ✅ 유틸리티 함수 강화 (안전성 개선)
- ✅ **버그 검출**: 그룹 선택 시 사용자 목록 미표시

**테스트 커버리지**: 108/121 (89.3%)

**발견된 이슈**: 1개 (HIGH 심각도)
- 설비권한그룹 페이지에서 그룹 선택 후 사용자 목록이 표시되지 않음

**다음 작업**: 버그 수정 및 테스트 계정 설정을 통한 스킵 테스트 활성화

---

**작업 완료**: 2026-01-30 08:46 KST
