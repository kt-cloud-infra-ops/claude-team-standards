# 학습: Morning Report & Zabbix 프로젝트

## 날짜
2026-01-19

## 프로젝트
morning_report, zabbix_api, zabbix_lib

---

## morning_report (Python)

### 개요
- **목적**: 조근점검 모닝 리포트 생성 및 발송
- **서버**: 10.2.14.55 (C:\zabbix_report)
- **DB**: MariaDB 10.11.2

### 주요 구성
```
morning_report/
├── main.py              # 메인 점검 스크립트
├── collect.py           # 데이터 수집
├── report_generator.py  # HTML 리포트 생성
├── send_mail.py         # 이메일 발송
├── send_slack.py        # Slack 발송
├── auth.py              # Zabbix 인증
├── config.json          # 설정 파일
└── scheduler.py         # 스케줄러
```

### 스케줄링
| 작업 | 시간 | 내용 |
|------|------|------|
| daily_rep.bat | 08:00 | 리포트 생성 + 발송 |
| retry_daily_report.bat | 08:10 | 실패 시 재시도 |
| send_report_staging_web.bat | 08:20 | STAGE 웹 업로드 |

### 배포 방법
```bash
# py → exe 빌드
pip install -r requirements.txt
./make.bat
# dist/ 폴더의 exe 파일을 서버에 복사
```

### 설정 (config.json)
- Zabbix 서버 접속 정보
- 메일 발송 설정 (수신인 cc 추가 가능)

---

## zabbix_api (Python 2.7)

### 개요
- **목적**: 여러 Zabbix 서버 상태 일괄 확인
- **특징**: Python 표준 라이브러리만 사용 (망분리 환경 호환)
- **지원 버전**: Zabbix 6.0, 7.0

### 주요 기능
1. **Web 상태 확인**: curl로 HTTP 응답 확인
2. **프록시 상태 확인**: 최종 접근 시간, 큐 정보
3. **호스트 상태 확인**: 아이템 수집 시간 기반 판단

### 상태 판단 기준
```
비정상 = 수집 시간 - 현재 시간 > 아이템 수집 주기 × 2
```

### 아이템 선택 우선순위
1. agent.ping (Zabbix Agent Ping)
2. IPMI Ping
3. SNMP Ping
4. 기타 랜덤

### 사용법
```bash
python multi_zabbix_checker_py2.py --config zabbix_config.json

# 옵션
--min-hosts 5    # 프록시당 확인 호스트 수
--threshold 5    # 비정상 판단 기준(분)
--show-normal    # 정상 항목도 출력
--debug          # 디버그 모드
```

### 설정 파일 (zabbix_config.json)
```json
[
  {
    "name": "HW ZABBIX",
    "url": "https://hw-zabbix.example.com/zabbix",
    "username": "viewer",
    "password": "****",
    "version": "6.0"
  }
]
```

### 보안 주의
```bash
chmod 600 zabbix_config.json  # 파일 권한 제한
```

---

## zabbix_lib (Java/Maven)

### 개요
- Zabbix 관련 Java 라이브러리
- Maven 프로젝트
- src/main/java 구조

---

## 적용 가능한 상황

### Python 프로젝트 작업 시
- 망분리 환경: 표준 라이브러리만 사용하는 방식 참고
- 스케줄링: Windows 예약 작업 또는 crontab
- py → exe 빌드: pyinstaller 사용

### Zabbix 연동 작업 시
- Zabbix API 버전 차이 주의 (6.0 vs 7.0)
- 인증 필드: 6.0은 `user`, 7.0은 `username`
- 프록시 상태 필드: 6.0은 `status`, 7.0은 `state`

### 모니터링 스크립트 작성 시
- 상태 판단: 수집 주기의 2배 기준
- 출력 형식: 표 형태로 정리
- 요약 통계 포함
