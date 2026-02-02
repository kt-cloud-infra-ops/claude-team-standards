# Luppiter 서비스 문서

이 폴더의 문서는 **Confluence에 업로드 대상**입니다.

## 동기화 대상 스페이스

- **스페이스**: [기술] InfraOps개발팀 (CL23)
- **URL**: https://ktcloud.atlassian.net/wiki/spaces/CL23/overview

## 폴더 구조 ↔ Confluence 매핑

| 로컬 폴더 | Confluence 위치 |
|----------|----------------|
| `architecture/` | [LUPPITER] 서비스 아키텍처 |
| `features/` | [LUPPITER] 주요 기능 명세서 |
| `history/` | [LUPPITER] History |
| `sop/` | [LUPPITER] SOP |
| `support-projects/` | 05. 지원 프로젝트 |
| `support-projects/next-observability/` | 05. 지원 프로젝트 > next-observability |
| `luppiter_web/screens/` | [LUPPITER] 주요 기능 명세서 > 화면 명세 |
| `luppiter_web/api/` | [LUPPITER] 주요 기능 명세서 > API |
| `luppiter_scheduler/decisions/` | [LUPPITER] History (설계 결정) |

## Claude 전용 (Confluence X)

`claude_` prefix가 붙은 폴더/파일은 동기화 제외:

- `luppiter_scheduler/claude_temp/` - 임시 작업 파일
- `luppiter_web/claude_temp/` - 임시 작업 파일
- `luppiter_web/claude_archive/` - 아카이브 문서
- `claude_*.md` 파일 - 구현 가이드, 분석 문서

## 동기화 절차

1. **변경 확인**: 로컬과 Confluence 양쪽 변경 사항 확인
2. **충돌 해결**: 양쪽 모두 변경된 경우 수동 머지
3. **업로드**: Claude가 `mcp__atlassian__update_confluence_page` 사용
4. **검증**: 업로드 후 Confluence에서 확인

## 주의사항

- **항상 사람이 의사결정** 후 동기화
- Confluence가 최신인 경우 로컬로 다운로드 먼저
- 대량 변경 시 백업 권장

## 지원프로젝트 참고

| 프로젝트 | Confluence 이름 | 상태 |
|---------|----------------|------|
| O11y 연동 | next-observability | 설계 완료, 개발 전 |

---

**최종 업데이트**: 2026-02-02
