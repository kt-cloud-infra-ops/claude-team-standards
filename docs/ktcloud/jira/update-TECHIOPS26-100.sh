#!/usr/bin/env bash
# TECHIOPS26-100 Summary + A.C. update. Usage: export ATLASSIAN_AUTH=$(echo -n 'email:api_token' | base64) && bash this-file

AUTH="${ATLASSIAN_AUTH:?Set ATLASSIAN_AUTH}"
curl -s -w "\nHTTP:%{http_code}" -X PUT \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d '{"fields":{"summary":"유피테르 프로젝트 테스트 자동화 및 검토","customfield_14516":"### 테스트 자동화\n- [ ] luppiter_web E2E 테스트 스위트 로컬/스테이징에서 실행 가능 상태 유지\n- [ ] 이벤트 연동 관련 테스트 (next 연동, 추상화 STG) 검증\n- [ ] 테스트 계정 자동 생성/삭제(global-setup·teardown) 동작 확인\n\n### 테스트 자동화 검토·문서\n- [ ] E2E 현황 문서 최신화 (실행 결과, 통과/실패 건수)\n- [ ] 로컬 환경 커버 가능 범위 문서 유지 (web/scheduler/web_e2e, 제한 사항)\n- [ ] 로컬 커버 범위 문서 Confluence [LUPPITER]에 반영\n\n### (선택) CI/안정화\n- [ ] E2E 셀렉터·Flaky 이슈 정리 및 필요 시 수정\n- [ ] CI 파이프라인 연동 검토"}}' \
  "https://ktcloud.atlassian.net/rest/api/3/issue/TECHIOPS26-100"
