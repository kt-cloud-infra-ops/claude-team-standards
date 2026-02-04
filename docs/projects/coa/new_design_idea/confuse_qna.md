# Canonical Model Confuse

## 목차

1. [VM에 network_id가 없는 이유](#1-vm에-network_id가-없는-이유)
2. [VM에 storage_pool_id가 없는 이유](#2-vm에-storage_pool_id가-없는-이유)
3. [VM 방화벽이 실제로 VR인 이유](#3-vm-방화벽이-실제로-vr인-이유)
4. [전체 요약 그림](#4-전체-요약-그림)
5. [Plan-B 관련 FAQ](#5-plan-b-관련-faq)

---

## 소개

이 문서는 Canonical Model 설계에서 **자주 헷갈리는 포인트**를 설명합니다.

"왜 이렇게 설계했지?"라는 질문에 대한 답변 모음입니다.

---

## 1. VM에 network_id가 없는 이유

### ❓ 질문

"왜 VM 테이블에 network_id 컬럼이 없나요? VM이 네트워크에 직접 붙으면 안되나요?"

### ✅ 결론

VM은 "네트워크에 직접 붙는 객체"가 아니라,
**NIC(Port/VIF)라는 '연결점'을 통해 네트워크에 붙는다.**

### 📝 이유

VM은 보통 **NIC를 여러 개** 가질 수 있습니다.
- NIC 1: 내부망(Guest Network)
- NIC 2: 외부망(Public Network)
- NIC 3: 관리망(Management Network)

만약 VM 테이블에 network_id를 직접 넣으면?
- "VM이 네트워크를 1개만 가진다"는 잘못된 전제
- 여러 NIC/여러 네트워크 표현이 깨짐

### 📐 정규화된 관계 (정답 구조)

```
[VM/Instance]
    |
    | 1:N  (VM은 NIC를 여러개 가진다)
    v
[NIC/Port/VIF]
    |
    | N:1  (이 NIC가 어떤 네트워크 소속인지)
    v
[Network]
```

### 🌟 운영자 화면에서 생기는 착시

운영 화면은 보통 VM을 중심으로 JOIN 해서 보여줘서
마치 VM이 network_id를 직접 갖는 것처럼 느껴짐.

**UI에서 보는 느낌:**
```
[VM] -----> [Network]   (처럼 보임)
```

**실제 구조:**
```
[VM] -> [NIC] -> [Network]
```

### 💡 쉬운 비유

- VM = "노트북 본체"
- NIC = "LAN 포트 / Wi-Fi 카드"
- Network = "공유기/스위치"

노트북이 공유기에 "직접" 붙는 게 아니라,
LAN 포트(=NIC)를 통해 붙는 것과 같습니다.

---

## 2. VM에 storage_pool_id가 없는 이유

### ❓ 질문

"왜 VM 테이블에 storage_pool_id 컬럼이 없나요? VM이 스토리지를 직접 참조하면 안되나요?"

### ✅ 결론

VM은 "스토리지풀(SR)을 직접 참조"하지 않고,
**VolumeAttachment(VBD)가 VM과 Volume(VDI)을 연결**합니다.
그리고 Volume이 어느 StoragePool(SR)에 있는지 압니다.

### 📝 이유

VM은 **디스크를 여러 개** 달 수 있습니다.
- root disk
- data disk 1
- data disk 2
- ISO / CDROM 등

그리고 **디스크마다 스토리지 풀이 다를 수 있습니다.**
- Disk A는 SR1 (SSD 풀)
- Disk B는 SR2 (HDD 풀)

그래서 VM에 storage_pool_id를 박아버리면
"VM의 모든 디스크는 같은 풀" 같은 잘못된 가정이 들어갑니다.

### 📐 정규화된 관계 (정답 구조)

```
[VM/Instance]
    |
    | 1:N  (VM은 디스크를 여러개 붙일 수 있다)
    v
[VolumeAttachment / VBD]
    |
    | N:1
    v
[Volume / VDI]
    |
    | N:1
    v
[StoragePool / SR]
```

### 🔧 실제 "디스크 붙이기" 느낌

```
           (disk attach)
[VM] --------------------> [VBD] -----------------> [VDI] --------------> [SR]
  |                          |                      |
  |                          | device=xvda          | size/type
  |                          | device=xvdb          |
  |
  +--(여러개 붙일 수 있음)----+
```

### 🌟 운영자 화면에서 생기는 착시

운영 UI에서는 VM 화면에
"StoragePool"이 표시되기도 해서
VM이 SR을 직접 아는 것처럼 보입니다.

하지만 실제로는 **JOIN 결과**입니다:
```
VM -> VBD -> VDI -> SR
```
을 JOIN해서 보여주는 것입니다.

---

## 3. VM 방화벽이 실제로 VR인 이유

### ❓ 질문

"VM 화면에 방화벽이 있는데, 왜 실제로는 VR에서 동작한다고 하나요?"

### ✅ 결론

CloudStack에서 **Firewall / PortForwarding 정책 집행(iptables)은 VR에서 수행**됩니다.
VM은 방화벽을 "직접 갖는" 게 아니라,
운영 UI가 "VM 기준으로 정책을 모아 보여주는 것"입니다.

### 📝 이유

CloudStack Isolated Network 구조는 보통:
1. 외부에서 들어오는 트래픽이 먼저 **VR로 들어옴**
2. **VR이 NAT / Firewall 적용**하고
3. 내부 VM으로 전달

즉, "게이트"가 VR입니다.
VM 앞에 문지기(방화벽)가 있는 게 아니라,
**단지 출입구(=VR)에 방화벽이 있습니다.**

### 📐 실제 네트워크 트래픽 흐름 (Data Plane)

```
(Internet)
   |
   v
[Public IP]
   |
   v
+---------------------------+
| Virtual Router (VR)       |
|---------------------------|
| iptables -t nat (DNAT)    |  <-- PortForwarding
| iptables filter (ACCEPT)  |  <-- Firewall rule
+---------------------------+
   |
   v
[VM NIC (private IP)]
   |
   v
[VM]
```

### 🔧 PortForwarding + Firewall 한 그림으로

```
(Internet)  --  PublicIP:10.221.10.165:15022
    |
    v
 VR iptables nat:
   DNAT 15022 -> 172.27.0.204:22
    |
    v
 VR iptables filter:
   ACCEPT tcp/15022 from 0.0.0.0/0 ?
    |
    v
 VM:172.27.0.204:22
```

### 🌟 운영자 화면 vs 실제 동작

**운영자가 보는 화면:**
```
[VM]  <-- "이 VM의 방화벽/포트포워딩"
  |
  +-- FirewallRule (ACCEPT/DENY)
  |
  +-- PortForwardingRule (PublicIP:Port -> VM:Port)
```

**실제 집행 위치:**
```
FirewallRule / PortForwardingRule
     |
     v
[VR iptables]  <-- 여기서 진짜 적용됨
     |
     v
[VM]
```

### 🔗 "VM 포트체크 화면"과의 연결

VM 포트 열렸는지 확인하려면,
**VR에서 실제 NAT/Firewall 상태 기준**으로 봐야 정확합니다.

그래서 코드가:
1. DB로 "이 VM이 속한 네트워크의 VR"을 찾고
2. Host → VR로 SSH hop 한 뒤
3. VR에서 ping/nmap/iptables로 검증

---

## 4. 전체 요약 그림

### Network + Storage + Security 한눈에

```
          (Security enforcement)
                 +------------------+
Internet -> PublicIP -> VirtualRouter|  iptables (NAT/FW)
                 +---------+--------+
                           |
                           v
                   [Network / L2-L3]
                           |
                           v
                     [NIC / Port]
                           |
                           v
                         [VM]
                           |
                           | (disk attach)
                           v
                         [VBD]
                           |
                           v
                         [VDI]
                           |
                           v
                          [SR]
```

### 📌 핵심

1. VM은 Network를 **직접 참조하지 않음** (NIC가 참조)
2. VM은 SR을 **직접 참조하지 않음** (VBD→VDI→SR)
3. Firewall/PortForwarding은 **VM이 아니라 VR iptables**에서 집행

---

## 5. Plan-B 관련 FAQ

### Q1: Plan-B는 왜 Instance가 아니라 VM인가?

**A:**
- Instance는 CloudStack의 개념 (VM/VR/System 통합)
- Plan-B는 Stack 없이 Hypervisor만 있어서 **VR 개념 없음**
- 따라서 VM만 존재, 통합 불필요

### Q2: Plan-B에 Network 테이블이 없는 이유?

**A:**
- CloudStack/OPS는 Stack이 Network 정의를 관리
- Plan-B는 Stack 없어서 **Network 메타데이터 없음**
- Hypervisor가 아는 건 VIF(가상 NIC)뿐
- VM에 **IP 주소만 직접 속성**으로 가짐

### Q3: Plan-B Zone/Pod는 무엇인가?

**A:**
- 실제 Hypervisor 계층 아님
- 운영 편의상 **논리 분류** (예: 데이터센터별, 상면별)
- **Pool(Master)이 실제 계층 진입점**

### Q4: Plan-B에 방화벽/포트포워딩이 없는 이유?

**A:**
- CloudStack은 **VR이 방화벽 집행**
- Plan-B는 **VR 없음**
- 방화벽은 Hypervisor나 외부 장비에서 관리

### Q5: Plan-B Probe/점검은?

**A:**
- CloudStack처럼 VR 경유 점검 불가
- **Host SSH로 VM 직접 점검** 가능
- 현재 엑셀에는 미포함, 추후 추가 검토

### Q6: Plan-B Storage는 어떻게 다른가?

**A:**
- 개념은 동일: VM → VBD → VDI → SR
- 네이밍만 Xen 용어 사용
- CloudStack: VolumeAttach → Volume → StoragePool
- Plan-B: **VBD → VDI → SR** (xe 명령 출력과 1:1)

### Q7: Plan-B는 어떻게 수집하나?

**A:**
1. **COA DB (수동 입력)**: Pool(Master) IP, Password
2. **SSH (Hypervisor)**: xe 명령 실행
3. 결과 파싱 후 [PlanB/MGMT] 테이블에 저장

### Q8: Plan-B 네임스페이스가 뭔가?

**A:**
- CloudStack 테이블과 혼재 방지
- 같은 Canonical 개념이지만 **구현 독립**
- DB 스키마: planb_pool_master, planb_vm

---

## 참조 문서

- **canonical-model-reference.md**: Canonical 모델 전체 구조
- **excel-data-sheet-guide.md**: 엑셀 시트 해석 가이드
