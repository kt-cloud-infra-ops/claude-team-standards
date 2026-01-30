# Luppiter 인증/인벤토리 모듈화 구현 가이드

> **작성일**: 2026-01-27
> **대상 프로젝트**: luppiter_web
> **개발 범위**: 구조 설계 + 기존 코드 리팩토링

---

## 목차

1. [개요](#1-개요)
2. [인증 모듈화](#2-인증-모듈화)
   - [AS-IS 현황](#21-as-is-현황)
   - [TO-BE 설계](#22-to-be-설계)
   - [구현 명세](#23-구현-명세)
3. [인벤토리 모듈화](#3-인벤토리-모듈화)
   - [AS-IS 현황](#31-as-is-현황)
   - [TO-BE 설계](#32-to-be-설계)
   - [구현 명세](#33-구현-명세)
4. [Mapper 추가 사항](#4-mapper-추가-사항)
5. [기존 코드 처리](#5-기존-코드-처리)
6. [프론트엔드 변경](#6-프론트엔드-변경)
7. [테스트 코드](#7-테스트-코드)
8. [마이그레이션 절차](#8-마이그레이션-절차)
9. [검토 필요 사항](#9-검토-필요-사항)
10. [체크리스트](#10-체크리스트)

---

## 1. 개요

### 1.1 배경

현재 Luppiter 시스템의 인증과 인벤토리 연동 로직이 하드코딩되어 있어, 새로운 인증 방식(SSO) 또는 인벤토리 시스템(CMDB) 추가 시 기존 코드를 직접 수정해야 하는 문제가 있습니다.

### 1.2 목표

| 목표 | 설명 |
|------|------|
| 인증 모듈화 | DEFAULT, LDAP, SSO 등 다양한 인증 방식을 인터페이스 기반으로 통합 |
| 인벤토리 모듈화 | ITAM, DCIM, CMDB 등 외부 시스템 연동을 인터페이스 기반으로 통합 |
| 확장성 확보 | 새로운 시스템 추가 시 Provider 구현체만 추가하면 되는 구조 |

### 1.3 기대 효과

| 항목 | AS-IS | TO-BE |
|------|-------|-------|
| 새 인증 방식 추가 | Controller, Service 수정 필요 | Provider 구현체만 추가 |
| 새 인벤토리 시스템 추가 | Service 로직 수정 필요 | Provider 구현체만 추가 |
| 테스트 | 전체 로직 테스트 필요 | Provider 단위 테스트 가능 |
| 유지보수 | 코드 간 결합도 높음 | 각 Provider 독립적 관리 |

---

## 2. 인증 모듈화

### 2.1 AS-IS 현황

#### 현재 API 구조

```
/api/ctl/login      → DEFAULT 로그인 (DB 검증)
/api/ctl/ldapLogin  → LDAP 로그인
```

#### 현재 코드 위치

| 파일 | 경로 | 설명 |
|------|------|------|
| CtlRestController.java | `com.ktc.luppiter.web.controller` | 로그인 API (146행: login, 253행: ldapLogin) |
| LdapLoginUtils.java | `com.ktc.luppiter.web.util` | LDAP 인증 유틸 (543행) |
| CtlMapper.java | `com.ktc.luppiter.web.mapper` | 사용자 조회 쿼리 |

#### 현재 코드 흐름

```
CtlRestController.login()                    ← DEFAULT 로그인
├── ctlService.selectUserInfo()              // 사용자 조회
├── 비밀번호 검증 (SHA256)                    // 하드코딩
└── session.setAttribute("loginInfo", ...)   // 세션 생성

CtlRestController.ldapLogin()                ← LDAP 로그인
├── LdapLoginUtils.auth_loginPeriod()        // LDAP 인증
├── LdapLoginUtils.query_userinfo()          // 사용자 정보
└── session.setAttribute("loginInfo", ...)   // 세션 생성
```

#### 문제점

1. **코드 중복**: 세션 생성, 사용자 상태 확인 로직이 각 메서드에 중복
2. **결합도 높음**: Controller에 인증 로직이 직접 구현됨
3. **확장성 부족**: SSO 추가 시 Controller에 새 API 추가 필요
4. **테스트 어려움**: Controller 전체를 테스트해야 함

---

### 2.2 TO-BE 설계

#### 목표 API 구조

```
/api/auth/login  → 단일 통합 API (내부에서 Provider 자동 선택)
```

#### 인증 분기 로직

```
사용자 로그인 요청 (userId, password)
              │
              ▼
┌─────────────────────────────────────┐
│  cmon_user 테이블에서 userId 조회    │
│  → local_auth_flag 값 확인          │
└─────────────────────────────────────┘
              │
              ├── flag = 'Y' ──→ LocalAuthProvider (DB 검증)
              │
              └── flag = 'N'/NULL ──→ ExternalAuthProvider (LDAP 등)
                                      (application.yml에서 설정)
```

#### 목표 코드 흐름

```
AuthController.login(request)
└── AuthenticationService.authenticate(request)
    ├── ctlMapper.selectUserByUserId()           // flag 확인
    ├── AuthProviderFactory.getProvider(user)    // Provider 선택
    │   ├── flag='Y' → LocalAuthProvider
    │   └── 그 외   → LdapAuthProvider (Config 기반)
    ├── provider.authenticate(request)           // 인증 수행
    └── sessionManager.createSession()           // 세션 생성 (공통)
```

#### 패키지 구조

```
com.ktc.luppiter.core.auth/
├── IAuthProvider.java              # 인터페이스
├── AuthProviderFactory.java        # Provider 선택
├── AuthenticationService.java      # 통합 서비스
├── AuthController.java             # API Controller
├── config/
│   └── AuthConfig.java             # yaml 설정 바인딩
├── provider/
│   ├── LocalAuthProvider.java      # DB 인증 (구현)
│   ├── LdapAuthProvider.java       # LDAP 인증 (구현)
│   ├── OktaAuthProvider.java       # OKTA 인증 (향후)
│   └── KeycloakAuthProvider.java   # Keycloak 인증 (향후)
├── dto/
│   ├── AuthRequest.java            # 요청 DTO
│   └── AuthResult.java             # 결과 DTO
└── enums/
    └── AuthType.java               # 인증 타입
```

---

### 2.3 구현 명세

#### 2.3.1 IAuthProvider 인터페이스

```java
package com.ktc.luppiter.core.auth;

public interface IAuthProvider {

    /**
     * 인증 수행
     */
    AuthResult authenticate(AuthRequest request);

    /**
     * 지원하는 인증 타입
     */
    AuthType getAuthType();

    /**
     * Provider 사용 가능 여부 (헬스체크)
     */
    boolean isAvailable();
}
```

#### 2.3.2 AuthType Enum

```java
package com.ktc.luppiter.core.auth.enums;

public enum AuthType {
    LOCAL("로컬 인증"),
    LDAP("LDAP 인증"),
    OKTA("OKTA SSO"),
    KEYCLOAK("Keycloak SSO");

    private final String description;

    AuthType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
```

#### 2.3.3 AuthRequest DTO

```java
package com.ktc.luppiter.core.auth.dto;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class AuthRequest {
    private String userId;
    private String password;
    private String clientIp;      // 감사 로그용
    private String userAgent;     // 감사 로그용
}
```

#### 2.3.4 AuthResult DTO

```java
package com.ktc.luppiter.core.auth.dto;

import lombok.Builder;
import lombok.Getter;

@Getter
@Builder
public class AuthResult {
    private boolean success;
    private String userId;
    private String userName;
    private String email;
    private String department;
    private String errorCode;
    private String errorMessage;
    private AuthType authType;

    public static AuthResult success(String userId, String userName, AuthType authType) {
        return AuthResult.builder()
            .success(true)
            .userId(userId)
            .userName(userName)
            .authType(authType)
            .build();
    }

    public static AuthResult failure(String errorCode, String errorMessage) {
        return AuthResult.builder()
            .success(false)
            .errorCode(errorCode)
            .errorMessage(errorMessage)
            .build();
    }
}
```

#### 2.3.5 AuthConfig (yaml 바인딩)

```java
package com.ktc.luppiter.core.auth.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "auth")
@Getter
@Setter
public class AuthConfig {

    private External external = new External();

    @Getter
    @Setter
    public static class External {
        private AuthType type = AuthType.LDAP;  // 기본값
        private String host;
        private int port = 389;
        private String baseDn;
        private String bindDn;
        private String bindPassword;
        private boolean useSsl = false;

        // OKTA/Keycloak용 (향후)
        private String clientId;
        private String clientSecret;
        private String issuerUri;
    }
}
```

**application.yml 설정**

```yaml
auth:
  external:
    type: LDAP
    host: ldap.ktcloud.com
    port: 389
    base-dn: ou=users,dc=ktcloud,dc=com
    bind-dn: cn=service,dc=ktcloud,dc=com
    bind-password: ${LDAP_BIND_PASSWORD}
    use-ssl: false
```

#### 2.3.6 LocalAuthProvider

```java
package com.ktc.luppiter.core.auth.provider;

import com.ktc.luppiter.core.auth.IAuthProvider;
import com.ktc.luppiter.core.auth.dto.*;
import com.ktc.luppiter.core.auth.enums.AuthType;
import com.ktc.luppiter.web.mapper.CtlMapper;
import com.ktc.luppiter.web.util.CryptoUtil;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class LocalAuthProvider implements IAuthProvider {

    private final CtlMapper ctlMapper;

    @Override
    public AuthResult authenticate(AuthRequest request) {
        try {
            // 1. 사용자 조회
            Map<String, Object> params = Map.of("userId", request.getUserId());
            Map<String, Object> userInfo = ctlMapper.selectUserInfo(params);

            if (userInfo == null) {
                log.warn("Local auth failed - user not found: {}", request.getUserId());
                return AuthResult.failure("AUTH_001", "사용자를 찾을 수 없습니다.");
            }

            // 2. 비밀번호 검증 (SHA256)
            String encPassword = CryptoUtil.encryptSHA256(request.getPassword());
            String storedPassword = (String) userInfo.get("password");

            if (!encPassword.equals(storedPassword)) {
                log.warn("Local auth failed - invalid password: {}", request.getUserId());
                return AuthResult.failure("AUTH_002", "비밀번호가 일치하지 않습니다.");
            }

            // 3. 사용자 상태 확인
            String userStatus = (String) userInfo.get("user_status");
            if (!"ACTIVE".equals(userStatus)) {
                log.warn("Local auth failed - inactive user: {}", request.getUserId());
                return AuthResult.failure("AUTH_003", "비활성화된 계정입니다.");
            }

            // 4. 인증 성공
            log.info("Local auth success: {}", request.getUserId());
            return AuthResult.builder()
                .success(true)
                .userId(request.getUserId())
                .userName((String) userInfo.get("user_name"))
                .email((String) userInfo.get("email"))
                .department((String) userInfo.get("department"))
                .authType(AuthType.LOCAL)
                .build();

        } catch (Exception e) {
            log.error("Local auth error: {}", request.getUserId(), e);
            return AuthResult.failure("AUTH_999", "인증 처리 중 오류가 발생했습니다.");
        }
    }

    @Override
    public AuthType getAuthType() {
        return AuthType.LOCAL;
    }

    @Override
    public boolean isAvailable() {
        return true;
    }
}
```

#### 2.3.7 LdapAuthProvider

```java
package com.ktc.luppiter.core.auth.provider;

import com.ktc.luppiter.core.auth.IAuthProvider;
import com.ktc.luppiter.core.auth.config.AuthConfig;
import com.ktc.luppiter.core.auth.dto.*;
import com.ktc.luppiter.core.auth.enums.AuthType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import javax.naming.Context;
import javax.naming.NamingEnumeration;
import javax.naming.directory.*;
import java.util.Hashtable;

@Slf4j
@Component
@RequiredArgsConstructor
public class LdapAuthProvider implements IAuthProvider {

    private final AuthConfig authConfig;

    @Override
    public AuthResult authenticate(AuthRequest request) {
        DirContext ctx = null;

        try {
            AuthConfig.External config = authConfig.getExternal();

            // 1. LDAP 연결 설정
            Hashtable<String, String> env = new Hashtable<>();
            env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
            env.put(Context.PROVIDER_URL, buildLdapUrl(config));
            env.put(Context.SECURITY_AUTHENTICATION, "simple");
            env.put(Context.SECURITY_PRINCIPAL, buildUserDn(request.getUserId(), config));
            env.put(Context.SECURITY_CREDENTIALS, request.getPassword());

            if (config.isUseSsl()) {
                env.put(Context.SECURITY_PROTOCOL, "ssl");
            }

            // 2. LDAP 인증 시도
            ctx = new InitialDirContext(env);

            // 3. 사용자 정보 조회
            SearchControls controls = new SearchControls();
            controls.setSearchScope(SearchControls.SUBTREE_SCOPE);
            controls.setReturningAttributes(new String[]{"cn", "mail", "department"});

            String searchFilter = String.format("(uid=%s)", request.getUserId());
            NamingEnumeration<SearchResult> results = ctx.search(
                config.getBaseDn(), searchFilter, controls);

            if (results.hasMore()) {
                SearchResult result = results.next();
                Attributes attrs = result.getAttributes();

                log.info("LDAP auth success: {}", request.getUserId());
                return AuthResult.builder()
                    .success(true)
                    .userId(request.getUserId())
                    .userName(getAttributeValue(attrs, "cn"))
                    .email(getAttributeValue(attrs, "mail"))
                    .department(getAttributeValue(attrs, "department"))
                    .authType(AuthType.LDAP)
                    .build();
            }

            return AuthResult.failure("AUTH_001", "사용자를 찾을 수 없습니다.");

        } catch (javax.naming.AuthenticationException e) {
            log.warn("LDAP auth failed: {}", request.getUserId());
            return AuthResult.failure("AUTH_002", "인증에 실패했습니다.");

        } catch (Exception e) {
            log.error("LDAP auth error: {}", request.getUserId(), e);
            return AuthResult.failure("AUTH_999", "LDAP 인증 처리 중 오류가 발생했습니다.");

        } finally {
            if (ctx != null) {
                try { ctx.close(); } catch (Exception ignored) {}
            }
        }
    }

    @Override
    public AuthType getAuthType() {
        return AuthType.LDAP;
    }

    @Override
    public boolean isAvailable() {
        try {
            AuthConfig.External config = authConfig.getExternal();
            Hashtable<String, String> env = new Hashtable<>();
            env.put(Context.INITIAL_CONTEXT_FACTORY, "com.sun.jndi.ldap.LdapCtxFactory");
            env.put(Context.PROVIDER_URL, buildLdapUrl(config));
            env.put(Context.SECURITY_AUTHENTICATION, "simple");
            env.put(Context.SECURITY_PRINCIPAL, config.getBindDn());
            env.put(Context.SECURITY_CREDENTIALS, config.getBindPassword());

            DirContext ctx = new InitialDirContext(env);
            ctx.close();
            return true;
        } catch (Exception e) {
            log.error("LDAP server not available", e);
            return false;
        }
    }

    private String buildLdapUrl(AuthConfig.External config) {
        String protocol = config.isUseSsl() ? "ldaps" : "ldap";
        return String.format("%s://%s:%d", protocol, config.getHost(), config.getPort());
    }

    private String buildUserDn(String userId, AuthConfig.External config) {
        return String.format("uid=%s,%s", userId, config.getBaseDn());
    }

    private String getAttributeValue(Attributes attrs, String name) {
        try {
            Attribute attr = attrs.get(name);
            return attr != null ? (String) attr.get() : null;
        } catch (Exception e) {
            return null;
        }
    }
}
```

#### 2.3.8 AuthProviderFactory

```java
package com.ktc.luppiter.core.auth;

import com.ktc.luppiter.core.auth.config.AuthConfig;
import com.ktc.luppiter.core.auth.enums.AuthType;
import com.ktc.luppiter.core.auth.provider.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.Map;

@Slf4j
@Component
@RequiredArgsConstructor
public class AuthProviderFactory {

    private final AuthConfig authConfig;
    private final LocalAuthProvider localAuthProvider;
    private final LdapAuthProvider ldapAuthProvider;

    /**
     * 사용자 정보 기반 Provider 선택
     * - local_auth_flag = 'Y' → LocalAuthProvider
     * - 그 외 → Config에 설정된 External Provider
     */
    public IAuthProvider getProvider(Map<String, Object> userInfo) {
        if (userInfo != null && "Y".equals(userInfo.get("local_auth_flag"))) {
            return localAuthProvider;
        }
        return getExternalProvider();
    }

    private IAuthProvider getExternalProvider() {
        AuthType type = authConfig.getExternal().getType();

        return switch (type) {
            case LDAP -> ldapAuthProvider;
            // case OKTA -> oktaAuthProvider;        // 향후
            // case KEYCLOAK -> keycloakAuthProvider; // 향후
            default -> throw new IllegalStateException("Unsupported auth type: " + type);
        };
    }

    public AuthType getExternalAuthType() {
        return authConfig.getExternal().getType();
    }
}
```

#### 2.3.9 AuthenticationService

```java
package com.ktc.luppiter.core.auth;

import com.ktc.luppiter.core.auth.dto.*;
import com.ktc.luppiter.core.auth.enums.AuthType;
import com.ktc.luppiter.core.config.UserSessionManager;
import com.ktc.luppiter.web.mapper.CtlMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import javax.servlet.http.HttpServletRequest;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthenticationService {

    private final AuthProviderFactory providerFactory;
    private final CtlMapper ctlMapper;
    private final UserSessionManager sessionManager;

    /**
     * 통합 인증 수행
     */
    public AuthResult authenticate(AuthRequest request, HttpServletRequest httpRequest) {
        log.info("Authentication attempt: userId={}", request.getUserId());

        // 1. 사용자 조회 (local_auth_flag 확인용)
        Map<String, Object> userInfo = ctlMapper.selectUserByUserId(request.getUserId());

        // 2. Provider 선택
        IAuthProvider provider = providerFactory.getProvider(userInfo);
        log.info("Selected provider: {}", provider.getAuthType());

        // 3. 인증 수행
        AuthResult result = provider.authenticate(request);

        // 4. 인증 성공 시 세션 생성
        if (result.isSuccess()) {
            sessionManager.createSession(httpRequest, result);
            log.info("Authentication success: userId={}, authType={}",
                result.getUserId(), result.getAuthType());
        } else {
            log.warn("Authentication failed: userId={}, error={}",
                request.getUserId(), result.getErrorCode());
        }

        return result;
    }

    /**
     * 현재 외부 인증 타입 조회
     */
    public AuthType getCurrentExternalAuthType() {
        return providerFactory.getExternalAuthType();
    }
}
```

#### 2.3.10 AuthController

```java
package com.ktc.luppiter.core.auth;

import com.ktc.luppiter.core.auth.dto.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import javax.servlet.http.HttpServletRequest;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthenticationService authService;

    /**
     * 통합 로그인 API
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(
            @RequestBody AuthRequest request,
            HttpServletRequest httpRequest) {

        request.setClientIp(getClientIp(httpRequest));
        request.setUserAgent(httpRequest.getHeader("User-Agent"));

        AuthResult result = authService.authenticate(request, httpRequest);

        if (result.isSuccess()) {
            return ResponseEntity.ok(Map.of(
                "success", true,
                "userId", result.getUserId(),
                "userName", result.getUserName(),
                "authType", result.getAuthType().getDescription()
            ));
        } else {
            return ResponseEntity.badRequest().body(Map.of(
                "success", false,
                "errorCode", result.getErrorCode(),
                "errorMessage", result.getErrorMessage()
            ));
        }
    }

    /**
     * 현재 인증 설정 조회 API
     */
    @GetMapping("/config")
    public ResponseEntity<?> getAuthConfig() {
        return ResponseEntity.ok(Map.of(
            "externalAuthType", authService.getCurrentExternalAuthType()
        ));
    }

    private String getClientIp(HttpServletRequest request) {
        String ip = request.getHeader("X-Forwarded-For");
        return (ip != null && !ip.isEmpty()) ? ip : request.getRemoteAddr();
    }
}
```

---

## 3. 인벤토리 모듈화

### 3.1 AS-IS 현황

#### 현재 코드 위치

| 파일 | 경로 | 설명 |
|------|------|------|
| InventoryManagerController.java | `com.ktc.luppiter.web.controller` | 인벤토리 API |
| InventoryManagerServiceImpl.java | `com.ktc.luppiter.web.service.impl` | ITAM/DCIM 조회 및 병합 (1374행) |
| ItamMapper.java | `com.ktc.luppiter.web.mapper` | ITAM DB 조회 |
| DcimMapper.java | `com.ktc.luppiter.web.mapper` | DCIM DB 조회 |

#### 현재 코드 흐름

```
InventoryManagerServiceImpl.getItamDcimList()
├── itamMapper.selectItamInfoList()           // ITAM 조회
├── dcimMapper.selectDcimDeviceInfoList()     // DCIM 조회
└── 바코드 기준 병합 로직 (하드코딩)
    └── ITAM.barcode == DCIM.EQUNR 매칭
```

#### 문제점

1. **결합도 높음**: ITAM/DCIM 조회 및 병합 로직이 Service에 직접 구현
2. **확장성 부족**: CMDB 추가 시 Service 로직 수정 필요
3. **소스 전환 어려움**: ITAM/DCIM → CMDB 전환 시 코드 변경 필요
4. **테스트 어려움**: 전체 Service를 테스트해야 함

---

### 3.2 TO-BE 설계

#### 설계 방향

- **ITAM + DCIM**: 하나의 Provider로 통합 (내부에서 병합)
- **CMDB**: 별도 Provider (단독 조회)
- **소스 선택**: Config(yaml)로 사용할 소스 지정
- **부분 실패 처리**: 가능한 데이터만 반환 + 알림/로깅

#### 목표 코드 흐름

```
InventoryService.getDeviceList(request)
├── InventoryProviderFactory.getProvider()     // Config 기반 선택
│   ├── ITAM_DCIM → ItamDcimProvider
│   └── CMDB      → CmdbProvider (향후)
└── provider.getDeviceList(request)
    ├── ItamDcimProvider 내부:
    │   ├── itamMapper.selectItamInfoList()
    │   ├── dcimMapper.selectDcimDeviceInfoList()
    │   ├── 바코드 기준 병합
    │   └── 부분 실패 시 가능한 데이터만 반환
    └── 결과 반환 (+ 실패 시 경고 메시지)
```

#### 패키지 구조

```
com.ktc.luppiter.core.inventory/
├── IInventoryProvider.java          # 인터페이스
├── InventoryProviderFactory.java    # Provider 선택
├── InventoryService.java            # 통합 서비스
├── config/
│   └── InventoryConfig.java         # yaml 설정 바인딩
├── provider/
│   ├── ItamDcimProvider.java        # ITAM+DCIM 통합 (구현)
│   └── CmdbProvider.java            # CMDB (향후)
├── dto/
│   ├── InventorySearchRequest.java  # 요청 DTO
│   ├── DeviceInfo.java              # 장비 정보 DTO
│   └── InventoryResult.java         # 결과 DTO (부분실패 지원)
└── enums/
    └── InventorySourceType.java     # 소스 타입
```

---

### 3.3 구현 명세

#### 3.3.1 IInventoryProvider 인터페이스

```java
package com.ktc.luppiter.core.inventory;

public interface IInventoryProvider {

    /**
     * 장비 목록 조회
     */
    InventoryResult getDeviceList(InventorySearchRequest request);

    /**
     * 장비 상세 조회
     */
    DeviceInfo getDeviceDetail(String deviceId);

    /**
     * 지원하는 소스 타입
     */
    InventorySourceType getSourceType();

    /**
     * Provider 사용 가능 여부
     */
    boolean isAvailable();
}
```

#### 3.3.2 InventorySourceType Enum

```java
package com.ktc.luppiter.core.inventory.enums;

public enum InventorySourceType {
    ITAM_DCIM("ITAM/DCIM 통합"),
    CMDB("CMDB");

    private final String description;

    InventorySourceType(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
```

#### 3.3.3 InventorySearchRequest DTO

```java
package com.ktc.luppiter.core.inventory.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.util.HashMap;
import java.util.Map;

@Getter
@Setter
@Builder
public class InventorySearchRequest {
    private String hostname;        // 호스트명 검색
    private String ipAddress;       // IP 검색
    private String barcode;         // 바코드 검색
    private String hostType;        // 호스트 타입 필터
    private String datacenter;      // 데이터센터 필터

    // 페이징
    private int page;
    private int size;

    /**
     * Mapper 호출용 Map 변환
     */
    public Map<String, Object> toParamMap() {
        Map<String, Object> params = new HashMap<>();
        if (hostname != null) params.put("hostname", hostname);
        if (ipAddress != null) params.put("ipAddress", ipAddress);
        if (barcode != null) params.put("barcode", barcode);
        if (hostType != null) params.put("hostType", hostType);
        if (datacenter != null) params.put("datacenter", datacenter);
        params.put("page", page);
        params.put("size", size);
        return params;
    }
}
```

#### 3.3.4 DeviceInfo DTO

```java
package com.ktc.luppiter.core.inventory.dto;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Builder
public class DeviceInfo {
    // 공통 필드
    private String barcode;
    private String hostname;
    private String ipAddress;
    private String hostType;

    // ITAM 필드
    private String assetStatus;
    private String purchaseDate;

    // DCIM 필드
    private String datacenterName;
    private String rackLocation;
    private String rackPosition;
    private String serialNumber;

    // 메타 정보
    private String sourceType;   // ITAM, ITAM+DCIM, CMDB
}
```

#### 3.3.5 InventoryResult DTO (부분 실패 지원)

```java
package com.ktc.luppiter.core.inventory.dto;

import lombok.Builder;
import lombok.Getter;

import java.util.ArrayList;
import java.util.List;

@Getter
@Builder
public class InventoryResult {
    private List<DeviceInfo> devices;
    private boolean partialFailure;
    private List<String> failedSources;
    private List<String> warningMessages;

    public static InventoryResult success(List<DeviceInfo> devices) {
        return InventoryResult.builder()
            .devices(devices)
            .partialFailure(false)
            .failedSources(new ArrayList<>())
            .warningMessages(new ArrayList<>())
            .build();
    }

    public static InventoryResult partialSuccess(
            List<DeviceInfo> devices,
            List<String> failedSources,
            List<String> warnings) {
        return InventoryResult.builder()
            .devices(devices)
            .partialFailure(true)
            .failedSources(failedSources)
            .warningMessages(warnings)
            .build();
    }
}
```

#### 3.3.6 InventoryConfig (yaml 바인딩)

```java
package com.ktc.luppiter.core.inventory.config;

import com.ktc.luppiter.core.inventory.enums.InventorySourceType;
import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Component
@ConfigurationProperties(prefix = "inventory")
@Getter
@Setter
public class InventoryConfig {

    private InventorySourceType source = InventorySourceType.ITAM_DCIM;

    // CMDB 설정 (향후)
    private Cmdb cmdb = new Cmdb();

    @Getter
    @Setter
    public static class Cmdb {
        private String apiUrl;
        private String apiKey;
        private int timeout = 30000;
    }
}
```

**application.yml 설정**

```yaml
inventory:
  source: ITAM_DCIM    # ITAM_DCIM / CMDB

# CMDB 사용 시 (향후)
# inventory:
#   source: CMDB
#   cmdb:
#     api-url: https://cmdb.ktcloud.com/api
#     api-key: ${CMDB_API_KEY}
```

#### 3.3.7 ItamDcimProvider

```java
package com.ktc.luppiter.core.inventory.provider;

import com.ktc.luppiter.core.inventory.IInventoryProvider;
import com.ktc.luppiter.core.inventory.dto.*;
import com.ktc.luppiter.core.inventory.enums.InventorySourceType;
import com.ktc.luppiter.web.mapper.DcimMapper;
import com.ktc.luppiter.web.mapper.ItamMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.*;
import java.util.function.Function;
import java.util.stream.Collectors;

@Slf4j
@Component
@RequiredArgsConstructor
public class ItamDcimProvider implements IInventoryProvider {

    private final ItamMapper itamMapper;
    private final DcimMapper dcimMapper;

    @Override
    public InventoryResult getDeviceList(InventorySearchRequest request) {
        List<DeviceInfo> devices = new ArrayList<>();
        List<String> failedSources = new ArrayList<>();
        List<String> warnings = new ArrayList<>();

        // 1. ITAM 조회
        List<Map<String, Object>> itamList = null;
        try {
            itamList = itamMapper.selectItamInfoList(request.toParamMap());
            log.info("ITAM query success: {} devices", itamList.size());
        } catch (Exception e) {
            log.error("ITAM query failed", e);
            failedSources.add("ITAM");
            warnings.add("ITAM 시스템 조회에 실패했습니다: " + e.getMessage());
        }

        // 2. DCIM 조회
        List<Map<String, Object>> dcimList = null;
        try {
            dcimList = dcimMapper.selectDcimDeviceInfoList(request.toParamMap());
            log.info("DCIM query success: {} devices", dcimList.size());
        } catch (Exception e) {
            log.error("DCIM query failed", e);
            failedSources.add("DCIM");
            warnings.add("DCIM 시스템 조회에 실패했습니다: " + e.getMessage());
        }

        // 3. 데이터 병합
        if (itamList != null) {
            Map<String, Map<String, Object>> dcimMap = dcimList != null
                ? dcimList.stream()
                    .filter(d -> d.get("EQUNR") != null)
                    .collect(Collectors.toMap(
                        d -> d.get("EQUNR").toString(),
                        Function.identity(),
                        (a, b) -> a
                    ))
                : Collections.emptyMap();

            devices = itamList.stream()
                .map(itam -> mergeToDeviceInfo(itam, dcimMap))
                .collect(Collectors.toList());
        }

        // 4. 결과 반환
        if (failedSources.isEmpty()) {
            return InventoryResult.success(devices);
        } else {
            return InventoryResult.partialSuccess(devices, failedSources, warnings);
        }
    }

    @Override
    public DeviceInfo getDeviceDetail(String deviceId) {
        try {
            Map<String, Object> params = Map.of("barcode", deviceId);
            Map<String, Object> itam = itamMapper.selectItamInfoDetail(params);

            if (itam == null) return null;

            Map<String, Object> dcim = dcimMapper.selectDcimDeviceInfoDetail(params);
            Map<String, Map<String, Object>> dcimMap = dcim != null
                ? Map.of(deviceId, dcim)
                : Collections.emptyMap();

            return mergeToDeviceInfo(itam, dcimMap);
        } catch (Exception e) {
            log.error("Device detail query failed: {}", deviceId, e);
            return null;
        }
    }

    @Override
    public InventorySourceType getSourceType() {
        return InventorySourceType.ITAM_DCIM;
    }

    @Override
    public boolean isAvailable() {
        try {
            itamMapper.healthCheck();
            return true;
        } catch (Exception e) {
            log.error("ITAM DB not available", e);
            return false;
        }
    }

    private DeviceInfo mergeToDeviceInfo(
            Map<String, Object> itam,
            Map<String, Map<String, Object>> dcimMap) {

        String barcode = getString(itam, "barcode");
        Map<String, Object> dcim = dcimMap.get(barcode);

        DeviceInfo.DeviceInfoBuilder builder = DeviceInfo.builder()
            .barcode(barcode)
            .hostname(getString(itam, "tcpiphostname"))
            .ipAddress(getString(itam, "tcpipaddress"))
            .hostType(getString(itam, "hosttype"))
            .assetStatus(getString(itam, "asset_status"))
            .purchaseDate(getString(itam, "purchase_date"))
            .sourceType("ITAM");

        if (dcim != null) {
            builder
                .datacenterName(getString(dcim, "DATACENTER_NM"))
                .rackLocation(getString(dcim, "LOCATION"))
                .rackPosition(getString(dcim, "POSITION"))
                .serialNumber(getString(dcim, "SERIAL_NO"))
                .sourceType("ITAM+DCIM");
        }

        return builder.build();
    }

    private String getString(Map<String, Object> map, String key) {
        Object value = map.get(key);
        return value != null ? value.toString() : null;
    }
}
```

#### 3.3.8 InventoryProviderFactory

```java
package com.ktc.luppiter.core.inventory;

import com.ktc.luppiter.core.inventory.config.InventoryConfig;
import com.ktc.luppiter.core.inventory.enums.InventorySourceType;
import com.ktc.luppiter.core.inventory.provider.ItamDcimProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class InventoryProviderFactory {

    private final InventoryConfig config;
    private final ItamDcimProvider itamDcimProvider;

    public IInventoryProvider getProvider() {
        InventorySourceType sourceType = config.getSource();

        return switch (sourceType) {
            case ITAM_DCIM -> itamDcimProvider;
            // case CMDB -> cmdbProvider;  // 향후
            default -> throw new IllegalStateException("Unsupported source: " + sourceType);
        };
    }

    public InventorySourceType getSourceType() {
        return config.getSource();
    }
}
```

#### 3.3.9 InventoryService

```java
package com.ktc.luppiter.core.inventory;

import com.ktc.luppiter.core.inventory.dto.*;
import com.ktc.luppiter.core.inventory.enums.InventorySourceType;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class InventoryService {

    private final InventoryProviderFactory providerFactory;

    public InventoryResult getDeviceList(InventorySearchRequest request) {
        IInventoryProvider provider = providerFactory.getProvider();
        log.info("Using inventory provider: {}", provider.getSourceType());

        InventoryResult result = provider.getDeviceList(request);

        if (result.isPartialFailure()) {
            log.warn("Partial failure. Failed sources: {}", result.getFailedSources());
        }

        return result;
    }

    public DeviceInfo getDeviceDetail(String deviceId) {
        return providerFactory.getProvider().getDeviceDetail(deviceId);
    }

    public InventorySourceType getCurrentSourceType() {
        return providerFactory.getSourceType();
    }

    public boolean isProviderAvailable() {
        return providerFactory.getProvider().isAvailable();
    }
}
```

---

## 4. Mapper 추가 사항

### 4.1 CtlMapper 추가 메서드

```java
// CtlMapper.java에 추가

/**
 * userId로 사용자 조회 (local_auth_flag 포함)
 */
Map<String, Object> selectUserByUserId(@Param("userId") String userId);
```

**sql-ctl.xml 추가**

```xml
<select id="selectUserByUserId" resultType="map">
    SELECT
        user_id,
        user_name,
        email,
        department,
        local_auth_flag,
        user_status
    FROM cmon_user
    WHERE user_id = #{userId}
</select>
```

### 4.2 ItamMapper 추가 메서드

```java
// ItamMapper.java에 추가

/**
 * 헬스체크
 */
void healthCheck();

/**
 * 장비 상세 조회
 */
Map<String, Object> selectItamInfoDetail(Map<String, Object> params);
```

**sql-itam.xml 추가**

```xml
<select id="healthCheck" resultType="int">
    SELECT 1
</select>

<select id="selectItamInfoDetail" resultType="map">
    SELECT
        barcode,
        tcpiphostname,
        tcpipaddress,
        hosttype,
        asset_status,
        purchase_date
    FROM itam_device
    WHERE barcode = #{barcode}
</select>
```

### 4.3 DcimMapper 추가 메서드

```java
// DcimMapper.java에 추가

/**
 * 장비 상세 조회
 */
Map<String, Object> selectDcimDeviceInfoDetail(Map<String, Object> params);
```

**sql-dcim.xml 추가**

```xml
<select id="selectDcimDeviceInfoDetail" resultType="map">
    SELECT
        EQUNR,
        DATACENTER_NM,
        LOCATION,
        POSITION,
        SERIAL_NO
    FROM dcim_device
    WHERE EQUNR = #{barcode}
</select>
```

---

## 5. 기존 코드 처리

### 5.1 기존 API Deprecated 처리

```java
// CtlRestController.java

/**
 * @deprecated 대신 /api/auth/login 사용
 */
@Deprecated
@PostMapping("/api/ctl/login")
public ResponseEntity<?> login(...) {
    // 내부적으로 새 API 호출
    AuthRequest request = new AuthRequest();
    request.setUserId(userId);
    request.setPassword(password);
    return authController.login(request, httpRequest);
}

/**
 * @deprecated 대신 /api/auth/login 사용
 */
@Deprecated
@PostMapping("/api/ctl/ldapLogin")
public ResponseEntity<?> ldapLogin(...) {
    // 내부적으로 새 API 호출
    AuthRequest request = new AuthRequest();
    request.setUserId(userId);
    request.setPassword(password);
    return authController.login(request, httpRequest);
}
```

### 5.2 기존 Service 연동

```java
// InventoryManagerServiceImpl.java 수정

@Autowired
private InventoryService inventoryService;

/**
 * 기존 메서드 - 새 Service로 위임
 */
public List<Map<String, Object>> getItamDcimList(Map<String, Object> map) {
    InventorySearchRequest request = InventorySearchRequest.builder()
        .hostname((String) map.get("hostname"))
        .ipAddress((String) map.get("ipAddress"))
        .build();

    InventoryResult result = inventoryService.getDeviceList(request);

    // 기존 반환 형식으로 변환
    return result.getDevices().stream()
        .map(this::convertToLegacyFormat)
        .collect(Collectors.toList());
}
```

---

## 6. 프론트엔드 변경

### 6.1 로그인 API 변경

```javascript
// 변경 전
async function login(userId, password) {
    const response = await fetch('/api/ctl/login', {
        method: 'POST',
        body: JSON.stringify({ userId, password })
    });
    return response.json();
}

// 변경 후
async function login(userId, password) {
    const response = await fetch('/api/auth/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ userId, password })
    });
    return response.json();
}
```

### 6.2 부분 실패 알림 처리

```javascript
// 인벤토리 조회 결과 처리
async function getInventoryList() {
    const response = await fetch('/api/inventory/devices');
    const result = await response.json();

    // 부분 실패 시 경고 표시
    if (result.partialFailure) {
        showWarning(result.warningMessages.join('\n'));
    }

    return result.devices;
}
```

---

## 7. 테스트 코드

### 7.1 LocalAuthProvider 테스트

```java
@ExtendWith(MockitoExtension.class)
class LocalAuthProviderTest {

    @Mock
    private CtlMapper ctlMapper;

    @InjectMocks
    private LocalAuthProvider provider;

    @Test
    @DisplayName("정상 로그인 - 성공")
    void authenticate_Success() {
        // given
        AuthRequest request = new AuthRequest();
        request.setUserId("admin");
        request.setPassword("password123");

        Map<String, Object> userInfo = Map.of(
            "user_id", "admin",
            "user_name", "관리자",
            "password", CryptoUtil.encryptSHA256("password123"),
            "user_status", "ACTIVE"
        );
        when(ctlMapper.selectUserInfo(any())).thenReturn(userInfo);

        // when
        AuthResult result = provider.authenticate(request);

        // then
        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getUserId()).isEqualTo("admin");
        assertThat(result.getAuthType()).isEqualTo(AuthType.LOCAL);
    }

    @Test
    @DisplayName("비밀번호 불일치 - 실패")
    void authenticate_InvalidPassword() {
        // given
        AuthRequest request = new AuthRequest();
        request.setUserId("admin");
        request.setPassword("wrong");

        Map<String, Object> userInfo = Map.of(
            "password", CryptoUtil.encryptSHA256("password123"),
            "user_status", "ACTIVE"
        );
        when(ctlMapper.selectUserInfo(any())).thenReturn(userInfo);

        // when
        AuthResult result = provider.authenticate(request);

        // then
        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getErrorCode()).isEqualTo("AUTH_002");
    }
}
```

### 7.2 AuthProviderFactory 테스트

```java
@ExtendWith(MockitoExtension.class)
class AuthProviderFactoryTest {

    @Mock private AuthConfig authConfig;
    @Mock private AuthConfig.External externalConfig;
    @Mock private LocalAuthProvider localAuthProvider;
    @Mock private LdapAuthProvider ldapAuthProvider;

    @InjectMocks
    private AuthProviderFactory factory;

    @BeforeEach
    void setUp() {
        when(authConfig.getExternal()).thenReturn(externalConfig);
        when(externalConfig.getType()).thenReturn(AuthType.LDAP);
    }

    @Test
    @DisplayName("local_auth_flag=Y → LocalAuthProvider")
    void getProvider_LocalFlag_Y() {
        Map<String, Object> userInfo = Map.of("local_auth_flag", "Y");

        IAuthProvider provider = factory.getProvider(userInfo);

        assertThat(provider).isEqualTo(localAuthProvider);
    }

    @Test
    @DisplayName("local_auth_flag=N → LdapAuthProvider")
    void getProvider_LocalFlag_N() {
        Map<String, Object> userInfo = Map.of("local_auth_flag", "N");

        IAuthProvider provider = factory.getProvider(userInfo);

        assertThat(provider).isEqualTo(ldapAuthProvider);
    }
}
```

### 7.3 ItamDcimProvider 테스트

```java
@ExtendWith(MockitoExtension.class)
class ItamDcimProviderTest {

    @Mock private ItamMapper itamMapper;
    @Mock private DcimMapper dcimMapper;

    @InjectMocks
    private ItamDcimProvider provider;

    @Test
    @DisplayName("ITAM + DCIM 정상 조회 및 병합")
    void getDeviceList_Success() {
        // given
        List<Map<String, Object>> itamList = List.of(
            Map.of("barcode", "BC001", "tcpiphostname", "server01")
        );
        List<Map<String, Object>> dcimList = List.of(
            Map.of("EQUNR", "BC001", "DATACENTER_NM", "분당IDC")
        );

        when(itamMapper.selectItamInfoList(any())).thenReturn(itamList);
        when(dcimMapper.selectDcimDeviceInfoList(any())).thenReturn(dcimList);

        // when
        InventoryResult result = provider.getDeviceList(
            InventorySearchRequest.builder().build());

        // then
        assertThat(result.isPartialFailure()).isFalse();
        assertThat(result.getDevices()).hasSize(1);
        assertThat(result.getDevices().get(0).getDatacenterName()).isEqualTo("분당IDC");
    }

    @Test
    @DisplayName("DCIM 실패 시 부분 성공")
    void getDeviceList_DcimFailure() {
        // given
        List<Map<String, Object>> itamList = List.of(
            Map.of("barcode", "BC001", "tcpiphostname", "server01")
        );

        when(itamMapper.selectItamInfoList(any())).thenReturn(itamList);
        when(dcimMapper.selectDcimDeviceInfoList(any()))
            .thenThrow(new RuntimeException("DCIM 연결 실패"));

        // when
        InventoryResult result = provider.getDeviceList(
            InventorySearchRequest.builder().build());

        // then
        assertThat(result.isPartialFailure()).isTrue();
        assertThat(result.getFailedSources()).contains("DCIM");
        assertThat(result.getDevices()).hasSize(1);  // ITAM 데이터는 반환
    }
}
```

---

## 8. 마이그레이션 절차

### Phase 1: 인프라 준비

1. 신규 패키지 생성 (`com.ktc.luppiter.core.auth`, `com.ktc.luppiter.core.inventory`)
2. application.yml에 설정 추가
3. Mapper에 신규 메서드 추가

### Phase 2: 인증 모듈화

1. 인터페이스 및 DTO 생성
2. LocalAuthProvider 구현 (기존 로직 이전)
3. LdapAuthProvider 구현 (LdapLoginUtils 로직 이전)
4. Factory, Service, Controller 구현
5. 단위 테스트 작성 및 검증

### Phase 3: 인벤토리 모듈화

1. 인터페이스 및 DTO 생성
2. ItamDcimProvider 구현 (기존 로직 이전)
3. Factory, Service 구현
4. 단위 테스트 작성 및 검증

### Phase 4: 통합 및 전환

1. 기존 API deprecated 처리
2. 프론트엔드 API 호출 변경
3. 통합 테스트 수행
4. 기존 코드 제거 (안정화 후)

---

## 9. 검토 필요 사항

### 9.1 확인 필요

| # | 항목 | 질문 | 담당 |
|---|------|------|------|
| 1 | **local_auth_flag 컬럼** | cmon_user 테이블에 해당 컬럼 존재 여부 확인 | DBA |
| 2 | **기존 LDAP 설정** | 현재 application.yml의 LDAP 설정 키 이름 확인 | 개발자 |
| 3 | **세션 생성 로직** | UserSessionManager 클래스 존재 여부, 없으면 신규 구현 필요 | 개발자 |
| 4 | **프론트엔드 영향** | 로그인 API 변경 시 수정 필요한 화면 목록 | 프론트 |

### 9.2 설계 결정 사항

| # | 항목 | 결정 내용 |
|---|------|----------|
| 1 | API 통합 | `/api/auth/login` 단일 API로 통합 |
| 2 | 인증 분기 | `local_auth_flag` 기준으로 Provider 선택 |
| 3 | 인벤토리 구성 | ITAM+DCIM 통합 Provider, CMDB 별도 Provider |
| 4 | 부분 실패 | 가능한 데이터 반환 + 경고 메시지 |
| 5 | 소스 선택 | Config(yaml)로 단일 소스 지정 |

---

## 10. 체크리스트

### 인증 모듈화

- [ ] `IAuthProvider` 인터페이스 생성
- [ ] `AuthRequest`, `AuthResult` DTO 생성
- [ ] `AuthType` enum 생성
- [ ] `AuthConfig` 설정 클래스 생성
- [ ] `LocalAuthProvider` 구현
- [ ] `LdapAuthProvider` 구현
- [ ] `AuthProviderFactory` 구현
- [ ] `AuthenticationService` 구현
- [ ] `AuthController` 구현
- [ ] `CtlMapper.selectUserByUserId()` 추가
- [ ] application.yml 설정 추가
- [ ] 기존 API deprecated 처리
- [ ] 단위 테스트 작성
- [ ] 통합 테스트 작성

### 인벤토리 모듈화

- [ ] `IInventoryProvider` 인터페이스 생성
- [ ] `InventorySearchRequest`, `DeviceInfo`, `InventoryResult` DTO 생성
- [ ] `InventorySourceType` enum 생성
- [ ] `InventoryConfig` 설정 클래스 생성
- [ ] `ItamDcimProvider` 구현
- [ ] `InventoryProviderFactory` 구현
- [ ] `InventoryService` 구현
- [ ] `ItamMapper.healthCheck()`, `selectItamInfoDetail()` 추가
- [ ] `DcimMapper.selectDcimDeviceInfoDetail()` 추가
- [ ] application.yml 설정 추가
- [ ] 기존 Service 연동
- [ ] 단위 테스트 작성
- [ ] 통합 테스트 작성

---

> **작성**: Claude Code
> **문의**: 개발팀
