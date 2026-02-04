# 엑셀 '데이터' 시트 읽는 법 가이드

---

## 0. 이 문서의 목적

이 문서는 엑셀 시트 중 **"데이터" 시트**를
다른 사람(AI 포함)이 **오해 없이 이해하도록 설명**하기 위한 가이드다.

핵심 목표는 다음 3가지다.

1. 각 컬럼이 무엇을 의미하는지
2. "원천 시스템" 컬럼을 어떻게 해석해야 하는지
3. 이 엑셀이 **ERD가 아니라 데이터 인벤토리**라는 점을 명확히 하는 것

---

## 1. 엑셀 '데이터' 시트의 성격

이 엑셀은 다음이 아니다 ❌

- DB 스키마 정의서
- ERD
- API 명세서

이 엑셀은 다음이다 ✅

- **데이터 수집 인벤토리**
- "어디서, 어떤 방식으로, 어떤 데이터를 얻는가"의 목록
- Canonical 모델 설계를 위한 **사실(Fact) 정리표**

---

## 2. 엑셀 컬럼 전체 구조

엑셀의 기본 컬럼은 다음과 같다.

```
원천 시스템 | 카테고리 | 데이터 | 방식 | 동작 여부 | 외래키 카테고리 | 데이터 예시 | 비고
```

이 컬럼들은 **왼쪽에서 오른쪽으로 읽는다**.

---

## 3. 컬럼별 상세 설명

---

### 3.1 원천 시스템 (Source System)

#### 가장 중요한 컬럼

이 컬럼의 기준은 **"어디에 접속해서 얻었는가"** 이다.

```
CS DB
SSH (Hypervisor)
SSH (VR)
COA DB
IPC Portal
DCIM
```

#### 의미 정리

```
CS DB
→ CloudStack가 이미 정의/관리하고 있는 메타데이터
→ 정책, 관계, 설정 중심

SSH (Hypervisor)
→ 하이퍼바이저 OS에 SSH 접속해서 얻은 데이터
→ Host / VM / Storage / Network 사실(Fact)

SSH (VR)
→ Host에 SSH → VR로 재접속해서 얻은 데이터
→ 실제 네트워크/방화벽 동작 검증

COA DB
→ Canonical DB
→ 수동 입력 또는 계산/집계 데이터

DCIM
→ 외부 시스템으로 실제 HW의 상면 위치 정보를 가진 시스템

Portal
→ 외부 시스템으로 고객 정보를 가진 시스템
```

⚠️ **같은 SSH라도 계층이 다르면 반드시 구분**
- SSH (Hypervisor) ≠ SSH (VR)

---

### 3.2 카테고리 (Category)

#### "이 데이터가 어느 개체(Entity)에 속하는가"

예:
```
Instance
Network
NIC
PublicIP
FirewallRule
Volume
VolumeAttach
StoragePool
VirtualRouter
리소스 통계용: 용량
리소스 통계용: Count
[PlanB/MGMT] VM
[PlanB/MGMT] Pool(Master)
[PlanB/MGMT] Host(C-Node)
[PlanB/MGMT] StoragePool(SR)
[PlanB/MGMT] Volume(VDI)
[PlanB/MGMT] VolumeAttachment(VBD)
```

이 값은 **Canonical ERD의 Entity 이름과 1:1로 맞추는 게 목표**다.

---

### 3.3 데이터 (Data)

#### 실제 컬럼 또는 속성의 의미

- 사람이 읽는 이름
- 화면/운영 관점 용어

예:
```
VM 상태
Host IP
전체 용량(byte)
사용률
이중화 상태
```

---

### 3.4 방식 (Collection Method)

```
요청 시 (On-Demand)
배치
계산
```

의미:

```
요청 시
→ API 호출 / 화면 진입 시 조회

배치
→ cron / nightly job / 주기 수집

계산
→ DB에 직접 저장하지 않고
  다른 값으로 계산
```

---

### 3.5 동작 여부

```
O
동작
동작 안함
```

의미:

- 현재 실제로 수집되고 있는가?
- 설계상 존재하지만 아직 미구현인가?

👉 **설계 가능성은 O, 구현 상태는 "동작 여부"로 판단**

---

### 3.6 외래키 카테고리 (FK Category)

#### 이 데이터가 **어떤 개체를 참조하는지**

예:
```
Instance
Network
StoragePool
Host
Account
[PlanB/MGMT] Pool(Master)
[PlanB/MGMT] Host(C-Node)
```

중요 포인트:

- 여기서 FK는 **DB 컬럼을 의미하지 않을 수도 있음**
- "개념적으로 어디에 종속되는가"를 표현

---

### 3.7 데이터 예시

#### 실제 값의 형태를 보여주는 컬럼

예:
```
172.27.0.204
0.75
Running
ce497223-155f-002f-af24-4d92badb7daa
```

👉 타입 추정 / 정규화 설계에 매우 중요

---

### 3.8 비고

#### 설계자의 의도가 들어가는 컬럼

여기에 적히는 내용:
- Canonical 컬럼명
- 설계 판단 이유
- "이건 직접 참조하지 말자"
- "중간 테이블로 빼자"

예:
```
VM은 Network를 직접 참조하지 않음
VolumeAttach로 이동 권장
참조용 컬럼
```

---

## 4. SSH (Hypervisor) vs SSH (VR) 해석 가이드

---

### 4.1 SSH (Hypervisor)

#### 의미
"하이퍼바이저가 알고 있는 사실"

#### 흐름

```
[ Web / Batch ]
      |
      | SSH 접속
      v
[ Hypervisor Host ]
      |
      | xe / virsh / ovs 명령
      v
[ 결과 텍스트 ]
      |
      v
[ COA DB ]
```

#### 수집 데이터 성격
- Host 스펙
- VM 목록 / 상태
- Storage 용량
- Network 정의

❌ 실제 방화벽 동작은 모름

---

### 4.2 SSH (VR)

#### 의미
"정책이 실제로 동작하는지"

#### 흐름 (2-hop SSH)

```
[ Web / PHP ]
      |
      | 1) DB 조회
      v
[ CloudStack DB ]
      |
      | 2) SSH Host
      v
[ Hypervisor Host ]
      |
      | 3) SSH to VR (3922)
      v
[ Virtual Router ]
      |
      | ping / nmap / iptables
      v
[ 결과 ]
```

#### 수집 데이터 성격
- 포트 오픈 여부
- 방화벽 ACCEPT/DENY
- 실제 통신 가능 여부

---

## 5. Plan-B 데이터 수집 ⭐ **NEW**

### 5.1 Plan-B 원천 시스템

Plan-B는 CloudStack/OpenStack이 없는 환경입니다.
따라서 원천 시스템이 다릅니다.

```
COA DB (수동 입력)
→ Pool(Master) 정보
  - Master IP
  - Password (암호화)
  - Zone 명 (논리 분류)

SSH (Hypervisor)
→ xe 명령으로 직접 수집
  - Pool UUID
  - Host / VM / Storage
```

### 5.2 Plan-B 수집 흐름

```
1. COA DB에 Pool(Master) 수동 등록
   - Master IP, Password, Zone명

2. 배치 작업이 SSH 접속
   - ssh root@{Master IP}

3. xe 명령 실행
   - xe pool-list
   - xe host-list
   - xe vm-list
   - xe sr-list
   - xe vdi-list
   - xe vbd-list

4. 결과 파싱 후 COA DB 저장
   - [PlanB/MGMT] 테이블들
```

### 5.3 Plan-B vs CloudStack 원천 시스템 비교

| 항목 | CloudStack | Plan-B |
|------|-----------|--------|
| **Stack DB** | CS DB | ❌ 없음 |
| **Hypervisor SSH** | SSH (Hypervisor) | SSH (Hypervisor) |
| **VR SSH** | SSH (VR) | ❌ 없음 (VR 없음) |
| **수동 입력** | 거의 없음 | Pool(Master) 등록 |

### 5.4 Plan-B 카테고리 특징

엑셀에서 Plan-B 카테고리는 `[PlanB/MGMT]` prefix를 사용합니다.

**이유:**
- CloudStack 카테고리와 혼재 방지
- 같은 개념이지만 구현 독립
- DB에서는 `planb_*` 테이블로 구현

**예시:**
```
[PlanB/MGMT] Pool(Master)  → planb_pool_master
[PlanB/MGMT] VM            → planb_vm
[PlanB/MGMT] Host(C-Node)  → planb_host
```

### 5.5 Plan-B에 없는 것

Plan-B는 Stack이 없으므로 다음 카테고리가 **존재하지 않습니다:**

```
❌ Network (VM에 IP만 있음)
❌ NIC (Network 정의 없음)
❌ PublicIP
❌ FirewallRule
❌ PortForwardingRule
❌ VirtualRouter
```

**이유:**
- Stack이 관리하는 Network/Security 메타데이터 없음
- Hypervisor는 VM, Storage만 알 수 있음

---

## 6. 왜 엑셀에서 이렇게 나눴나?

### 핵심 이유

1. **수집 위치가 다르면 데이터 신뢰도가 다르다**
2. 같은 "IP"라도
   - 정의 값(CS DB)
   - 실제 값(SSH)
   는 다를 수 있다
3. Canonical 모델은
   - "어디서 얻었는지"를 반드시 기억해야 한다

---

## 7. 엑셀을 읽을 때의 올바른 사고 흐름

```
1. 원천 시스템을 먼저 본다
2. 이 데이터가 "정의"인지 "사실"인지 판단
3. 카테고리로 Entity를 매핑
4. FK 카테고리로 관계를 유추
5. 비고로 설계 의도를 이해
```

### Plan-B 추가 확인사항

```
6. [PlanB/MGMT] prefix 확인
7. SSH (Hypervisor) = xe 명령 결과
8. COA DB = 수동 입력 또는 계산
```

---

## 8. 한 줄 요약

이 엑셀은

> "DB를 이렇게 만들자"가 아니라  
> "우리가 **어디서 무엇을 알고 있는지**를 정리한 지도"

다음 단계에서
- ERD
- 실제 테이블
- View / Cache 설계
로 자연스럽게 이어지게 된다.

---

## 참조 문서

- **canonical-model-reference.md**: Canonical 모델 전체 구조
- **troubleshooting-guide.md**: 헷갈리는 포인트 FAQ
