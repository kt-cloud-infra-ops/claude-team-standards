# Luppiter Web 문서

## 폴더 구조

```
docs/projects/luppiter_web/
├── architecture/        # 시스템 아키텍처
│   ├── 시스템_아키텍처.md
│   └── 권한_체계.md
├── api/                 # API 레퍼런스
│   └── API_레퍼런스.md
├── guide/               # 개발 가이드
│   ├── AI_코딩_가이드.md
│   ├── 테스트_가이드.md
│   └── 로그인_세션.md
├── screens/             # 화면별 구조 (16개)
│   └── *_화면_구조.md
├── sop/                 # 운영 절차서
│   ├── luppiter-db-기존서버-데이터복구.md
│   └── luppiter-db-신규서버-설치복구.md
└── archive/             # 보관 문서
    └── 마이크로서비스_리팩토링_초안.md
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

### 운영 (SOP)
| 문서 | 설명 |
|------|------|
| [기존서버-데이터복구](sop/luppiter-db-기존서버-데이터복구.md) | 기존 DB 서버에 백업 데이터 복구 |
| [신규서버-설치복구](sop/luppiter-db-신규서버-설치복구.md) | 신규 서버 PostgreSQL 설치 및 복구 |

---

## 공통 문서 참조

프로젝트 공통 규칙은 상위 문서 참조:
- 코딩 스타일: `~/.claude/rules/coding-style.md`
- 테스트 요구사항: `~/.claude/rules/testing.md`
- Java 코드 스타일: `/docs/learnings/008-kt-cloud-java-code-style.md`

---

**최종 업데이트**: 2026-01-30
