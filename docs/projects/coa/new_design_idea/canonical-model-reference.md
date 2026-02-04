# Canonical Cloud / Hypervisor Data Model Reference

## 목차

0. [목적](#0-목적)
1. [핵심 개념 요약](#1-핵심-개념-요약)
2. [Instance 개념](#2-instance-개념)
3. [Network Canonical ERD](#3-network-canonical-erd)
4. [Public IP & Security ERD](#4-public-ip--security-erd)
5. [실제 트래픽 흐름 (CloudStack)](#5-실제-트래픽-흐름-cloudstack-기준)
6. [VM 포트 점검 SSH 흐름](#6-vm-포트-점검-화면의-실제-ssh-흐름)
7. [Storage Canonical ERD](#7-storage-canonical-erd)
8. [Plan-B Model (Hypervisor Only)](#8-plan-b-model-hypervisor-only)

---

## 0. 목적

이 문서는 CloudStack, OPS(OpenStack), Plan-B(No Stack, Hypervisor Only)를
동시에 수용하는 Canonical 데이터 모델(ERD 중심)을 설명하기 위한 참조 문서이다.

**목표:**
- 플랫폼별 차이를 흡수하는 공통 개념 모델
- 데이터 모델(정규화/FK)과 UI(View/Join) 분리
- 네트워크 / 스토리지 / 보안 책임의 명확한 분리

**대상 플랫폼:**
- CloudStack
- OpenStack (OPS)
- Plan-B (No Stack, Hypervisor Direct)

---

## 1. 핵심 개념 요약

### 3대 원칙

1. **모든 실행 단위는 Instance로 통합** (CloudStack/OPS만 해당)
   - User VM, VirtualRouter, System VM을 하나의 테이블로
   - 구분은 `instance_kind`, `instance_role` 컬럼으로

2. **VM은 직접 참조하지 않음**
   - VM → Network ❌ (NIC를 통해)
   - VM → StoragePool ❌ (VolumeAttachment를 통해)
   - VM → PublicIP ❌ (PublicIPAttachment를 통해)

3. **보이는 구조 ≠ 실제 동작**
   - UI: "VM 방화벽"
   - Reality: VR iptables

---

## 2. Instance 개념

**CloudStack / OPS 전용 개념**

Instance는 하나의 테이블로 통합하되, 구분은 컬럼으로 처리한다.

```
Instance
  ├─ instance_kind : compute | network | system
  └─ instance_role : user_vm | virtual_router | system_vm | ...
```

**예시:**
- User VM → `kind=compute, role=user_vm`
- VirtualRouter → `kind=network, role=virtual_router`
- Console Proxy → `kind=system, role=console_proxy`

**Plan-B 차이점:**
- Plan-B는 Instance 개념 없음
- `[PlanB/MGMT] VM` 테이블 사용 (VR 없으므로 통합 불필요)

---

## 3. Network Canonical ERD

### 3.1 논리적 연결 구조 (정규화)

```
[ Instance ]
     |
     | 1:N
     v
[ NIC / Port / VIF ]
     |
     | N:1
     v
[ Network ]
```

### 3.2 플랫폼 매핑

| Canonical | CloudStack | OpenStack | Plan-B |
|-----------|-----------|-----------|--------|
| Instance/VM | vm_instance | Nova Server | [PlanB/MGMT] VM |
| NIC/Port/VIF | nics | neutron port | ❌ 없음 |
| Network | networks | neutron network | ❌ 없음 |

**Plan-B 차이점:**
- Network, NIC 테이블 없음
- VM에 IP 주소가 직접 속성으로 존재

---

## 4. Public IP & Security ERD

### 4.1 Public IP Attachment

```
[ PublicIP ]
     |
     | 1:N
     v
[ PublicIPAttachment ]
     |
     | N:1
     v
[ Attach Target ]
  (instance | nic | network)
```

PublicIP는 VM에 직접 붙지 않는다.

### 4.2 Firewall / PortForwarding 구조

```
[ FirewallRule ]
  - scope_type (network | public_ip | instance | nic)
  - scope_id
  - purpose (Firewall | PortForwarding)
  - protocol / port range / source_cidr
  - action / state
     |
     | 1:1 (purpose=PortForwarding)
     v
[ PortForwardingRule ]
     |
     | dest_nic_id
     v
[ NIC ] → [ Instance (VM) ]
```

**Plan-B 차이점:**
- PublicIP, FirewallRule, PortForwardingRule 모두 없음
- 방화벽은 Hypervisor 외부에서 관리

---

## 5. 실제 트래픽 흐름 (CloudStack 기준)

### 5.1 Data Plane (실제 집행 위치)

```
( Internet )
     |
     v
[ Public IP ]
     |
     v
+------------------------+
|   Virtual Router       |
|------------------------|
| iptables (nat)         |
|  - DNAT / SNAT         |
| iptables (filter)      |
|  - Firewall rules      |
| conntrack              |
+------------------------+
     |
     v
[ Network ]
     |
     v
[ NIC ]
     |
     v
[ VM ]
```

### 5.2 운영자 UI vs Reality

**UI에서 보이는 구조:**
```
[VM] → [FirewallRule] → [Public IP]
```

**실제 동작:**
```
[FirewallRule] → [VR iptables] → [VM]
```

**핵심:**
- "VM 방화벽"은 UI 개념
- 실제 enforcement는 VR

**Plan-B 차이점:**
- VR 없음 → 네트워크/보안 계층 없음

---

## 6. VM 포트 점검 화면의 실제 SSH 흐름

**CloudStack 코드 기준**

```
[ Web UI / PHP ]
      |
      | (1) CS DB 조회
      |     VM → NIC → Network → VR → Host
      v
[ CloudStack DB ]
      |
      | (2) SSH 접속
      v
[ Hypervisor Host ]
      |
      | (3) SSH (port 3922)
      v
[ Virtual Router ]
      |
      | (4) ping / nmap 실행
      v
[ VM (private IP) ]
```

**결론:**
- VM 하나를 선택해도
- 실제 점검은 VR 내부에서 수행됨

**Plan-B 차이점:**
- VR 없음 → Host에서 VM 직접 점검

---

## 7. Storage Canonical ERD

VM은 StoragePool을 직접 참조하지 않는다.

```
[ Instance (VM) ]
     |
     | 1:N
     v
[ VolumeAttachment (VBD) ]
     |
     | N:1
     v
[ Volume (VDI) ]
     |
     | N:1
     v
[ StoragePool (SR) ]
```

### 플랫폼 매핑

| Canonical | CloudStack | OpenStack | Plan-B |
|-----------|-----------|-----------|--------|
| StoragePool | storage_pool | backend pool | [PlanB/MGMT] StoragePool(SR) |
| Volume | volumes | cinder volume | [PlanB/MGMT] Volume(VDI) |
| VolumeAttachment | volume_attach | volume attach | [PlanB/MGMT] VolumeAttachment(VBD) |

---

## 8. Plan-B Model (Hypervisor Only)

### 8.1 Plan-B 개요

**특징:**
- CloudStack / OpenStack 미사용
- XenServer Pool Master 직접 관리
- SSH xe 명령으로 메타데이터 수집
- **Network/Security 계층 없음**
- **VirtualRouter 없음**

### 8.2 Plan-B vs CloudStack

| 구분 | CloudStack/OPS | Plan-B |
|------|---------------|--------|
| **진입점** | Zone → Pod → Cluster | **Pool(Master)** |
| **계층** | 4단계 (Zone/Pod/Cluster/Host) | **2단계 (Pool/Host)** |
| **실행 개체** | Instance (VM/VR/System 통합) | **VM** (단순) |
| **Network** | NIC → Network | **없음** (VM IP만) |
| **Security** | FirewallRule, PortForwarding | **없음** |
| **Storage** | VolumeAttach → Volume → StoragePool | **VBD → VDI → SR** (Xen 용어) |
| **SSH 접속** | Host → VR (2-hop) | **Host (직접)** |
| **Zone/Pod** | 실제 계층 | **논리 개념** (운영 분류) |

### 8.3 Plan-B 계층 구조

```
Platform (공통 진입점)
   ↓
[PlanB/MGMT] Pool(Master)    ← 수동 등록 (Master IP, Password)
   ↓
   ├─→ [PlanB/MGMT] Host(C-Node)
   │      · Host UUID, Host IP
   │      · MGMT IP, IPMI IP
   │      · CPU, Memory, Uptime
   │      ↓ (1:N)
   │   [PlanB/MGMT] VM
   │      · VM UUID, VM 명
   │      · IP 주소 (Network 정의 없음)
   │      · vCPU, Memory
   │      · PV Driver
   │      ↓ (1:N)
   │   [PlanB/MGMT] VolumeAttachment(VBD)
   │      · VBD UUID
   │      · Device (xvda, xvdb...)
   │      ↓ (N:1)
   │   [PlanB/MGMT] Volume(VDI)
   │      · VDI UUID
   │      · Virtual Size, Physical Used
   │      ↓ (N:1)
   │   [PlanB/MGMT] StoragePool(SR)
   │      · SR UUID
   │      · 전체/사용 용량
   │
   └─→ [PlanB/MGMT] Zone/Pod    ← 논리 개념 (실제 계층 아님)
```

### 8.4 Plan-B FK 관계

```
[PlanB/MGMT] Pool(Master)
  ↑ FK: Platform ID

[PlanB/MGMT] Host
  ↑ FK: Platform ID, Pool UUID

[PlanB/MGMT] VM
  ↑ FK: Platform ID, Pool UUID, Host UUID

[PlanB/MGMT] StoragePool(SR)
  ↑ FK: Platform ID, Pool UUID

[PlanB/MGMT] Volume(VDI)
  ↑ FK: SR UUID

[PlanB/MGMT] VolumeAttachment(VBD)
  ↑ FK: VM UUID, VDI UUID

[PlanB/MGMT] Zone/Pod
  ↑ FK: Platform ID
  (논리 개념, 실제 계층 없음)
```

### 8.5 Plan-B 데이터 수집

**수집 방식:**
1. **COA DB (수동 입력)**
   - Pool(Master) 정보: Master IP, Password, Zone명

2. **SSH (Hypervisor) - xe 명령**
   - Pool UUID: `xe pool-list`
   - Host 정보: `xe host-list`
   - VM 정보: `xe vm-list`
   - Storage: `xe sr-list`, `xe vdi-list`, `xe vbd-list`

**수집 흐름:**
```
[ COA 배치 작업 ]
      |
      | 1) COA DB에서 Pool(Master) 정보 조회
      |    (Master IP, Password)
      v
[ SSH 접속 ]
      |
      | ssh root@{Master IP}
      v
[ Hypervisor Host (Pool Master) ]
      |
      | 2) xe 명령 실행
      |    xe pool-list
      |    xe host-list
      |    xe vm-list
      |    xe sr-list
      |    xe vdi-list
      |    xe vbd-list
      v
[ 결과 파싱 ]
      |
      v
[ COA DB 저장 ]
  [PlanB/MGMT] 테이블들
```

### 8.6 Plan-B 네임스페이스

**모든 Plan-B 테이블은 `[PlanB/MGMT]` prefix 사용**

**이유:**
- CloudStack 테이블과 혼재 방지
- 같은 Canonical 개념이지만 구현 독립
- DB 스키마에서 `planb_*` 테이블로 구현

**예시:**
- `[PlanB/MGMT] Pool(Master)` → `planb_pool_master`
- `[PlanB/MGMT] VM` → `planb_vm`
- `[PlanB/MGMT] StoragePool(SR)` → `planb_storage_pool`

### 8.7 Plan-B Zone/Pod (논리 개념)

**CloudStack vs Plan-B:**

| 항목 | CloudStack | Plan-B |
|------|-----------|--------|
| Zone | 실제 계층 (리전/DC) | **논리 분류** (운영 편의) |
| Pod | 실제 계층 (랙/상면) | **논리 분류** (운영 편의) |
| Cluster | 실제 계층 (리소스 풀) | **없음** |
| 진입점 | Zone | **Pool(Master)** |

**Plan-B Zone/Pod 역할:**
- 실제 Hypervisor 계층 아님
- 운영 편의상 논리 분류 (예: 데이터센터별, 상면별)
- **Pool(Master)이 실제 계층 진입점**

### 8.8 Plan-B 전체 흐름도

```
┌─────────────────────────────────────────┐
│            Platform                     │
│  (CloudStack / OPS / Plan-B)            │
└──────────┬──────────────────┬───────────┘
           │                  │
   ┌───────▼────────┐   ┌────▼──────────────────┐
   │ CloudStack/OPS │   │ Plan-B (No Stack)     │
   │ (Stack 기반)    │   │ (Hypervisor Direct)   │
   └───────┬────────┘   └────┬──────────────────┘
           │                 │
    Zone→Pod→Cluster   [PlanB/MGMT] Pool(Master)
           │                 │
         Host          [PlanB/MGMT] Host
           │                 │
       Instance        [PlanB/MGMT] VM
    (VM/VR/System)           │
           │                 │
    ┌──────┴──────┐          │
    │             │          │
 Network       Storage    Storage
(NIC 중심)  (VolumeAttach) (VBD/VDI/SR)
    │
 Security
(Firewall/PF)
```

### 8.9 Plan-B 한계

**수집하지 않는 것:**
- Network 정의 (VM IP만 알 수 있음)
- 방화벽 정책 (Hypervisor 외부 관리)
- VirtualRouter (개념 없음)
- 포트포워딩 (개념 없음)

**이유:**
- Plan-B는 Stack이 없어서 Stack이 관리하는 메타데이터 없음
- Hypervisor가 아는 건 VM, Storage뿐

---

## 참조 문서

- **troubleshooting-guide.md**: 헷갈리는 포인트 FAQ
- **excel-data-sheet-guide.md**: 엑셀 시트 해석 가이드
