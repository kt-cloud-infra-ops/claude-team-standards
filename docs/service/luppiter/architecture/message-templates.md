# 메시지 발송 양식 정리

> **작성일**: 2026-02-04
> **참조**: message-delivery-architecture.md, [매체발송 기능 정리](https://ktcloud.atlassian.net/wiki/spaces/SREP/pages/1381466169)

---

## 1. 전체 알림 기능 현황

### 1.1 기능별 발송 메시지 (코드 검증 완료)

| 기능 | Case | SMS/LMS | Email | Slack (AS-IS) | Slack (TO-BE) | 미리보기 |
|------|------|---------|-------|---------------|---------------|----------|
| 이벤트 | 발생 | `NEW[F]HITACHI_AMS2500_10.4.34.19_05R1008_87013424_2[HW6213] PATH 상태 비 정상` | [Email](./email-previews/event-email.html) | 🚨 NEW[F]HITACHI_AMS2500_10.4.34.19_05R1008_87013424_2[HW6213] PATH 상태 비 정상<br>━━━━━━━━━━━━━━━━━━━━━━━━━━<br>이벤트ID: E2025111700043<br>분류(L1): IPC상품 /도메인(L2): ktc_KT Captive<br>표준서비스(L3): KT-Legacy인프라 /zone(L4): LEG-CA-PRD<br>단위서비스명: -<br>설비바코드: K911760600010046<br>**이벤트 제목**: [HW6213] PATH 상태 비 정상<br>관제영역: HW /이벤트 등급: Fatal<br>이벤트 발생시간: 2025-11-17 03:58:48<br>이벤트 해소시간: -<br>이벤트 상태: 지속 /이벤트 대응단계: 신규<br>**호스트명**: HITACHI_AMS2500_10.4.34.19_05R1008_87013424_2<br>TCP IP: - /MGMT IP: -<br>IPMI IP: 10.4.34.19 /**이벤트 수집 IP**: 10.4.34.19<br>장비위치: [지상2층-서버5실] 천안CDC - 1008(상면정보) - 1(실장위치) | 🚨 이벤트 [신규] [등급] [이벤트코드] 이벤트명<br>• 대상: [L3/L4] 호스트명 (설비바코드)<br>• 발생: YYYY-MM-DD HH:mm:ss<br>• 해소: -<br>• IP (수집, MGMT, IPMI): (인프라만) | [AS-IS](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%3Arotating_light%3A%20%2ANEW%5BF%5DHITACHI_AMS2500_10.4.34.19_05R1008_87013424_2%5BHW6213%5D%20PATH%20%5Cuc0c1%5Cud0dc%20%5Cube44%20%5Cuc815%5Cuc0c1%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22divider%22%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc774%5Cubca4%5Cud2b8ID%2A%5CnE2025111700043%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cubd84%5Cub958%28L1%29%2A%5CnIPC%5Cuc0c1%5Cud488%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cub3c4%5Cuba54%5Cuc778%28L2%29%2A%5Cnktc_KT%20Captive%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cud45c%5Cuc900%5Cuc11c%5Cube44%5Cuc2a4%28L3%29%2A%5CnKT-Legacy%5Cuc778%5Cud504%5Cub77c%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2Azone%28L4%29%2A%5CnLEG-CA-PRD%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cub2e8%5Cuc704%5Cuc11c%5Cube44%5Cuc2a4%5Cuba85%2A%5Cn-%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc124%5Cube44%5Cubc14%5Cucf54%5Cub4dc%2A%5CnK911760600010046%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuad00%5Cuc81c%5Cuc601%5Cuc5ed%2A%5CnHW%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc774%5Cubca4%5Cud2b8%20%5Cuc81c%5Cubaa9%2A%5Cn%5BHW6213%5D%20PATH%20%5Cuc0c1%5Cud0dc%20%5Cube44%20%5Cuc815%5Cuc0c1%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc774%5Cubca4%5Cud2b8%20%5Cub4f1%5Cuae09%2A%5CnFatal%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc774%5Cubca4%5Cud2b8%20%5Cuc0c1%5Cud0dc%2A%5Cn%5Cuc9c0%5Cuc18d%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc774%5Cubca4%5Cud2b8%20%5Cubc1c%5Cuc0dd%5Cuc2dc%5Cuac04%2A%5Cn2025-11-17%2003%3A58%3A48%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc774%5Cubca4%5Cud2b8%20%5Cud574%5Cuc18c%5Cuc2dc%5Cuac04%2A%5Cn-%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc774%5Cubca4%5Cud2b8%20%5Cub300%5Cuc751%5Cub2e8%5Cuacc4%2A%5Cn%5Cuc2e0%5Cuaddc%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cud638%5Cuc2a4%5Cud2b8%5Cuba85%2A%5CnHITACHI_AMS2500_10.4.34.19_05R1008_87013424_2%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2ATCP%20IP%2A%5Cn-%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2AMGMT%20IP%2A%5Cn-%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2AIPMI%20IP%2A%5Cn10.4.34.19%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc774%5Cubca4%5Cud2b8%20%5Cuc218%5Cuc9d1%20IP%2A%5Cn10.4.34.19%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc7a5%5Cube44%5Cuc704%5Cuce58%2A%5Cn%5B%5Cuc9c0%5Cuc0c12%5Cuce35-%5Cuc11c%5Cubc845%5Cuc2e4%5D%20%5Cucc9c%5Cuc548CDC%20-%201008%28%5Cuc0c1%5Cuba74%5Cuc815%5Cubcf4%29%20-%201%28%5Cuc2e4%5Cuc7a5%5Cuc704%5Cuce58%29%22%7D%7D%5D%7D) [TO-BE](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22header%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22plain_text%22%2C%20%22text%22%3A%20%22%F0%9F%94%A7%20%EB%A9%94%EC%9D%B8%ED%84%B0%EB%84%8C%EC%8A%A4%20%5B%EC%88%98%EC%A0%95%5D%20%5BT25081900004%5D%20Zabbix%20%ED%81%AC%EB%A1%9C%EC%8A%A4%20%EA%B4%80%EC%A0%9C%20%EC%9D%B4%EA%B4%80%20%EC%9E%91%EC%97%85%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%E2%80%A2%20%2A%EA%B8%B0%EA%B0%84%3A%2A%202025-08-19%2018%3A00%20~%202026-08-19%2017%3A59%5Cn%E2%80%A2%20%2A%EB%93%B1%EB%A1%9D%3A%2A%20%EC%9C%A0%ED%94%BC%ED%85%8C%EB%A5%B4_%EA%B3%B5%EC%9A%A9%EA%B3%84%EC%A0%95%20%28Cloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C%ED%8C%80%29%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%ED%98%B8%EC%8A%A4%ED%8A%B8%3A%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BCloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C/ECLS-M1-COREMGMT%5D%20m1-jpt-prd-zab-d01%20%2810.2.14.141%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BCloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C/ECLS-M1-COREMGMT%5D%20m1-jpt-prd-zab-d02%20%2810.2.14.142%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BCloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C/ECLS-M1-COREMGMT%5D%20m1-jpt-prd-zab-d01_d02_VIP%20%2810.2.14.141%29%22%7D%5D%7D%5D%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%EC%9D%B4%EB%B2%A4%ED%8A%B8%3A%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BDB1213%5D%20Session%20Connect%20Warning%20%2896.62%25%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BDB1211%5D%20Session%20Connect%20%EC%A6%9D%EA%B0%80%20%2896.62%25%29%22%7D%5D%7D%5D%7D%5D%7D%5D%7D) |
| 이벤트 | 해소 | `END[F]HITACHI_AMS2500_10.4.34.18_05R1008_87013424_1[HW6213] PATH 상태 비 정상` | [Email](./email-previews/event-email.html) | 발생과 동일 (해소시간, 상태 변경) | ✅ 이벤트 [해소] [등급] [이벤트코드] 이벤트명<br>• 대상: [L3/L4] 호스트명 (설비바코드)<br>• 발생: YYYY-MM-DD HH:mm:ss<br>• 해소: YYYY-MM-DD HH:mm:ss<br>• IP (수집, MGMT, IPMI): (인프라만) | [TO-BE](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22context%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc608%5Cuc2dc%201%3A%20%5Cuc778%5Cud504%5Cub77c%20%5Cuc774%5Cubca4%5Cud2b8%20%28%5Cud574%5Cuc18c%29%2A%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22header%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22plain_text%22%2C%20%22text%22%3A%20%22%5Cu2705%20%5Cuc774%5Cubca4%5Cud2b8%20%5B%5Cud574%5Cuc18c%5D%20%5BFatal%5D%20%5BHW6213%5D%20PATH%20%5Cuc0c1%5Cud0dc%20%5Cube44%20%5Cuc815%5Cuc0c1%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cub300%5Cuc0c1%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BKT-Legacy%5Cuc778%5Cud504%5Cub77c%2FLEG-CA-PRD%5D%20HITACHI_AMS2500_10.4.34.19_05R1008_87013424_2%20%28K911760600010046%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cubc1c%5Cuc0dd%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%222025-11-17%2003%3A58%3A48%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cud574%5Cuc18c%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%222025-11-17%2004%3A15%3A32%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22IP%20%28%5Cuc218%5Cuc9d1%2C%20MGMT%2C%20IPMI%29%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%2210.4.34.19%2C%20-%2C%2010.4.34.19%22%7D%5D%7D%5D%7D%5D%7D%2C%20%7B%22type%22%3A%20%22divider%22%7D%2C%20%7B%22type%22%3A%20%22context%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc608%5Cuc2dc%202%3A%20%5Cuc11c%5Cube44%5Cuc2a4%20%5Cuc774%5Cubca4%5Cud2b8%20%28%5Cud574%5Cuc18c%29%2A%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22header%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22plain_text%22%2C%20%22text%22%3A%20%22%5Cu2705%20%5Cuc774%5Cubca4%5Cud2b8%20%5B%5Cud574%5Cuc18c%5D%20%5BCritical%5D%20%5BSVC1001%5D%20API%20Gateway%20Latency%20High%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cub300%5Cuc0c1%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BNEXT-apigw%2FDX-G-GB%5D%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cubc1c%5Cuc0dd%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%222025-11-17%2010%3A15%3A32%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cud574%5Cuc18c%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%222025-11-17%2010%3A45%3A18%22%7D%5D%7D%5D%7D%5D%7D%2C%20%7B%22type%22%3A%20%22divider%22%7D%2C%20%7B%22type%22%3A%20%22context%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc608%5Cuc2dc%203%3A%20%5Cud50c%5Cub7ab%5Cud3fc%20%5Cuc774%5Cubca4%5Cud2b8%20%28%5Cud574%5Cuc18c%29%2A%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22header%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22plain_text%22%2C%20%22text%22%3A%20%22%5Cu2705%20%5Cuc774%5Cubca4%5Cud2b8%20%5B%5Cud574%5Cuc18c%5D%20%5BCritical%5D%20%5BK8S2001%5D%20Pod%20CrashLoopBackOff%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cub300%5Cuc0c1%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BNEXT-K8S%2FDX-G-GB%5D%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cubc1c%5Cuc0dd%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%222025-11-17%2011%3A23%3A45%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cud574%5Cuc18c%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%222025-11-17%2012%3A05%3A33%22%7D%5D%7D%5D%7D%5D%7D%5D%7D) |
| 미등록이벤트 | 발생 | - | - | - | ⚠️ 미등록이벤트 [발생] [등급] [이벤트코드] 이벤트명<br>• 대상: [L3/L4]<br>• 발생: YYYY-MM-DD HH:mm:ss<br>• 해소: -<br>※ 서비스/플랫폼 관리에서 등록 필요 | [TO-BE](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cu26a0%5Cufe0f%20%5Cubbf8%5Cub4f1%5Cub85d%5Cuc774%5Cubca4%5Cud2b8%20%5B%5Cubc1c%5Cuc0dd%5D%20%5BCritical%5D%20%5BK8S2001%5D%20Pod%20CrashLoopBackOff%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cub300%5Cuc0c1%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BNEXT-K8S%2FDX-G-SE%5D%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cubc1c%5Cuc0dd%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%222026-02-04%2014%3A30%3A00%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cud574%5Cuc18c%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22-%22%7D%5D%7D%5D%7D%5D%7D%2C%20%7B%22type%22%3A%20%22context%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%5Cu203b%20%5Cuc11c%5Cube44%5Cuc2a4%2F%5Cud50c%5Cub7ab%5Cud3fc%20%5Cuad00%5Cub9ac%5Cuc5d0%5Cuc11c%20%5Cub4f1%5Cub85d%20%5Cud544%5Cuc694%22%7D%5D%7D%5D%7D) |
| 미등록이벤트 | 해소 | - | - | - | ✅ 미등록이벤트 [해소] [등급] [이벤트코드] 이벤트명<br>• 대상: [L3/L4]<br>• 발생: YYYY-MM-DD HH:mm:ss<br>• 해소: YYYY-MM-DD HH:mm:ss<br>※ 서비스/플랫폼 관리에서 등록 필요 | [TO-BE](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cu2705%20%5Cubbf8%5Cub4f1%5Cub85d%5Cuc774%5Cubca4%5Cud2b8%20%5B%5Cud574%5Cuc18c%5D%20%5BCritical%5D%20%5BK8S2001%5D%20Pod%20CrashLoopBackOff%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cub300%5Cuc0c1%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BNEXT-K8S%2FDX-G-SE%5D%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cubc1c%5Cuc0dd%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%222026-02-04%2014%3A30%3A00%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5Cud574%5Cuc18c%3A%20%22%2C%20%22style%22%3A%20%7B%22bold%22%3A%20true%7D%7D%2C%20%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%222026-02-04%2015%3A05%3A33%22%7D%5D%7D%5D%7D%5D%7D%2C%20%7B%22type%22%3A%20%22context%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%5Cu203b%20%5Cuc11c%5Cube44%5Cuc2a4%2F%5Cud50c%5Cub7ab%5Cud3fc%20%5Cuad00%5Cub9ac%5Cuc5d0%5Cuc11c%20%5Cub4f1%5Cub85d%20%5Cud544%5Cuc694%22%7D%5D%7D%5D%7D) |
| 메인터넌스 | 등록 | ⚠️ `[등록][T25081900004]Zabbix 크로스 관제 이관 작업` | [Email](./email-previews/maintenance-email.html) | 수정과 동일 (상태만 변경) | 🔧 메인터넌스 [등록] [ID] 메인터넌스명<br>• 기간/등록<br>• 호스트: [L3/L4] 호스트명 (IP)<br>• 이벤트: 이벤트명 | [TO-BE](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22header%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22plain_text%22%2C%20%22text%22%3A%20%22%F0%9F%94%A7%20%EB%A9%94%EC%9D%B8%ED%84%B0%EB%84%8C%EC%8A%A4%20%5B%EC%88%98%EC%A0%95%5D%20%5BT25081900004%5D%20Zabbix%20%ED%81%AC%EB%A1%9C%EC%8A%A4%20%EA%B4%80%EC%A0%9C%20%EC%9D%B4%EA%B4%80%20%EC%9E%91%EC%97%85%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%E2%80%A2%20%2A%EA%B8%B0%EA%B0%84%3A%2A%202025-08-19%2018%3A00%20~%202026-08-19%2017%3A59%5Cn%E2%80%A2%20%2A%EB%93%B1%EB%A1%9D%3A%2A%20%EC%9C%A0%ED%94%BC%ED%85%8C%EB%A5%B4_%EA%B3%B5%EC%9A%A9%EA%B3%84%EC%A0%95%20%28Cloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C%ED%8C%80%29%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%ED%98%B8%EC%8A%A4%ED%8A%B8%3A%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BCloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C/ECLS-M1-COREMGMT%5D%20m1-jpt-prd-zab-d01%20%2810.2.14.141%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BCloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C/ECLS-M1-COREMGMT%5D%20m1-jpt-prd-zab-d02%20%2810.2.14.142%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BCloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C/ECLS-M1-COREMGMT%5D%20m1-jpt-prd-zab-d01_d02_VIP%20%2810.2.14.141%29%22%7D%5D%7D%5D%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%EC%9D%B4%EB%B2%A4%ED%8A%B8%3A%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BDB1213%5D%20Session%20Connect%20Warning%20%2896.62%25%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BDB1211%5D%20Session%20Connect%20%EC%A6%9D%EA%B0%80%20%2896.62%25%29%22%7D%5D%7D%5D%7D%5D%7D%5D%7D) |
| 메인터넌스 | 수정 | ⚠️ `[수정][T25081900004]Zabbix 크로스 관제 이관 작업` | [Email](./email-previews/maintenance-email.html) | 🔧 [수정] Luppiter 메인터넌스 알림 T25081900004<br>━━━━━━━━━━━━━━━━━━━━━━━━━━<br>메인터넌스 상태: 활성 /메인터넌스 명: Zabbix 크로스 관제 이관 작업<br>메인터넌스 시작시간: 2025-08-19 18:00<br>메인터넌스 종료시간: 2026-08-19 17:59<br>메인터넌스 사유: [CRM25081442137] Zabbix 크로스 관제 이관 작업<br>등록자: 유피테르_공용계정(Cloud통합관제팀)<br>등록시간: 2025-08-19 17:19<br>수정자: 유피테르_공용계정(Cloud통합관제팀)<br>수정시간: 2025-12-22 16:10<br>━━━━━━━━━━━━━━━━━━━━━━━━━━<br>**[호스트 정보]**<br>표준서비스(L3): Cloud통합관제 /Zone(L4): ECLS-M1-COREMGMT<br>관제영역: VM_통합 /호스트그룹명: ETC_Cloud통합관제_ECLS-M1-COREMGMT_VM_통합<br>운영부서: InfraOps개발팀 /1선담당자: 윤동희<br>2선담당자: 이창렬 /관제부서: Cloud통합관제팀<br>━━━━━━━━━━━━━━━━━━━━━━━━━━<br>**[이벤트 정보] - m1-jpt-prd-zab-d01_d02_VIP (10.2.14.141)**<br>발생시간: 2025-11-12 14:16:28 /관제영역: VM_DB<br>이벤트명: [DB1213] Session Connect Warning (96.62%)<br>이벤트명: [DB1211] Session Connect 증가 (96.62%) | 🔧 메인터넌스 [상태] [ID] 제목<br>• 기간/등록<br>• 호스트: [L3/L4] 호스트명 (IP)<br>• 이벤트: 이벤트명 | [AS-IS](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%3Awrench%3A%20%2A%5B%5Cuc218%5Cuc815%5D%20Luppiter%20%5Cuba54%5Cuc778%5Cud130%5Cub10c%5Cuc2a4%20%5Cuc54c%5Cub9bc%20T25081900004%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22divider%22%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuba54%5Cuc778%5Cud130%5Cub10c%5Cuc2a4%20%5Cuc0c1%5Cud0dc%2A%5Cn%5Cud65c%5Cuc131%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuba54%5Cuc778%5Cud130%5Cub10c%5Cuc2a4%20%5Cuba85%2A%5CnZabbix%20%5Cud06c%5Cub85c%5Cuc2a4%20%5Cuad00%5Cuc81c%20%5Cuc774%5Cuad00%20%5Cuc791%5Cuc5c5%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuba54%5Cuc778%5Cud130%5Cub10c%5Cuc2a4%20%5Cuc2dc%5Cuc791%5Cuc2dc%5Cuac04%2A%5Cn2025-08-19%2018%3A00%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuba54%5Cuc778%5Cud130%5Cub10c%5Cuc2a4%20%5Cuc885%5Cub8cc%5Cuc2dc%5Cuac04%2A%5Cn2026-08-19%2017%3A59%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuba54%5Cuc778%5Cud130%5Cub10c%5Cuc2a4%20%5Cuc0ac%5Cuc720%2A%5Cn%5BCRM25081442137%5D%20Zabbix%20%5Cud06c%5Cub85c%5Cuc2a4%20%5Cuad00%5Cuc81c%20%5Cuc774%5Cuad00%20%5Cuc791%5Cuc5c5%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cub4f1%5Cub85d%5Cuc790%2A%5Cn%5Cuc720%5Cud53c%5Cud14c%5Cub974_%5Cuacf5%5Cuc6a9%5Cuacc4%5Cuc815%28Cloud%5Cud1b5%5Cud569%5Cuad00%5Cuc81c%5Cud300%29%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cub4f1%5Cub85d%5Cuc2dc%5Cuac04%2A%5Cn2025-08-19%2017%3A19%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc218%5Cuc815%5Cuc790%2A%5Cn%5Cuc720%5Cud53c%5Cud14c%5Cub974_%5Cuacf5%5Cuc6a9%5Cuacc4%5Cuc815%28Cloud%5Cud1b5%5Cud569%5Cuad00%5Cuc81c%5Cud300%29%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc218%5Cuc815%5Cuc2dc%5Cuac04%2A%5Cn2025-12-22%2016%3A10%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22divider%22%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5B%5Cud638%5Cuc2a4%5Cud2b8%20%5Cuc815%5Cubcf4%5D%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cud45c%5Cuc900%5Cuc11c%5Cube44%5Cuc2a4%28L3%29%2A%5CnCloud%5Cud1b5%5Cud569%5Cuad00%5Cuc81c%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2AZone%28L4%29%2A%5CnECLS-M1-COREMGMT%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuad00%5Cuc81c%5Cuc601%5Cuc5ed%2A%5CnVM_%5Cud1b5%5Cud569%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cud638%5Cuc2a4%5Cud2b8%5Cuadf8%5Cub8f9%5Cuba85%2A%5CnETC_Cloud%5Cud1b5%5Cud569%5Cuad00%5Cuc81c_ECLS-M1-COREMGMT_VM_%5Cud1b5%5Cud569%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc6b4%5Cuc601%5Cubd80%5Cuc11c%2A%5CnInfraOps%5Cuac1c%5Cubc1c%5Cud300%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A1%5Cuc120%5Cub2f4%5Cub2f9%5Cuc790%2A%5Cn%5Cuc724%5Cub3d9%5Cud76c%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A2%5Cuc120%5Cub2f4%5Cub2f9%5Cuc790%2A%5Cn%5Cuc774%5Cucc3d%5Cub82c%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuad00%5Cuc81c%5Cubd80%5Cuc11c%2A%5CnCloud%5Cud1b5%5Cud569%5Cuad00%5Cuc81c%5Cud300%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22divider%22%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5B%5Cuc774%5Cubca4%5Cud2b8%20%5Cuc815%5Cubcf4%5D%20-%20m1-jpt-prd-zab-d01_d02_VIP%20%2810.2.14.141%29%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cubc1c%5Cuc0dd%5Cuc2dc%5Cuac04%2A%5Cn2025-11-12%2014%3A16%3A28%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuad00%5Cuc81c%5Cuc601%5Cuc5ed%2A%5CnVM_DB%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc774%5Cubca4%5Cud2b8%5Cuba85%2A%5Cn%5BDB1213%5D%20%5BSession%20%3A%20Connect%20Warning%20Check%28%5Cud604%5Cuc7ac%20%5Cuac12%20%3A%2096.62%29%5D%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc774%5Cubca4%5Cud2b8%5Cuba85%2A%5Cn%5BDB1211%5D%20%5BSession%20%3A%20Connect%20%5Cuc99d%5Cuac00%20Check%28%5Cud604%5Cuc7ac%20%5Cuac12%20%3A%2096.62%29%5D%22%7D%7D%5D%7D) [TO-BE](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22header%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22plain_text%22%2C%20%22text%22%3A%20%22%F0%9F%94%A7%20%EB%A9%94%EC%9D%B8%ED%84%B0%EB%84%8C%EC%8A%A4%20%5B%EC%88%98%EC%A0%95%5D%20%5BT25081900004%5D%20Zabbix%20%ED%81%AC%EB%A1%9C%EC%8A%A4%20%EA%B4%80%EC%A0%9C%20%EC%9D%B4%EA%B4%80%20%EC%9E%91%EC%97%85%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%E2%80%A2%20%2A%EA%B8%B0%EA%B0%84%3A%2A%202025-08-19%2018%3A00%20~%202026-08-19%2017%3A59%5Cn%E2%80%A2%20%2A%EB%93%B1%EB%A1%9D%3A%2A%20%EC%9C%A0%ED%94%BC%ED%85%8C%EB%A5%B4_%EA%B3%B5%EC%9A%A9%EA%B3%84%EC%A0%95%20%28Cloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C%ED%8C%80%29%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%ED%98%B8%EC%8A%A4%ED%8A%B8%3A%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BCloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C/ECLS-M1-COREMGMT%5D%20m1-jpt-prd-zab-d01%20%2810.2.14.141%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BCloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C/ECLS-M1-COREMGMT%5D%20m1-jpt-prd-zab-d02%20%2810.2.14.142%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BCloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C/ECLS-M1-COREMGMT%5D%20m1-jpt-prd-zab-d01_d02_VIP%20%2810.2.14.141%29%22%7D%5D%7D%5D%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%EC%9D%B4%EB%B2%A4%ED%8A%B8%3A%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BDB1213%5D%20Session%20Connect%20Warning%20%2896.62%25%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22%5BDB1211%5D%20Session%20Connect%20%EC%A6%9D%EA%B0%80%20%2896.62%25%29%22%7D%5D%7D%5D%7D%5D%7D%5D%7D) |
| 메인터넌스 | 기타 | ⚠️ `[상태][ID]제목` | [Email](./email-previews/maintenance-email.html) | 활성과 동일 (상태만 변경: 대기중/종료3일전/종료1시간전/종료/수정/시간연장/실패/삭제/부분종료) | 상동 | 상동 |
| 이벤트예외 | 예외등록 | - | [Email](./email-previews/exception-email.html) | - | ⏸️ 이벤트예외 [상태] [ID] 예외명<br>*[이벤트 예외][이벤트코드] 예외명*<br>• 기간/등록<br>• 대상: 호스트명 (IP) | [TO-BE](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22header%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22plain_text%22%2C%20%22text%22%3A%20%22%E2%8F%B8%EF%B8%8F%20%EC%9D%B4%EB%B2%A4%ED%8A%B8%EC%98%88%EC%99%B8%20%5B%EC%98%88%EC%99%B8%EB%93%B1%EB%A1%9D%5D%20%5BEXC-728%5D%20XenServer%20host%20down%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5B%EC%9D%B4%EB%B2%A4%ED%8A%B8%20%EC%98%88%EC%99%B8%5D%5BXS1001%5D%20XenServer%20host%20down%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22divider%22%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%E2%80%A2%20%2A%EA%B8%B0%EA%B0%84%3A%2A%202025-01-12%2000%3A00%20~%202025-02-10%2023%3A59%5Cn%E2%80%A2%20%2A%EB%93%B1%EB%A1%9D%3A%2A%20%ED%99%8D%EA%B8%B8%EB%8F%99%20%28Cloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C%ED%8C%80%29%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%EB%8C%80%EC%83%81%3A%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22host-01%20%2810.1.2.3%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22host-02%20%2810.1.2.4%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22host-03%20%2810.1.2.5%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22host-04%20%2810.1.2.6%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22host-05%20%2810.1.2.7%29%22%7D%5D%7D%5D%7D%5D%7D%5D%7D) |
| 이벤트예외 | 기타 | - | [Email](./email-previews/exception-email.html) | - | 상동 (상태: 시작/종료3일전/종료1일전/종료) | 상동 |
| 관제수용 | 임시수용 | - | - | 🔔 [HMM2512100001] 관제수용 요청건 상태 알림<br>━━━━━━━━━━━━━━━━━━━━━━━━━━<br>신청서 ID: HMM2512100001 /신청 상태: 임시수용<br>제목: [관제 수용][CRM25121079391] 수용_IPC_7대_최원동<br>신청부서: Cloud통합관제팀 /신청자: 유피테르_공용계정<br>호스트정보:<br>[10.4.230.22] ivdi-pc50616u30-snd02<br>... | 📋 관제수용 [상태] [ID] 제목<br>• 시간/등록<br>• (이벤트)<br>• 대상: 호스트명 (IP) | [AS-IS](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%3Abell%3A%20%2A%5BHMM2512100001%5D%20%5Cuad00%5Cuc81c%5Cuc218%5Cuc6a9%20%5Cuc694%5Cuccad%5Cuac74%20%5Cuc0c1%5Cud0dc%20%5Cuc54c%5Cub9bc%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22divider%22%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc2e0%5Cuccad%5Cuc11c%20ID%2A%5CnHMM2512100001%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc2e0%5Cuccad%20%5Cuc0c1%5Cud0dc%2A%5Cn%5Cuc784%5Cuc2dc%5Cuc218%5Cuc6a9%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc81c%5Cubaa9%2A%5Cn%5B%5Cuad00%5Cuc81c%20%5Cuc218%5Cuc6a9%5D%5BCRM25121079391%5D%20%5Cuc218%5Cuc6a9_IPC_7%5Cub300_%5Cucd5c%5Cuc6d0%5Cub3d9%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22fields%22%3A%20%5B%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc2e0%5Cuccad%5Cubd80%5Cuc11c%2A%5CnCloud%5Cud1b5%5Cud569%5Cuad00%5Cuc81c%5Cud300%22%7D%2C%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cuc2e0%5Cuccad%5Cuc790%2A%5Cn%5Cuc720%5Cud53c%5Cud14c%5Cub974_%5Cuacf5%5Cuc6a9%5Cuacc4%5Cuc815%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5Cud638%5Cuc2a4%5Cud2b8%5Cuc815%5Cubcf4%2A%5Cn%5B10.4.230.22%5D%20ivdi-pc50616u30-snd02%5Cn%5B10.4.230.23%5D%20ivdi-pc50617u30-snd03%5Cn%5B10.4.230.24%5D%20ivdi-pc50711u30-snd04%5Cn%5B10.4.229.202%5D%20snode02-5s0911-c3-isovdi%5Cn%5B10.4.229.203%5D%20snode03-5s0911-c5-isovdi%5Cn%5B10.4.229.204%5D%20snode04-5s1303-c1-isovdi%5Cn%5B10.4.229.205%5D%20snode05-5s1303-c3-isovdi%22%7D%7D%5D%7D) [TO-BE](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22header%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22plain_text%22%2C%20%22text%22%3A%20%22%F0%9F%93%8B%20%EA%B4%80%EC%A0%9C%EC%88%98%EC%9A%A9%20%5B%EC%9E%84%EC%8B%9C%EC%88%98%EC%9A%A9%5D%20%5BHMM2512100001%5D%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5B%EA%B4%80%EC%A0%9C%20%EC%88%98%EC%9A%A9%5D%5BCRM25121079391%5D%20%EC%88%98%EC%9A%A9_IPC_7%EB%8C%80_%EC%B5%9C%EC%9B%90%EB%8F%99%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22divider%22%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%E2%80%A2%20%2A%EC%8B%9C%EA%B0%84%3A%2A%202025-12-10%2014%3A30%3A00%5Cn%E2%80%A2%20%2A%EB%93%B1%EB%A1%9D%3A%2A%20%EC%9C%A0%ED%94%BC%ED%85%8C%EB%A5%B4_%EA%B3%B5%EC%9A%A9%EA%B3%84%EC%A0%95%20%28Cloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C%ED%8C%80%29%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%EB%8C%80%EC%83%81%3A%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22ivdi-pc50616u30-snd02%20%2810.4.230.22%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22ivdi-pc50617u30-snd03%20%2810.4.230.23%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22ivdi-pc50711u30-snd04%20%2810.4.230.24%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22snode02-5s0911-c3-isovdi%20%2810.4.229.202%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22snode03-5s0911-c5-isovdi%20%2810.4.229.203%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22snode04-5s1303-c1-isovdi%20%2810.4.229.204%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22snode05-5s1303-c3-isovdi%20%2810.4.229.205%29%22%7D%5D%7D%5D%7D%5D%7D%5D%7D) |
| 관제수용 | 기타 | - | - | 임시수용과 동일 (상태만 변경: 매핑완료/임시수용/수용완료) | 상동 | 상동 |
| 관제삭제 | 삭제 | - | - | 관제수용과 동일 | 🗑️ 관제삭제 [상태] [ID] 제목<br>• 시간/등록<br>• 대상: 호스트명 (IP) | [TO-BE](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22header%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22plain_text%22%2C%20%22text%22%3A%20%22%F0%9F%97%91%EF%B8%8F%20%EA%B4%80%EC%A0%9C%EC%82%AD%EC%A0%9C%20%5B%EC%82%AD%EC%A0%9C%EC%99%84%EB%A3%8C%5D%20%5BDEL2512150001%5D%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%5B%EA%B4%80%EC%A0%9C%20%EC%82%AD%EC%A0%9C%5D%5BCRM25121512345%5D%20%EC%82%AD%EC%A0%9C_IPC_3%EB%8C%80_%ED%99%8D%EA%B8%B8%EB%8F%99%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22divider%22%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%E2%80%A2%20%2A%EC%8B%9C%EA%B0%84%3A%2A%202025-12-15%2010%3A00%3A00%5Cn%E2%80%A2%20%2A%EB%93%B1%EB%A1%9D%3A%2A%20%ED%99%8D%EA%B8%B8%EB%8F%99%20%28Cloud%ED%86%B5%ED%95%A9%EA%B4%80%EC%A0%9C%ED%8C%80%29%22%7D%7D%2C%20%7B%22type%22%3A%20%22section%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22mrkdwn%22%2C%20%22text%22%3A%20%22%2A%EB%8C%80%EC%83%81%3A%2A%22%7D%7D%2C%20%7B%22type%22%3A%20%22rich_text%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_list%22%2C%20%22style%22%3A%20%22bullet%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22server-01%20%2810.1.1.1%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22server-02%20%2810.1.1.2%29%22%7D%5D%7D%2C%20%7B%22type%22%3A%20%22rich_text_section%22%2C%20%22elements%22%3A%20%5B%7B%22type%22%3A%20%22text%22%2C%20%22text%22%3A%20%22server-03%20%2810.1.1.3%29%22%7D%5D%7D%5D%7D%5D%7D%5D%7D) |
| OTP인증 | 인증요청 | `[LUPPITER_ADMIN] OTP 인증번호 : 482957` | `[LUPPITER_ADMIN] 인증번호 [482957]` | - | 🔐 OTP인증 인증번호: 482957 | [TO-BE](https://app.slack.com/block-kit-builder#%7B%22blocks%22%3A%20%5B%7B%22type%22%3A%20%22header%22%2C%20%22text%22%3A%20%7B%22type%22%3A%20%22plain_text%22%2C%20%22text%22%3A%20%22%5Cud83d%5Cudd10%20OTP%5Cuc778%5Cuc99d%20%5Cuc778%5Cuc99d%5Cubc88%5Cud638%3A%20482957%22%7D%7D%5D%7D) |

> **⚠️ 발송 현황**
> - **SMS ⚠️**: 협력업체만 발송 (user_id가 "8"로 시작 안하면 SMS, 자사직원은 Slack)
> - **Slack (AS-IS)**: 이벤트/메인터넌스/관제수용만 발송, 이벤트예외/OTP는 미발송
> - **관제수용**: 운영에서 SMS/Email 미사용 (Slack DM만 사용)

### 1.2 메시지 포맷 구조

| 기능 | 헤더 포맷 | 본문 필드                                                                                        |
|------|----------|----------------------------------------------------------------------------------------------|
| 이벤트 | `기능명 [상태] [등급] [이벤트코드] 이벤트명` | 인프라: 대상([L3/L4] 호스트명 (설비바코드)), 발생, 해소, IP(수집/MGMT/IPMI)<br>서비스/플랫폼: 대상([L3/L4] 서비스명), 발생, 해소 |
| 미등록이벤트 | `기능명 [상태] [등급] 이벤트명` | 대상, 시간, 위치, 안내문                                                                              |
| 메인터넌스 | `기능명 [상태] [ID] 메인터넌스명` | 기간, 등록, 호스트([L3/L4] 호스트명 (IP)), 이벤트                                                          |
| 이벤트예외 | `기능명 [상태] [ID] 예외명` | 기간, 등록, 대상목록                                                                                 |
| 관제수용 | `기능명 [상태] [ID] 요청명` | 시간, 등록, (이벤트), 대상목록                                                                          |
| 관제삭제 | `기능명 [상태] [ID] 요청명` | 시간, 등록, 대상목록                                                                                 |
| OTP인증 | `기능명 인증번호: {6자리}` | -                                                                                            |

---

## 2. 아이콘 정리

| 구분 | 아이콘 |
|------|--------|
| 이벤트 발생 | 🚨 |
| 이벤트 해소 | ✅ |
| 미등록이벤트 | ⚠️ |
| 메인터넌스 | 🔧 |
| 이벤트예외 | ⏸️ |
| 관제수용 | 📋 |
| 관제삭제 | 🗑️ |
| OTP인증 | 🔐 |

---

## 3. 협의 필요 사항

- [ ] TO-BE 메시지 포맷 확정
- [ ] 필드 표시 범위 협의 (상세 vs 요약)
- [ ] 채널 발송 시 멘션 여부 (@channel, @here)
- [ ] Email/SMS Decomm 일정 (Slack 채널 완료 후)

---

## 4. 코드 구현 (Slack Block Kit)

### 4.1 이벤트 알림

**변수:**
- `icon`: 🚨 (발생) / ✅ (해소)
- `status`: 신규/해소
- `grade`: Fatal/Critical/Warning 등
- `eventCode`: HW6213, SVC1001 등
- `eventName`: 이벤트명
- `l3Name`: 표준서비스명 (L3)
- `l4Name`: Zone명 (L4)
- `hostName`: 호스트명
- `barcode`: 설비바코드 (인프라만)
- `occurTime`: 발생시간
- `clearTime`: 해소시간 (없으면 "-")
- `collectIp`, `mgmtIp`, `ipmiIp`: IP 정보 (인프라만)

```json
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "${icon} 이벤트 [${status}] [${grade}] [${eventCode}] ${eventName}"
      }
    },
    {
      "type": "rich_text",
      "elements": [
        {
          "type": "rich_text_list",
          "style": "bullet",
          "elements": [
            {
              "type": "rich_text_section",
              "elements": [
                { "type": "text", "text": "대상: ", "style": { "bold": true } },
                { "type": "text", "text": "[${l3Name}/${l4Name}] ${hostName} (${barcode})" }
              ]
            },
            {
              "type": "rich_text_section",
              "elements": [
                { "type": "text", "text": "발생: ", "style": { "bold": true } },
                { "type": "text", "text": "${occurTime}" }
              ]
            },
            {
              "type": "rich_text_section",
              "elements": [
                { "type": "text", "text": "해소: ", "style": { "bold": true } },
                { "type": "text", "text": "${clearTime}" }
              ]
            },
            {
              "type": "rich_text_section",
              "elements": [
                { "type": "text", "text": "IP (수집, MGMT, IPMI): ", "style": { "bold": true } },
                { "type": "text", "text": "${collectIp}, ${mgmtIp}, ${ipmiIp}" }
              ]
            }
          ]
        }
      ]
    }
  ]
}
```

### 4.2 미등록이벤트 알림

**변수:**
- `icon`: ⚠️ (발생) / ✅ (해소)
- `status`: 발생/해소
- `grade`, `eventCode`, `eventName`
- `l3Name`, `l4Name`
- `occurTime`, `clearTime`

```json
{
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*${icon} 미등록이벤트 [${status}] [${grade}] [${eventCode}] ${eventName}*"
      }
    },
    {
      "type": "rich_text",
      "elements": [
        {
          "type": "rich_text_list",
          "style": "bullet",
          "elements": [
            {
              "type": "rich_text_section",
              "elements": [
                { "type": "text", "text": "대상: ", "style": { "bold": true } },
                { "type": "text", "text": "[${l3Name}/${l4Name}]" }
              ]
            },
            {
              "type": "rich_text_section",
              "elements": [
                { "type": "text", "text": "발생: ", "style": { "bold": true } },
                { "type": "text", "text": "${occurTime}" }
              ]
            },
            {
              "type": "rich_text_section",
              "elements": [
                { "type": "text", "text": "해소: ", "style": { "bold": true } },
                { "type": "text", "text": "${clearTime}" }
              ]
            }
          ]
        }
      ]
    },
    {
      "type": "context",
      "elements": [{ "type": "mrkdwn", "text": "※ 서비스/플랫폼 관리에서 등록 필요" }]
    }
  ]
}
```

### 4.3 메인터넌스 알림

**변수:**
- `status`: 등록/수정/활성/대기중/종료3일전/종료1시간전/종료/시간연장/실패/삭제/부분종료
- `maintenanceId`: T25081900004
- `maintenanceName`: 메인터넌스명
- `startTime`, `endTime`: 기간
- `reason`: 사유
- `registrant`: 등록자 (부서)
- `hostList`: 호스트 목록 [{l3Name, l4Name, hostName, ip}]
- `eventList`: 이벤트 목록 [{eventCode, eventName}]

```json
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "🔧 메인터넌스 [${status}] [${maintenanceId}] ${maintenanceName}"
      }
    },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "• *기간:* \${startTime} ~ \${endTime}\\n• *등록:* \${registrant}"
      }
    },
    {
      "type": "section",
      "text": { "type": "mrkdwn", "text": "*호스트:*" }
    },
    {
      "type": "rich_text",
      "elements": [
        {
          "type": "rich_text_list",
          "style": "bullet",
          "elements": "${hostList.map(h => richTextSection('[' + h.l3Name + '/' + h.l4Name + '] ' + h.hostName + ' (' + h.ip + ')'))}"
        }
      ]
    },
    {
      "type": "section",
      "text": { "type": "mrkdwn", "text": "*이벤트:*" }
    },
    {
      "type": "rich_text",
      "elements": [
        {
          "type": "rich_text_list",
          "style": "bullet",
          "elements": "${eventList.map(e => richTextSection('[' + e.eventCode + '] ' + e.eventName))}"
        }
      ]
    }
  ]
}
```

### 4.4 이벤트예외 알림

**변수:**
- `exceptionId`: EXC-728
- `status`: 예외등록/시작/종료3일전/종료1일전/종료
- `exceptionName`: 예외명
- `startDate`, `endDate`: 기간
- `reason`: 사유
- `registrant`: 등록자
- `targetList`: 대상 목록 [{hostName, ip}]

```json
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "⏸️ 이벤트예외 [\${status}] [\${exceptionId}] ${exceptionName}"
      }
    },
    { "type": "divider" },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "• *기간:* \${startDate} ~ \${endDate}\\n• *등록:* \${registrant}"
      }
    },
    {
      "type": "section",
      "text": { "type": "mrkdwn", "text": "*대상:*" }
    },
    {
      "type": "rich_text",
      "elements": [
        {
          "type": "rich_text_list",
          "style": "bullet",
          "elements": "${targetList.map(t => richTextSection(t.hostName + ' (' + t.ip + ')'))}"
        }
      ]
    }
  ]
}
```

### 4.5 관제수용 알림

**변수:**
- `acceptanceId`: HMM2512100001
- `status`: 임시수용/매핑완료/수용완료
- `title`: 제목
- `requestTime`: 요청시간
- `reason`: 사유
- `registrant`: 등록자 (부서)
- `eventList`: 이벤트 목록 (선택)
- `targetList`: 대상 목록 [{hostName, ip}]

```json
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "📋 관제수용 [\${status}] [\${acceptanceId}]"
      }
    },
    {
      "type": "section",
      "text": { "type": "mrkdwn", "text": "*${title}*" }
    },
    { "type": "divider" },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "• *시간:* \${requestTime}\\n• *등록:* \${registrant}"
      }
    },
    {
      "type": "section",
      "text": { "type": "mrkdwn", "text": "*대상:*" }
    },
    {
      "type": "rich_text",
      "elements": [
        {
          "type": "rich_text_list",
          "style": "bullet",
          "elements": "${targetList.map(t => richTextSection(t.hostName + ' (' + t.ip + ')'))}"
        }
      ]
    }
  ]
}
```

### 4.6 관제삭제 알림

**변수:**
- `deletionId`: DEL2512150001
- `status`: 삭제완료
- `title`: 제목
- `deleteTime`: 삭제시간
- `reason`: 사유
- `registrant`: 등록자 (부서)
- `targetList`: 대상 목록 [{hostName, ip}]

```json
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "🗑️ 관제삭제 [\${status}] [\${deletionId}]"
      }
    },
    {
      "type": "section",
      "text": { "type": "mrkdwn", "text": "*${title}*" }
    },
    { "type": "divider" },
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "• *시간:* \${deleteTime}\\n• *등록:* \${registrant}"
      }
    },
    {
      "type": "section",
      "text": { "type": "mrkdwn", "text": "*대상:*" }
    },
    {
      "type": "rich_text",
      "elements": [
        {
          "type": "rich_text_list",
          "style": "bullet",
          "elements": "${targetList.map(t => richTextSection(t.hostName + ' (' + t.ip + ')'))}"
        }
      ]
    }
  ]
}
```

### 4.7 OTP 인증 알림

**변수:**
- `otpCode`: 6자리 인증번호

```json
{
  "blocks": [
    {
      "type": "header",
      "text": {
        "type": "plain_text",
        "text": "🔐 OTP인증 인증번호: ${otpCode}"
      }
    }
  ]
}
```

### 4.8 공통 헬퍼 함수

```java
/**
 * rich_text_section 블록 생성
 */
private Map<String, Object> richTextSection(String text) {
    return Map.of(
        "type", "rich_text_section",
        "elements", List.of(Map.of("type", "text", "text", text))
    );
}

/**
 * rich_text_section 블록 생성 (라벨 + 값)
 */
private Map<String, Object> richTextSection(String label, String value) {
    return Map.of(
        "type", "rich_text_section",
        "elements", List.of(
            Map.of("type", "text", "text", label, "style", Map.of("bold", true)),
            Map.of("type", "text", "text", value)
        )
    );
}

/**
 * rich_text_list 블록 생성
 */
private Map<String, Object> richTextList(List<String> items) {
    return Map.of(
        "type", "rich_text",
        "elements", List.of(Map.of(
            "type", "rich_text_list",
            "style", "bullet",
            "elements", items.stream()
                .map(this::richTextSection)
                .toList()
        ))
    );
}
```

---

**최종 업데이트**: 2026-02-05
