---
tags:
  - type/reference
  - domain/jira
  - domain/observability
  - service/luppiter
  - audience/team
---

> 상위: [next-observability](README.md) · [docs](../../README.md)

# O11y 연동 프로젝트 - Jira 이슈 목록

> 조회일: 2026-02-06
> 프로젝트: TECHIOPS26

---

## 요약

| 구분 | 개수 |
|------|------|
| 에픽 | 3건 |
| 작업 | 5건 |
| 진행 중 | 3건 |
| 완료 | 5건 |

---

## 에픽 목록

| 티켓 | 제목 | 상태 | 담당자 | 멀티리전 영향 |
|------|------|------|--------|--------------|
| [TECHIOPS26-220](https://ktcloud.atlassian.net/browse/TECHIOPS26-220) | NEXT 관제분야 o11y Event 연동 (예외 관리 화면) | 🔄 진행 중 | 김지웅 | 🟡 중간 |
| [TECHIOPS26-221](https://ktcloud.atlassian.net/browse/TECHIOPS26-221) | NEXT 관제분야 o11y Event 연동 (메인터넌스 관리 화면) | 🔄 진행 중 | 김지웅 | 🔴 **높음** |
| [TECHIOPS26-222](https://ktcloud.atlassian.net/browse/TECHIOPS26-222) | NEXT 관제분야 o11y Event 연동 (이벤트 조회 화면) | 🔄 진행 중 | 김지웅 | 🟢 낮음 |

---

## 작업 목록

| 티켓 | 제목 | 상태 | 담당자 | 비고 |
|------|------|------|--------|------|
| [TECHIOPS26-227](https://ktcloud.atlassian.net/browse/TECHIOPS26-227) | 서비스/플랫폼 등록 화면설계 | ✅ 완료 | 김지웅 | 설계 |
| [TECHIOPS26-228](https://ktcloud.atlassian.net/browse/TECHIOPS26-228) | 서비스/플랫폼 등록 설계 협의 | ✅ 완료 | 김지웅 | 설계 |
| [TECHIOPS26-231](https://ktcloud.atlassian.net/browse/TECHIOPS26-231) | 계위/호스트 관리 화면설계 | ✅ 완료 | 김지웅 | 설계 |
| [TECHIOPS26-232](https://ktcloud.atlassian.net/browse/TECHIOPS26-232) | 계위/호스트 관리 설계 협의 | ✅ 완료 | 김지웅 | 설계 |
| [TECHIOPS26-271](https://ktcloud.atlassian.net/browse/TECHIOPS26-271) | Observability 배포 전 기존 시스템 사전 점검 | 📋 할일 | 김지웅 | cross-cutting |

---

## 멀티 리전(GB/SE) 영향 분석

### 🔴 높음 - 필수 반영

| 티켓 | 영향 내용 | 반영 필요 사항 |
|------|----------|---------------|
| **TECHIOPS26-221** | 메인터넌스 API가 리전별 분리됨 | ObsApiService 리전별 API URL 분기 |

### 🟡 중간 - 확인 필요

| 티켓 | 영향 내용 | 반영 필요 사항 |
|------|----------|---------------|
| **TECHIOPS26-220** | 예외 등록 시 O11y 이벤트 조회 | 리전별 API 호출 분기 (조회용) |

### 🟢 낮음 - 기존 구현 활용

| 티켓 | 이유 |
|------|------|
| TECHIOPS26-222 | 이벤트 상세 표시만, API 연동 없음 |

---

## 에픽 상세

### TECHIOPS26-220: 예외 관리 화면

**상태**: 진행 중
**담당자**: 김지웅
**목표**: 예외 관리에 O11y 타입 추가

**내용**:
- 예외 등록 팝업에 타입 선택 추가
- Service/Platform 예외 상세 테이블 연동

**멀티리전 확인 필요**:
- [ ] O11y 이벤트 조회 시 리전별 API 분기 (조회용)

---

### TECHIOPS26-221: 메인터넌스 관리 화면

**상태**: 진행 중
**담당자**: 김지웅
**목표**: 메인터넌스 관리에 O11y 타입 추가

**내용**:
- 메인터넌스 등록 팝업에 타입 선택 추가
- O11y API 실제 중단 처리 연동

**멀티리전 반영 필요**:
- [ ] ObsApiService 리전별 API URL 분기
- [ ] application.yml에 regions 맵 설정
- [ ] 리전 확장 고려한 Map 기반 구조

---

### TECHIOPS26-222: 이벤트 조회 화면

**상태**: 진행 중
**담당자**: 김지웅
**목표**: 이벤트 조회 화면에 O11y 연동 정보 표시

**내용**:
- source 컬럼 추가
- 대시보드 링크 및 상세 정보 링크

---

## LUPR 프로젝트 관련 이슈 (참고)

TECHIOPS26은 팀 업무 관리용이며, 실제 개발 티켓은 LUPR 프로젝트에 있음.

| TECHIOPS26 | 관련 LUPR | 제목 | 상태 |
|------------|-----------|------|------|
| TECHIOPS26-220 | LUPR-683 | 이벤트 예외 관리 기능 개선 | 개발 |
| TECHIOPS26-221 | LUPR-684 | 메인터넌스 관리 기능 개선 | 개발 |
| TECHIOPS26-222 | LUPR-690 | 이벤트 관리 | 개발 |
| - | LUPR-686 | 이벤트 연동 처리 (Scheduler) | 개발 |
| - | LUPR-687 | 서비스/플랫폼 관리 화면 (DDL, DML) | ✅ 개발완료 |
| - | LUPR-692 | 관제삭제 | 개발 |
| TECHIOPS26-79 | LUPR-699 | 전체 메뉴 서비스 인벤토리 적용 - WEB | 해야 할 일 |
| TECHIOPS26-79 | LUPR-700 | 전체 메뉴 서비스 인벤토리 적용 - Scheduler | 해야 할 일 |

---

## 일정

| 단계 | 일정 | 상태 |
|------|------|------|
| 개발 완료 | 2/13 | 진행 중 |
| 검증 완료 | 2/27 | - |

---

## 변경 이력

| 날짜 | 변경 내용 |
|------|----------|
| 2026-02-06 | TECHIOPS26-271 추가, LUPR-687 개발완료 반영, LUPR-699/700 추가 |
| 2026-02-03 | TECHIOPS26 프로젝트 기준으로 재작성, 멀티리전 영향도 분석 추가 |
