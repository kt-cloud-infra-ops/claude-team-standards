# Luppiter 서비스 문서

관제 플랫폼

## Confluence 동기화

- **스페이스**: [기술] InfraOps개발팀 (CL23)
- **URL**: https://ktcloud.atlassian.net/wiki/spaces/CL23/overview

## 폴더 구조

```
luppiter/
├── architecture/       # 서비스 아키텍처
├── features/           # 주요 기능 명세
├── history/            # History
├── sop/                # 운영 절차서
├── decisions/          # 서비스 레벨 ADR
├── cicd/               # CI/CD 파이프라인
└── projects/           # 프로젝트별 문서
    ├── scheduler/      # luppiter_scheduler
    ├── web/            # luppiter_web
    └── morning_report/ # luppiter_morning_report
```

> 지원 프로젝트는 `docs/support-projects/`로 이동

## Confluence 매핑

| 로컬 폴더 | Confluence 위치 |
|----------|----------------|
| `architecture/` | [LUPPITER] 서비스 아키텍처 |
| `features/` | [LUPPITER] 주요 기능 명세서 |
| `history/` | [LUPPITER] History |
| `sop/` | [LUPPITER] SOP |
| `projects/scheduler/decisions/` | [LUPPITER] History (설계 결정) |
| `projects/web/screens/` | 주요 기능 명세서 > 화면 명세 |
| `projects/web/api/` | 주요 기능 명세서 > API |
| `cicd/` | (내부 문서, Confluence X) |

## 프로젝트 구성

| 프로젝트 | 폴더 | 기술 스택 |
|---------|------|----------|
| luppiter_scheduler | `projects/scheduler/` | Java/Spring |
| luppiter_web | `projects/web/` | Java/Spring |
| luppiter_morning_report | `projects/morning_report/` | Python |

## CI/CD 파이프라인

| 파일 | 용도 | 환경 |
|------|------|------|
| `cicd/stg-deploy-with-db-sync.groovy` | 스테이징 배포 + DB 동기화 | STG |
| `cicd/stg-db-sync-pipeline.groovy` | DB 동기화 전용 | STG |

> 상세: [cicd/README.md](cicd/README.md)

## Claude 전용 (Confluence X)

`claude_` prefix가 붙은 파일과 `cicd/` 폴더는 Confluence 동기화 제외

---

**최종 업데이트**: 2026-02-03
