# Luppiter Web E2E 테스트 자동화 구현 가이드

## 1. 개요

Playwright 기반 E2E(End-to-End) 테스트 자동화 프레임워크 구현.
실제 브라우저에서 사용자 시나리오를 자동으로 검증합니다.

### 기술 스택
- **Playwright**: E2E 테스트 프레임워크
- **TypeScript**: 타입 안전성
- **Page Object Model**: 유지보수성 높은 테스트 구조
- **PostgreSQL**: 테스트 사용자 자동 생성

### 테스트 현황
- **93개 테스트** 통과
- 8개 테스트 카테고리 (로그인, 대시보드, 이벤트, 인시던트, 인벤토리, 관제설정, 권한관리, 네비게이션)

---

## 2. 프로젝트 구조

```
luppiter_web_e2e/
├── pages/                    # Page Object 클래스
│   ├── BasePage.ts          # 공통 페이지 요소
│   ├── LoginPage.ts         # 로그인 페이지
│   ├── DashboardPage.ts     # 대시보드
│   ├── EventPage.ts         # 이벤트 관리
│   ├── IncidentPage.ts      # 인시던트 관리
│   ├── InventoryPage.ts     # 인벤토리
│   ├── MaintenancePage.ts   # 메인터넌스(관제 일시 중단)
│   └── AdminPage.ts         # 권한 관리
├── tests/
│   └── e2e/                  # E2E 테스트 파일
│       ├── login.spec.ts
│       ├── dashboard.spec.ts
│       ├── event-management.spec.ts
│       ├── incident-management.spec.ts
│       ├── inventory.spec.ts
│       ├── maintenance.spec.ts
│       ├── admin-management.spec.ts
│       └── navigation.spec.ts
├── utils/
│   └── validation.ts         # 검증 유틸리티 함수
├── fixtures/
│   └── test-data.ts          # 테스트 데이터 (사용자, 메뉴 구조)
├── setup/
│   └── test-users.ts         # DB 테스트 사용자 자동 생성
├── global-setup.ts           # 테스트 시작 전 설정
├── global-teardown.ts        # 테스트 종료 후 정리
├── playwright.config.ts      # Playwright 설정
└── .env                      # 환경 변수
```

---

## 3. 환경 설정

### 3.1 패키지 설치

```bash
npm init -y
npm install -D @playwright/test dotenv pg xlsx
npx playwright install chromium
```

### 3.2 환경 변수 (.env)

```env
# 테스트 대상 URL
BASE_URL=http://localhost:8080

# 테스트 사용자 DB 연결
DB_HOST=your-db-host
DB_PORT=5432
DB_NAME=luppiter
DB_USER=your-user
DB_PASSWORD=your-password

# 테스트 계정
TEST_USER_ID=e2e_manager
TEST_USER_PASSWORD=test1234!
```

### 3.3 Playwright 설정 (playwright.config.ts)

```typescript
import { defineConfig, devices } from '@playwright/test'
import 'dotenv/config'

export default defineConfig({
  testDir: './tests',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',

  globalSetup: './global-setup.ts',
  globalTeardown: './global-teardown.ts',

  use: {
    baseURL: process.env.BASE_URL || 'http://localhost:8080',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  outputDir: './artifacts',

  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
})
```

---

## 4. 테스트 사용자 자동 생성

### 4.1 핵심 포인트

1. **비밀번호 암호화**: SHA-256 + Base64 (서버 로직과 동일)
2. **초기 로그인 우회**: `exception_user_init_login = 'Y'` 설정
3. **테스트 종료 후 자동 삭제**: teardown에서 정리

### 4.2 구현 (setup/test-users.ts)

```typescript
import { Client } from 'pg'
import * as crypto from 'crypto'

// 비밀번호 암호화 (서버와 동일한 방식)
function encryptPassword(password: string): string {
  const hash = crypto.createHash('sha256')
  hash.update(password)
  return hash.digest('base64')
}

export async function createTestUsers() {
  const client = new Client({
    host: process.env.DB_HOST,
    port: parseInt(process.env.DB_PORT || '5432'),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
  })

  await client.connect()

  const testUsers = [
    { id: 'e2e_manager', name: 'E2E 관제담당자', role: '관제담당자', roleCode: '01' },
    { id: 'e2e_operator', name: 'E2E 관제자', role: '관제자', roleCode: '02' },
  ]

  for (const user of testUsers) {
    const encryptedPassword = encryptPassword('test1234!')

    await client.query(`
      INSERT INTO cmon_user (
        user_id, user_nm, user_pw, user_role, user_role_cd,
        exception_user_init_login,  -- 초기 비밀번호 변경 팝업 우회
        use_yn, reg_dt, reg_user_id
      ) VALUES ($1, $2, $3, $4, $5, 'Y', 'Y', NOW(), 'E2E_SYSTEM')
      ON CONFLICT (user_id) DO UPDATE SET
        user_pw = $3,
        exception_user_init_login = 'Y'
    `, [user.id, user.name, encryptedPassword, user.role, user.roleCode])
  }

  await client.end()
}

export async function deleteTestUsers() {
  const client = new Client({ /* 연결 설정 */ })
  await client.connect()
  await client.query(`DELETE FROM cmon_user WHERE user_id LIKE 'e2e_%'`)
  await client.end()
}
```

---

## 5. Page Object Model 패턴

### 5.1 개념

페이지별로 UI 요소와 액션을 클래스로 캡슐화하여 유지보수성 향상.

### 5.2 기본 구조 (pages/LoginPage.ts)

```typescript
import { Page, Locator } from '@playwright/test'

export class LoginPage {
  readonly page: Page

  // UI 요소 정의
  readonly userIdInput: Locator
  readonly passwordInput: Locator
  readonly loginButton: Locator
  readonly errorMessage: Locator

  constructor(page: Page) {
    this.page = page

    // 선택자 정의 (여러 선택자 대응)
    this.userIdInput = page.locator('input[name="userId"], #userId')
    this.passwordInput = page.locator('input[name="password"], #password')
    this.loginButton = page.locator('button:has-text("LOGIN"), .btLogin')
    this.errorMessage = page.locator('.error, .alert')
  }

  // 페이지 이동
  async goto() {
    await this.page.goto('/')
    await this.page.waitForLoadState('networkidle')
  }

  // 로그인 액션
  async login(userId: string, password: string) {
    await this.userIdInput.fill(userId)
    await this.passwordInput.fill(password)
    await this.loginButton.click()
    await this.page.waitForLoadState('networkidle')
  }
}
```

### 5.3 TUI Grid 대응 (테이블 선택자)

Luppiter는 TUI Grid를 사용하므로 일반 `<table>` 대신 TUI Grid 선택자 사용:

```typescript
// ❌ 잘못된 선택자
this.dataTable = page.locator('table.dataTable')

// ✅ TUI Grid 선택자
this.dataTable = page.locator('.tui-grid-container').first()
this.dataRows = page.locator('.tui-grid-container .tui-grid-body-area .tui-grid-row')
```

### 5.4 Strict Mode 대응

Playwright strict mode에서 여러 요소 매칭 시 에러 발생. `.first()` 사용:

```typescript
// ❌ 여러 요소 매칭 시 에러
this.searchButton = page.locator('button:has-text("검색")')

// ✅ 첫 번째 요소만 선택
this.searchButton = page.locator('button:has-text("검색")').first()
```

---

## 6. 검증 유틸리티 (utils/validation.ts)

### 6.1 TUI Grid 데이터 추출

```typescript
export async function extractTuiGridData(page: Page): Promise<string[][]> {
  return await page.evaluate(() => {
    const container = document.querySelector('.tui-grid-container')
    if (!container) return []

    const rows: string[][] = []
    container.querySelectorAll('.tui-grid-body-area .tui-grid-row').forEach((row) => {
      const cells: string[] = []
      row.querySelectorAll('.tui-grid-cell').forEach((cell) => {
        cells.push((cell.textContent || '').trim())
      })
      if (cells.length > 0) rows.push(cells)
    })
    return rows
  })
}
```

### 6.2 검색 결과 검증

```typescript
export async function validateSearchResults(
  page: Page,
  searchKeyword: string,
  targetColumnIndex: number
): Promise<{ valid: boolean; matchedRows: number; totalRows: number }> {
  const data = await extractTuiGridData(page)
  const keyword = searchKeyword.toLowerCase()

  let matchedRows = 0
  data.forEach((row) => {
    if (row[targetColumnIndex]?.toLowerCase().includes(keyword)) {
      matchedRows++
    }
  })

  return {
    valid: matchedRows === data.length,
    matchedRows,
    totalRows: data.length,
  }
}
```

### 6.3 드롭다운 필터 결과 검증

```typescript
export async function validateDropdownFilterResults(
  page: Page,
  expectedValue: string,
  targetColumnIndex: number
): Promise<{ valid: boolean; matchedRows: number; totalRows: number }> {
  const data = await extractTuiGridData(page)
  const expected = expectedValue.toLowerCase()

  let matchedRows = 0
  data.forEach((row) => {
    if (row[targetColumnIndex]?.toLowerCase().includes(expected)) {
      matchedRows++
    }
  })

  return {
    valid: matchedRows === data.length,
    matchedRows,
    totalRows: data.length,
  }
}
```

---

## 7. 테스트 작성 패턴

### 7.1 기본 테스트 구조

```typescript
import { test, expect } from '@playwright/test'
import { LoginPage } from '../../pages/LoginPage'
import { EventPage } from '../../pages/EventPage'
import { testUsers } from '../../fixtures/test-data'

test.describe('이벤트 상황 관리 테스트', () => {
  let eventPage: EventPage

  // 각 테스트 전 로그인
  test.beforeEach(async ({ page }) => {
    const loginPage = new LoginPage(page)
    await loginPage.goto()

    // 테스트 계정 미설정 시 스킵
    test.skip(!testUsers.exceptionUser.userId, '테스트 계정 미설정')

    await loginPage.login(
      testUsers.exceptionUser.userId,
      testUsers.exceptionUser.password
    )
    await page.waitForURL(/\/(dashboard|view)\/.*/, { timeout: 10000 })

    eventPage = new EventPage(page)
  })

  test('실시간 이벤트 페이지 UI 로드 확인', async ({ page }) => {
    await eventPage.gotoRealtimeEvent()
    await expect(eventPage.eventTable).toBeVisible()
    await page.screenshot({ path: 'artifacts/event-ui.png' })
  })
})
```

### 7.2 검색 결과 검증 테스트

```typescript
test('검색 필터 동작 및 결과 검증', async ({ page }) => {
  await eventPage.gotoRealtimeEvent()

  const beforeCount = await eventPage.getEventCount()

  if (beforeCount > 0) {
    // 첫 번째 행 데이터로 검색 키워드 추출
    const firstRowData = await extractTuiGridData(page)
    const searchKeyword = firstRowData[0][0].substring(0, 5)

    await eventPage.searchEvent(searchKeyword)

    const afterCount = await getTableRowCount(page)

    if (afterCount > 0) {
      // 검색 결과 검증
      const validation = await validateSearchResults(page, searchKeyword, 0)

      // 최소 50% 이상 일치 (다중 컬럼 검색 가능성 고려)
      expect(validation.matchedRows / validation.totalRows).toBeGreaterThanOrEqual(0.5)
    }
  }
})
```

### 7.3 드롭다운 필터 검증 테스트

```typescript
test('호스트 상태 필터 동작 및 결과 검증', async ({ page }) => {
  await maintenancePage.gotoMaintenanceHistory()

  const statusDropdown = page.locator('select:has(option:text("호스트 상태"))').first()

  if (await statusDropdown.isVisible()) {
    const options = await statusDropdown.locator('option').allTextContents()
    const filterOptions = options.filter(opt => !opt.includes('호스트 상태'))

    if (filterOptions.length > 0) {
      await statusDropdown.selectOption({ label: filterOptions[0] })
      await maintenancePage.searchButton.click()
      await page.waitForLoadState('networkidle')

      const rowCount = await getTableRowCount(page)

      if (rowCount > 0) {
        const validation = await validateDropdownFilterResults(page, filterOptions[0], 1)
        expect(validation.matchedRows / validation.totalRows).toBeGreaterThanOrEqual(0.8)
      }
    }
  }
})
```

---

## 8. 테스트 실행 방법

### 8.1 전체 테스트 실행

```bash
npm test
```

### 8.2 브라우저 보며 실행 (headed mode)

```bash
npm run test:headed
```

### 8.3 순차 실행 (1개씩)

```bash
npm run test:headed -- --workers=1
```

### 8.4 특정 테스트만 실행

```bash
npm test -- --grep "로그인"
npm test -- --grep "이벤트 상황 관리"
```

### 8.5 디버그 모드

```bash
npm run test:debug
```

### 8.6 UI 모드 (인터랙티브)

```bash
npm run test:ui
```

---

## 9. 트러블슈팅

### 9.1 로그인 후 비밀번호 변경 팝업

**문제**: 신규 사용자 로그인 시 비밀번호 변경 팝업 표시
**해결**: `exception_user_init_login = 'Y'` 설정

### 9.2 TUI Grid 테이블 선택자 오류

**문제**: `table.dataTable` 선택자가 동작하지 않음
**해결**: `.tui-grid-container` 선택자 사용

### 9.3 Strict Mode Violation

**문제**: `locator resolved to X elements` 에러
**해결**: `.first()` 추가하여 첫 번째 요소만 선택

### 9.4 타임아웃 에러

**문제**: 페이지 로드 대기 중 타임아웃
**해결**: `waitForLoadState('networkidle')` 또는 타임아웃 값 증가

---

## 10. 테스트 커버리지

| 메뉴 | 테스트 항목 | 검증 수준 |
|------|------------|----------|
| 로그인 | UI 로드, 유효성 검사, 로그인 성공/실패 | L3 (기능) |
| 대시보드 | UI 로드, 이벤트/인시던트 건수, 팝업 | L2 (표시) |
| 이벤트 | UI, 검색, 필터, 상세, 버튼, 엑셀 | L4 (데이터 검증) |
| 인시던트 | UI, 검색, 상세, 등록/조치완료, 엑셀 | L4 (데이터 검증) |
| 인벤토리 | UI, 검색, 상세, 엑셀 | L4 (데이터 검증) |
| 관제 설정 | UI, 검색, 필터, 등록/상세 | L4 (데이터 검증) |
| 권한 관리 | UI, 검색, 그룹 선택, 이력조회 | L3 (기능) |
| 네비게이션 | 메뉴 이동, 로그아웃 | L3 (기능) |

### 검증 수준
- **L1**: 페이지 로드 확인
- **L2**: UI 요소 표시 확인
- **L3**: 기능 동작 확인
- **L4**: 실제 데이터 값 검증 (검색 결과, 필터 결과)

---

## 11. 향후 개선 사항

1. **CRUD 테스트 추가**: 실제 데이터 등록/수정/삭제 테스트
2. **권한별 테스트**: 다른 역할로 로그인하여 메뉴 접근 권한 테스트
3. **성능 테스트**: 대량 데이터 환경에서 응답 시간 측정
4. **CI/CD 연동**: GitHub Actions 또는 Jenkins 파이프라인 구성
