# Canonical Cloud/Hypervisor Data Model

## 📚 주요 문서

### 1. canonical-model-reference.md ⭐ (메인)
Canonical 모델의 전체 구조 및 ERD 정의
- Instance 통합 개념
- Network / Storage / Security 아키텍처
- CloudStack / OpenStack / Plan-B 매핑
- **AI/프롬프트 컨텍스트로 사용**

### 2. troubleshooting-guide.md 🔧 (실무)
자주 헷갈리는 포인트 & 착시 해소
- "왜 VM에 network_id가 없나?"
- "왜 VM에 storage_pool_id가 없나?"
- "VM 방화벽이 실제로 VR인 이유"
- **신규 개발자 필독**

### 3. excel-data-sheet-guide.md 📊 (작업)
엑셀 '데이터' 시트 해석 가이드
- 원천 시스템 (CS DB / SSH / COA DB) 구분
- SSH (Hypervisor) vs SSH (VR) 차이
- Plan-B 데이터 수집 방식
- **데이터 수집/정리 작업 시 참조**

---

## 🎯 사용 시나리오

| 상황 | 읽을 문서 |
|------|----------|
| AI에게 Canonical 모델 설명 | `canonical-model-reference.md` |
| ERD 설계/리뷰 | `canonical-model-reference.md` |
| "왜 이렇게 설계했지?" | `troubleshooting-guide.md` |
| Plan-B 환경 설계 | `canonical-model-reference.md` 섹션 8 |
| "Plan-B는 왜 다른가?" | `troubleshooting-guide.md` Plan-B FAQ |
| 엑셀 시트 작업 | `excel-data-sheet-guide.md` |
| 처음부터 학습 | `archive/` 폴더 01~05 순서대로 |

---

## 📐 전체 아키텍처 한눈에

```
Platform (공통)
   ├─→ CloudStack/OPS
   │     Zone → Pod → Cluster → Host → Instance (VM/VR/System)
   │           ├─→ Network (NIC → Network → PublicIP → Firewall)
   │           └─→ Storage (VolumeAttach → Volume → StoragePool)
   │
   └─→ Plan-B (No Stack)
         Pool(Master) → Host → VM → VBD → VDI → SR
         (Network/Security 없음, Hypervisor Direct)
```

---

## 📂 Archive

교육용 단계별 학습 자료는 `archive/` 폴더 참고
- 01: 설계 의도
- 02: 개체 계층
- 03: 엑셀 가이드 (현재는 메인 문서로 통합)
- 04: 전체 구조
- 05: 플랫폼 매핑

---

## 🔄 최근 업데이트 (2026-02-04)

- ✅ Plan-B 전용 계층 추가 (Pool/Host/VM/Storage)
- ✅ Plan-B vs CloudStack 비교표 추가
- ✅ 3개 파일로 문서 재구성 (Reference / Troubleshooting / Excel Guide)
- ✅ 엑셀 리스트_260204_1700 기준 Plan-B 카테고리 반영
