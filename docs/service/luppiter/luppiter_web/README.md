# Luppiter Web 문서

## 폴더 구조

```
docs/projects/luppiter_web/
├── architecture/        # 시스템 아키텍처
├── api/                 # API 레퍼런스
├── guide/               # 개발 가이드
├── o11y/                # Observability 연동 (Web 영역)
├── screens/             # 화면별 구조 (16개)
├── sop/                 # 운영 절차서
├── e2e/                 # E2E 테스트
├── temp/                # 임시 문서
├── archive/             # 보관 문서
└── coding-standards.md  # 프로젝트 코딩 표준
```

## 문서 목록

### 아키텍처
| 문서 | 설명 |
|------|------|
| [시스템_아키텍처](architecture/시스템_아키텍처.md) | 이벤트/인시던트 시스템 구조 |
| [권한_체계](architecture/권한_체계.md) | 그룹 기반 접근 제어 |

### API
| 문서 | 설명 |
|------|------|
| [API_레퍼런스](api/API_레퍼런스.md) | 전체 API 목록 |

### 개발 가이드
| 문서 | 설명 |
|------|------|
| [AI_코딩_가이드](guide/AI_코딩_가이드.md) | AI 도구 코드 생성 규칙 |
| [테스트_가이드](guide/테스트_가이드.md) | 단위/통합 테스트 작성법 |
| [로그인_세션](guide/로그인_세션.md) | 세션 기반 인증 가이드 |

### Observability 연동 (o11y/) - Web 영역

| 문서 | 설명 |
|------|------|
| [README.md](o11y/README.md) | O11y Web 영역 개요 |
| [implementation-guide.md](o11y/implementation-guide.md) | Web 구현 가이드 (Controller, Service, JSP 패턴) |

> 공통 설계 문서는 [luppiter_scheduler/o11y](../luppiter_scheduler/o11y/) 참조

### 운영 (SOP)

| 문서 | 설명 |
|------|------|
| [기존서버-데이터복구](sop/luppiter-db-기존서버-데이터복구.md) | 기존 DB 서버에 백업 데이터 복구 |
| [신규서버-설치복구](sop/luppiter-db-신규서버-설치복구.md) | 신규 서버 PostgreSQL 설치 및 복구 |

---

## 공통 가이드 참조

- [Java 코드 스타일](../../../claude_lessons_learned/java/kt-cloud-style.md)
- [SRE 코딩 가이드](../../../claude_lessons_learned/java/sre-coding.md)
- [디자인 패턴](../../../claude_lessons_learned/java/design-patterns.md)
- [DB 최적화](../../../claude_lessons_learned/db/database-optimization.md)
- [Playwright E2E 패턴](../../../claude_lessons_learned/common/playwright-e2e-patterns.md)

## Confluence 동기화

아키텍처, SOP 문서는 Confluence에도 동기화됨:
- `docs/confluence/luppiter/architecture/`
- `docs/confluence/luppiter/sop/`

---

**최종 업데이트**: 2026-02-02
