# Luppiter Web API 레퍼런스

## 개요

Luppiter Web 프로젝트의 RESTful API 목록.

> **참고**: 상세 API 문서는 [APIDOG SRE개발팀 Luppiter](https://apidog.com)에 정리됨

---

## 권한 체계

| 권한 | 사용자 관리 | 그룹 관리 | 이벤트 처리 | 이벤트 조회 | 대시보드 |
|------|:-----------:|:---------:|:-----------:|:-----------:|:--------:|
| 계정관리자 | O | O | O | O | O |
| 관제담당자 | O | O | O | O | O |
| 관제자 | X | X | O | O | O |
| 사용자 | X | X | X | O | O |
| 운영담당자 | X | X | X | O | O |

---

## 공통 응답 코드

| resCode | 설명 |
|---------|------|
| 000 | 성공 |
| 900 | 변경된 데이터 없음 |
| 999 | 시스템 오류 |

---

## 1. 인증 API

| API | 메서드 | 엔드포인트 | 설명 |
|-----|--------|------------|------|
| 로그인 | POST | `/api/ctl/login` | 일반 로그인 |
| LDAP 로그인 | POST | `/api/ctl/ldapLogin` | LDAP 로그인 |
| 로그아웃 | GET | `/view/ctl/logout` | 로그아웃 |
| 세션 체크 | POST | `/api/ctl/checkSession` | 세션 유효성 확인 |
| OTP 전송 | POST | `/api/ctl/otpSend` | OTP 인증번호 전송 |

---

## 2. 사용자 관리 API

| API | 메서드 | 엔드포인트 | 설명 |
|-----|--------|------------|------|
| 사용자 목록 | POST | `/api/ctl/list` | 사용자 목록 조회 |
| 사용자 등록 | POST | `/api/ctl/add` | 신규 사용자 등록 |
| 사용자 수정 | POST | `/api/ctl/update` | 사용자 정보 수정 |
| 사용자 삭제 | POST | `/api/ctl/delete` | 사용자 삭제 |
| ID 중복체크 | POST | `/api/ctl/check` | 사용자 ID 중복 확인 |
| 비밀번호 변경 | POST | `/api/ctl/updateUserPassword` | 비밀번호 변경 |

---

## 3. 그룹 관리 API

| API | 메서드 | 엔드포인트 | 설명 |
|-----|--------|------------|------|
| 그룹 목록 | POST | `/api/ctl/groupList` | 그룹 목록 조회 |
| 그룹 등록 | POST | `/api/ctl/insertGroup` | 신규 그룹 등록 |
| 그룹 수정 | POST | `/api/ctl/updateGroup` | 그룹 정보 수정 |
| 그룹 삭제 | POST | `/api/ctl/deleteGroup` | 그룹 삭제 |
| 그룹 사용자 목록 | POST | `/api/ctl/groupUserList` | 그룹 소속 사용자 조회 |
| 그룹 사용자 등록 | POST | `/api/ctl/insertGroupUser` | 그룹에 사용자 추가 |
| 그룹 사용자 삭제 | POST | `/api/ctl/deleteGroupUser` | 그룹에서 사용자 제거 |

---

## 4. 이벤트 관리 API

| API | 메서드 | 엔드포인트 | 설명 |
|-----|--------|------------|------|
| 이벤트 목록 | POST | `/api/evt/list` | 이벤트 목록 조회 |
| 이벤트 상세 | POST | `/api/evt/info` | 이벤트 상세 정보 |
| 1차 인지 | POST | `/api/evt/updateOne/{eventType}` | 1차 인지 처리 |
| 2차 인지 | POST | `/api/evt/updateTwoPerceive` | 2차 인지 처리 |
| 1차 이관 | POST | `/api/evt/updateOneTransfer` | 1차 이관 처리 |
| 2차 이관 | POST | `/api/evt/updateTwoTransfer` | 2차 이관 처리 |
| 인시던트 생성 | POST | `/api/evt/createIncident` | 이벤트→인시던트 |
| 이벤트 종료 | POST | `/api/evt/updateEventEnd` | 이벤트 종료 |
| 일괄 종료 | POST | `/api/evt/endSelectedEventList` | 선택 이벤트 일괄 종료 |
| 엑셀 다운로드 | POST | `/api/evt/excellist` | 엑셀 다운로드 |

---

## 5. 인시던트 관리 API

| API | 메서드 | 엔드포인트 | 설명 |
|-----|--------|------------|------|
| 인시던트 목록 | POST | `/api/icd/list` | 인시던트 목록 조회 |
| 인시던트 상세 | POST | `/api/icd/detail` | 인시던트 상세 정보 |
| 인시던트 수정 | POST | `/api/icd/save` | 인시던트 정보 수정 |
| 조치 완료 | POST | `/api/icd/end` | 인시던트 조치 완료 |
| 수동 생성 | POST | `/api/icd/createManualIncident` | 수동 인시던트 생성 |
| 조치 진행 결과 | POST | `/api/icd/proclist` | 조치 진행 결과 조회 |
| 신규 알람 건수 | POST | `/api/icd/newAlarmCount` | 신규 알람 건수 |
| 엑셀 다운로드 | POST | `/api/icd/excelList` | 엑셀 다운로드 |

---

## 6. 대시보드 API

| API | 메서드 | 엔드포인트 | 설명 |
|-----|--------|------------|------|
| 월보드 데이터 | POST | `/api/dashboard/wallMain` | 종합 대시보드 |
| 관제 대시보드 | POST | `/api/dashboard/list` | 관제 대시보드 |

---

## 7. 레이어/호스트그룹 API

| API | 메서드 | 엔드포인트 | 설명 |
|-----|--------|------------|------|
| 레이어 코드 목록 | POST | `/api/ctl/layerCodeList` | 레이어 코드 조회 |
| 레이어 코드 저장 | POST | `/api/ctl/saveLayerCode` | 레이어 코드 저장 |
| 호스트그룹 목록 | POST | `/api/ctl/selectHostGroupList` | 호스트그룹 조회 |
| 호스트그룹 저장 | POST | `/api/ctl/saveHostGroupNmList` | 호스트그룹 저장 |

---

## 8. 담당관리 API

| API | 메서드 | 엔드포인트 | 설명 |
|-----|--------|------------|------|
| 담당 정보 조회 | POST | `/api/ctl/selectRespManageInfo` | 담당 정보 조회 |
| 담당 정보 저장 | POST | `/api/ctl/saveRespManageInfo` | 담당 정보 저장 |
| 담당자 목록 | POST | `/api/ctl/personInChargeList` | 담당자 목록 |

---

## 주요 파라미터 예시

### 로그인
```json
{
  "loginId": "admin",
  "loginPassword": "password123"
}
```

### 이벤트 목록 조회
```json
{
  "pageNum": 1,
  "pageSize": 20,
  "startDate": "2026-01-01",
  "endDate": "2026-01-30",
  "kwEventLevel": "2",
  "kwZabbixState": "신규"
}
```

### 인시던트 상세 조회
```json
{
  "incidentId": "ICD202601300001"
}
```

---

**최종 업데이트**: 2026-01-30
