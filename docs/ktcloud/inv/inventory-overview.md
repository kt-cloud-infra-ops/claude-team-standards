---
tags:
  - type/reference
  - domain/sre
  - audience/team
---

> 상위: [ktcloud](../README.md)

# 인프라 인벤토리

> 원본: `Inventory_20260115.csv` (2026-01-15 기준)

## 요약

| 시스템 | 전체 | 사용 | 미사용 |
|--------|------|------|--------|
| LUPPITER | 18 | 10 | 8 |
| LUPPITER(ZABBIX) | 136 | 111 | 25 |
| LUPPITER(M-Kate) | 15 | 8 | 7 |
| LUPPITER(Prometheus) | 4 | 0 | 4 |
| LUPPITER(Topology) | 1 | 0 | 1 |
| HERA | 50 | 38 | 12 |
| GAIA | 32 | 27 | 5 |
| GIT | 3 | 1 | 2 |
| COA | 2 | 2 | 0 |
| CMDB | 1 | 0 | 1 |
| **합계** | **262** | **197** | **65** |

## LUPPITER

| # | 환경 | 상태 | 역할 | hostname | 기본 IP | NAT/Float IP | Storage IP | Services IP | Virtual IP | OS | CPU | MEM | SW |
|---|------|------|------|----------|---------|--------------|------------|-------------|------------|----|-----|-----|-----|
| 1 | 테스트 | 미사용 | AP | - | 172.25.0.98 | - | - | - | - | centos-7.9-64bit | 4 | 4 | - |
| 97 | 운영(PRD) | 사용 | LB | m1-jpt-prd-hap-a01 | 10.2.14.144 | - | - | - | 10.2.14.146
10.2.14.137
10.2.14.140
10.2.14.142
10.2.14.210 | centos-7.9-64bit | 4 | 4 | HAProxy version 2.6.1 |
| 98 | 운영(PRD) | 사용 | LB | m1-jpt-prd-hap-a02 | 10.2.14.145 | - | - | - | - | centos-7.9-64bit | 4 | 4 | HAProxy version 2.6.1 |
| 99 | 운영(PRD) | 미사용 | LB | m1-jpt-prd-hap-a03 | 10.2.14.161 | - | - | - | - | centos-7.9-64bit | 4 | 8 | - |
| 100 | 운영(PRD) | 미사용 | LB | m1-jpt-prd-hap-a04 | 10.2.14.162 | - | - | - | - | centos-7.9-64bit | 4 | 8 | - |
| 101 | 운영(PRD) | 사용 | AP | m1-jpt-prd-mon-a01 | 10.2.14.103 | - | - | - | - | centos-7.9-64bit | 8 | 16 | JAR_FILE: message_bridge.war Spring Boot Version: 2.7.5 JAR_FILE: luppiter_scheduler-1.0.0.jar Spring Boot Version: 3.3.5 JAR_FILE: luppiter-web.war Spring Boot Version: 2.7.5 |
| 102 | 운영(PRD) | 사용 | AP | m1-jpt-prd-mon-a02 | 10.2.14.104 | - | - | - | - | centos-7.9-64bit | 8 | 16 | JAR_FILE: luppiter-web.war Spring Boot Version: 2.7.5 JAR_FILE: SlackEventDispatcher-1.0.0.jar Spring Boot Version: 3.3.5 JAR_FILE: message_bridge.war Spring Boot Version: 2.7.5 |
| 103 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-mon-a03 | 10.2.14.107 | - | 10.2.8.99 | - | 10.2.14.139 | centos-7.9-64bit | 8 | 8 | grafana-9.0.6 |
| 104 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-mon-a04 | 10.2.14.108 | - | 10.2.8.115 | - | - | centos-7.9-64bit | 8 | 8 | - |
| 105 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-mon-a05 | 10.2.14.205 | - | - | - | 10.2.14.207 | rocky-8.10-64bit | 4 | 8 | podman 4.9.4 |
| 106 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-mon-a06 | 10.2.14.206 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | Apache/2.4.63, podman 4.9.4 |
| 107 | 운영(PRD) | 사용 | DB | m1-jpt-prd-mon-d01 | 10.2.14.105 | - | 10.2.8.73 | - | 10.2.14.138 | centos-7.9-64bit | 16 | 32 | PostgreSQL 13.5 |
| 108 | 운영(PRD) | 사용 | DB | m1-jpt-prd-mon-d02 | 10.2.14.106 | - | 10.2.8.87 | - | - | centos-7.9-64bit | 16 | 32 | PostgreSQL 13.5 |
| 109 | 운영(PRD) | 사용 | WEB | m1-jpt-prd-mon-w01 | 10.2.14.101 | - | - | - | - | centos-7.9-64bit | 4 | 4 | Apache/2.4.63 |
| 110 | 운영(PRD) | 사용 | WEB | m1-jpt-prd-mon-w02 | 10.2.14.102 | - | - | - | - | centos-7.9-64bit | 4 | 4 | Apache/2.4.63 |
| 145 | 스테이징(STG) | 미사용 | LB | m1-jpt-stg-hap-a01 | 10.2.14.189 | - | - | - | - | centos-7.9-64bit | 2 | 4 | HAProxy version 2.6.1 |
| 251 | 스테이징(STG) | 사용 | AP | p-mon-was-01 | 10.4.224.93 | - | - | 10.217.192.20 | - | centos-7.9-64bit | 8 | 16 | JAR_FILE: luppiter_web-2.0.0.war Spring Boot Version: 2.7.9 |
| 252 | 스테이징(STG) | 사용 | AP | p-mon-was-02 | 10.4.224.94 | - | - | 10.217.192.21 | - | centos-7.9-64bit | 8 | 16 | JAR_FILE: luppiter_web-2.0.0.war Spring Boot Version: 2.7.9 |

## LUPPITER(ZABBIX)

| # | 환경 | 상태 | 역할 | hostname | 기본 IP | NAT/Float IP | Storage IP | Services IP | Virtual IP | OS | CPU | MEM | SW |
|---|------|------|------|----------|---------|--------------|------------|-------------|------------|----|-----|-----|-----|
| 2 | 개발(DEV) | 사용 | AP | m1-jpt-dev-d1zab-p01 | 172.25.2.20 | 10.221.45.68 | - | - | - | centos-7.9-64bit | 4 | 4 | zabbix_proxy 5.0.25 |
| 3 | 개발(DEV) | 사용 | DB | m1-jpt-dev-d1zab-pd01 | 172.25.2.21 | 10.221.45.69 | - | - | - | centos-7.9-64bit | 4 | 8 | PostgreSQL 13.5 |
| 4 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-d1zab-a01 | 172.25.1.34 | 10.230.9.59 | - | - | 172.25.1.63 | centos-7.9-64bit | 8 | 16 | zabbix_server 5.0.25 |
| 5 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-d1zab-a01 | 172.25.1.53 | 10.230.7.83 | - | - | 172.25.1.63 | rocky-8.10-64bit | 8 | 16 | zabbix_server 7.0.18 |
| 6 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-d1zab-a02 | 172.25.1.35 | 10.230.9.60 | - | - | 172.25.1.64 | centos-7.9-64bit | 8 | 16 | zabbix_proxy 5.0.25 |
| 7 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-d1zab-a02 | 172.25.1.54 | 10.230.7.84 | - | - | - | rocky-8.10-64bit | 8 | 16 | - |
| 8 | 운영(PRD) | 미사용 | DB | m1-jpt-prd-d1zab-d01 | 172.25.1.37 | 10.230.9.61 | 172.25.44.37 | - | - | centos-7.9-64bit | 16 | 32 | PostgreSQL 13.5 |
| 9 | 운영(PRD) | 미사용 | DB | m1-jpt-prd-d1zab-d01 | 172.25.1.55 | 10.230.7.85 | 172.25.44.55 | - | 172.25.1.40 | rocky-8.10-64bit | 16 | 32 | PostgreSQL 16.9 |
| 10 | 운영(PRD) | 미사용 | DB | m1-jpt-prd-d1zab-d02 | 172.25.1.38 | 10.230.9.62 | 172.25.44.38 | - | - | centos-7.9-64bit | 16 | 32 | PostgreSQL 13.5 |
| 11 | 운영(PRD) | 미사용 | DB | m1-jpt-prd-d1zab-d02 | 172.25.1.56 | 10.230.7.86 | 172.25.44.56 | - | - | rocky-8.10-64bit | 16 | 32 | PostgreSQL 16.9 |
| 12 | 운영(PRD) | 사용 | AP | m1-jpt-prd-d1zab-p01 | 172.25.1.23 | 10.221.45.116 | - | - | - | centos-7.9-64bit | 8 | 8 | - |
| 13 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-d1zab-p01 | 172.25.1.57 | 10.230.7.87 | - | - | - | rocky-8.10-64bit | 8 | 8 | - |
| 14 | 운영(PRD) | 사용 | AP | m1-jpt-prd-d1zab-p02 | 172.25.1.89 | 10.221.45.117 | - | - | 172.25.1.71 | centos-7.9-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 15 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-d1zab-p02 | 172.25.1.58 | 10.230.7.88 | - | - | - | rocky-8.10-64bit | 8 | 8 | - |
| 16 | 운영(PRD) | 사용 | DB | m1-jpt-prd-d1zab-pd01 | 172.25.1.166 | 10.221.45.122 | - | - | 172.25.1.161 | centos-7.9-64bit | 8 | 16 | POstgreSQL 13.5 |
| 17 | 운영(PRD) | 미사용 | DB | m1-jpt-prd-d1zab-pd01 | 172.25.1.59 | 10.230.7.89 | - | - | - | rocky-8.10-64bit | 8 | 16 | PostgreSQL 16.9 |
| 18 | 운영(PRD) | 사용 | DB | m1-jpt-prd-d1zab-pd02 | 172.25.1.24 | 10.221.45.123 | - | - | - | centos-7.9-64bit | 8 | 16 | POstgreSQL 13.5 |
| 19 | 운영(PRD) | 미사용 | DB | m1-jpt-prd-d1zab-pd02 | 172.25.1.60 | 10.230.7.90 | - | - | - | rocky-8.10-64bit | 8 | 16 | PostgreSQL 16.9 |
| 20 | 운영(PRD) | 미사용 | WEB | m1-jpt-prd-d1zab-w01 | 172.25.1.31 | 10.230.9.57 | - | - | - | centos-7.9-64bit | 4 | 8 | Apache/2.4.34 |
| 21 | 운영(PRD) | 미사용 | WEB | m1-jpt-prd-d1zab-w01 | 172.25.1.51 | 10.230.7.81 | - | - | - | rocky-8.10-64bit | 4 | 8 | Apache/2.4.63 |
| 22 | 운영(PRD) | 미사용 | WEB | m1-jpt-prd-d1zab-w02 | 172.25.1.32 | 10.230.9.58 | - | - | - | centos-7.9-64bit | 4 | 8 | Apache/2.4.34 |
| 23 | 운영(PRD) | 미사용 | WEB | m1-jpt-prd-d1zab-w02 | 172.25.1.52 | 10.230.7.82 | - | - | - | rocky-8.10-64bit | 4 | 8 | Apache/2.4.63 |
| 32 | 테스트 | 미사용 | AP | - | 172.25.2.14 | 10.230.9.44 | - | - | - | ubuntu-24.04-64bit | 2 | 4 | - |
| 41 | 운영(PRD) | 사용 | AP | ca-jpt-prd-gzab-p01 | 10.48.0.43 | - | - | - | 10.48.0.128 | rocky-8.10-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 42 | 운영(PRD) | 사용 | AP | ca-jpt-prd-gzab-p02 | 10.48.0.46 | - | - | - | - | rocky-8.10-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 43 | 운영(PRD) | 사용 | AP | ca-jpt-prd-gzab-p03 | 10.48.0.47 | - | - | - | 10.48.0.130 | rocky-8.10-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 44 | 운영(PRD) | 사용 | AP | ca-jpt-prd-gzab-p04 | 10.48.0.48 | - | - | - | - | rocky-8.10-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 45 | 운영(PRD) | 사용 | DB | ca-jpt-prd-gzab-pd01 | 10.48.0.60 | - | - | - | 10.48.0.53 | rocky-8.10-64bit | 8 | 16 | PostgreSQL 16.9 |
| 46 | 운영(PRD) | 미사용 | DB | ca-jpt-prd-gzab-pd01 | 10.48.0.49 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | PostgreSQL 13.5 |
| 47 | 운영(PRD) | 사용 | DB | ca-jpt-prd-gzab-pd02 | 10.48.0.61 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | PostgreSQL 16.9 |
| 48 | 운영(PRD) | 미사용 | DB | ca-jpt-prd-gzab-pd02 | 10.48.0.54 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | PostgreSQL 13.5 |
| 95 | 운영(PRD) | 사용 | DB | m1-jpt-prd-zab-pd09 | 10.2.14.187 | - | 10.2.8.114 | - | 10.2.14.235 | centos-7.9-64bit | 8 | 16 | PostgreSQL 13.5 |
| 96 | 운영(PRD) | 사용 | DB | m1-jpt-prd-zab-pd10 | 10.2.14.188 | - | 10.2.8.113 | - | - | centos-7.9-64bit | 8 | 16 | PostgreSQL 13.5 |
| 113 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-a01 | 10.2.14.111 | - | 10.2.8.117 | - | 10.2.14.147 | centos-7.9-64bit | 16 | 16 | zabbix_server 5.0.25 |
| 114 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-a02 | 10.2.14.112 | - | 10.2.8.119 | - | - | centos-7.9-64bit | 16 | 16 | - |
| 115 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-a03 | 10.2.14.117 | - | 10.2.8.158 | - | 10.2.14.148 | centos-7.9-64bit | 16 | 32 | zabbix_server 5.0.25 |
| 116 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-a04 | 10.2.14.118 | - | 10.2.8.169 | - | - | centos-7.9-64bit | 16 | 16 | - |
| 117 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-a05 | 10.2.14.211 | - | 10.2.8.184 | - | 10.2.14.213 | rocky-8.10-64bit | 8 | 16 | zabbix_server 7.0.3 |
| 118 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-a06 | 10.2.14.212 | - | 10.2.8.186 | - | - | rocky-8.10-64bit | 8 | 16 | - |
| 119 | 운영(PRD) | 사용 | DB | m1-jpt-prd-zab-d01 | 10.2.14.113 | - | 10.2.8.154 | - | 10.2.14.141 | centos-7.9-64bit | 16 | 32 | PostgreSQL 13.5 MariaDB 10.5.16 |
| 120 | 운영(PRD) | 사용 | DB | m1-jpt-prd-zab-d02 | 10.2.14.114 | - | 10.2.8.156 | - | - | centos-7.9-64bit | 16 | 32 | PostgreSQL 13.5 |
| 121 | 운영(PRD) | 사용 | DB | m1-jpt-prd-zab-d03 | 10.2.14.119 | - | 10.2.8.171 | - | - | centos-7.9-64bit | 16 | 32 | PostgreSQL 13.5 |
| 122 | 운영(PRD) | 사용 | DB | m1-jpt-prd-zab-d04 | 10.2.14.120 | - | 10.2.8.173 | - | 10.2.14.143 | centos-7.9-64bit | 16 | 32 | PostgreSQL 13.5 |
| 123 | 운영(PRD) | 사용 | DB | m1-jpt-prd-zab-d05 | 10.2.14.135 | - | 10.2.8.183 | - | 10.2.14.151 | centos-7.9-64bit | 8 | 16 | PostgreSQL 13.5 |
| 124 | 운영(PRD) | 사용 | DB | m1-jpt-prd-zab-d06 | 10.2.14.136 | - | 10.2.8.185 | - | - | centos-7.9-64bit | 8 | 16 | PostgreSQL 13.5 |
| 125 | 운영(PRD) | 사용 | DB | m1-jpt-prd-zab-d07 | 10.2.14.129 | - | 10.2.8.198 | - | 10.2.14.154 | centos-7.9-64bit | 8 | 16 | PostgreSQL 13.5 |
| 126 | 운영(PRD) | 사용 | DB | m1-jpt-prd-zab-d08 | 10.2.14.130 | - | 10.2.8.205 | - | - | centos-7.9-64bit | 8 | 16 | PostgreSQL 13.5 |
| 127 | 운영(PRD) | 사용 | DB | m1-jpt-prd-zab-d09 | 10.2.14.214 | - | 10.2.8.188 | - | 10.2.14.216 | rocky-8.10-64bit | 16 | 32 | PostgreSQL 15.8 |
| 128 | 운영(PRD) | 사용 | DB | m1-jpt-prd-zab-d10 | 10.2.14.215 | - | 10.2.8.190 | - | - | rocky-8.10-64bit | 16 | 32 | PostgreSQL 15.8 |
| 129 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-p01 | 10.2.14.121 | - | 10.2.8.175 | - | 10.2.14.149 | centos-7.9-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 130 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-p02 | 10.2.14.122 | - | 10.2.8.177 | - | - | centos-7.9-64bit | 8 | 8 | - |
| 131 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-p03 | 10.2.14.123 | - | 10.2.8.179 | - | 10.2.14.150 | centos-7.9-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 132 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-p04 | 10.2.14.124 | - | 10.2.8.181 | - | - | centos-7.9-64bit | 8 | 8 | - |
| 133 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-p05 | 10.2.14.125 | - | 10.2.8.187 | - | 10.2.14.152 | centos-7.9-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 134 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-p06 | 10.2.14.126 | - | 10.2.8.189 | - | - | centos-7.9-64bit | 8 | 8 | - |
| 135 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-p07 | 10.2.14.127 | - | 10.2.8.194 | - | 10.2.14.153 | centos-7.9-64bit | 8 | 16 | zabbix_proxy 5.0.25 |
| 136 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-p08 | 10.2.14.128 | - | 10.2.8.196 | - | - | centos-7.9-64bit | 8 | 16 | - |
| 137 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-p09 | 10.2.14.185 | - | 10.2.8.77 | - | - | centos-7.9-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 138 | 운영(PRD) | 사용 | AP | m1-jpt-prd-zab-p10 | 10.2.14.186 | - | 10.2.8.75 | - | 10.2.14.230 | centos-7.9-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 139 | 운영(PRD) | 사용 | WEB | m1-jpt-prd-zab-w01 | 10.2.14.109 | - | - | - | - | centos-7.9-64bit | 4 | 8 | Apache/2.4.63 |
| 140 | 운영(PRD) | 사용 | WEB | m1-jpt-prd-zab-w02 | 10.2.14.110 | - | - | - | - | centos-7.9-64bit | 4 | 8 | Apache/2.4.63 |
| 141 | 운영(PRD) | 사용 | WEB | m1-jpt-prd-zab-w03 | 10.2.14.115 | - | - | - | - | centos-7.9-64bit | 4 | 4 | Apache/2.4.63 |
| 142 | 운영(PRD) | 사용 | WEB | m1-jpt-prd-zab-w04 | 10.2.14.116 | - | - | - | - | centos-7.9-64bit | 4 | 4 | Apache/2.4.63 |
| 143 | 운영(PRD) | 사용 | WEB | m1-jpt-prd-zab-w05 | 10.2.14.208 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | Apache/2.4.63 |
| 144 | 운영(PRD) | 사용 | WEB | m1-jpt-prd-zab-w06 | 10.2.14.209 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | Apache/2.4.63 |
| 146 | 스테이징(STG) | 사용 | AP | m1-jpt-stg-zab-p01 | 10.2.14.197 | - | - | - | - | rocky-8.10-64bit | 4 | 4 | zabbix_proxy 7.0.3 |
| 147 | 스테이징(STG) | 사용 | DB | m1-jpt-stg-zab-pd01 | 10.2.14.199 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | PostgreSQL 15.8 |
| 149 | 개발(DEV) | 사용 | DB | p-mon-mk1-d01 | 10.2.14.54 | - | - | - | - | centos-7.9-64bit | 4 | 16 | PostgreSQL 13.5 |
| 150 | 개발(DEV) | 사용 | WEB | p-mon-mk1-w01 | 10.2.14.52 | - | - | - | - | centos-7.9-64bit | 16 | 32 | Apache 2.4.41 |
| 151 | 개발(DEV) | 사용 | WEB | p-mon-mk1-w02 | 10.2.14.55 | - | - | - | - | Windows 2016 Standard | 4 | 4 | - |
| 171 | 운영(PRD) | 사용 | AP | ys-jpt-prd-gzab-a01 | 172.27.1.20 | 10.48.219.72 | 10.48.222.23 | - | 172.27.1.102 | rocky-8.10-64bit | 16 | 16 | zabbix_server 5.0.25 |
| 172 | 운영(PRD) | 사용 | AP | ys-jpt-prd-gzab-a02 | 172.27.1.89 | 10.48.219.73 | 10.48.222.24 | - | - | rocky-8.10-64bit | 16 | 16 | - |
| 173 | 운영(PRD) | 사용 | DB | ys-jpt-prd-gzab-d01 | 172.27.1.85 | 10.48.219.74 | 10.48.222.20 | - | 172.27.1.103 | rocky-8.10-64bit | 16 | 32 | PostgreSQL 16.9 |
| 174 | 운영(PRD) | 미사용 | DB | ys-jpt-prd-gzab-d01 | 172.27.1.49 | 10.48.219.90 | 10.48.222.26 | - | - | rocky-8.10-64bit | 16 | 32 | PostgreSQL 13.5 |
| 175 | 운영(PRD) | 사용 | DB | ys-jpt-prd-gzab-d02 | 172.27.1.60 | 10.48.219.75 | 10.48.222.15 | - | - | rocky-8.10-64bit | 16 | 32 | PostgreSQL 16.9 |
| 176 | 운영(PRD) | 미사용 | DB | ys-jpt-prd-gzab-d02 | 172.27.1.38 | 10.48.219.91 | 10.48.222.27 | - | - | rocky-8.10-64bit | 16 | 32 | PostgreSQL 13.5 |
| 177 | 운영(PRD) | 사용 | AP | ys-jpt-prd-gzab-p01 | 172.27.1.39 | 10.48.219.76 | 10.48.222.17 | - | 172.27.1.104 | rocky-8.10-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 178 | 운영(PRD) | 사용 | AP | ys-jpt-prd-gzab-p02 | 172.27.1.74 | 10.48.219.77 | 10.48.222.18 | - | - | rocky-8.10-64bit | 8 | 8 | - |
| 179 | 운영(PRD) | 사용 | AP | ys-jpt-prd-gzab-p03 | 172.27.1.55 | 10.48.219.78 | 10.48.222.21 | - | 172.27.1.105 | rocky-8.10-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 180 | 운영(PRD) | 사용 | AP | ys-jpt-prd-gzab-p04 | 172.27.1.52 | 10.48.219.79 | 10.48.222.22 | - | - | rocky-8.10-64bit | 8 | 8 | - |
| 181 | 운영(PRD) | 사용 | DB | ys-jpt-prd-gzab-pd01 | 172.27.1.58 | 10.48.219.80 | 10.48.222.19 | - | 172.27.1.106 | rocky-8.10-64bit | 8 | 16 | PostgreSQL 16.9 |
| 182 | 운영(PRD) | 미사용 | DB | - | 172.27.1.4 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | - |
| 183 | 운영(PRD) | 사용 | DB | ys-jpt-prd-gzab-pd02 | 172.27.1.86 | 10.48.219.81 | 10.48.222.25 | - | - | rocky-8.10-64bit | 8 | 16 | PostgreSQL 16.9 |
| 184 | 운영(PRD) | 미사용 | DB | - | 172.27.1.47 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | - |
| 185 | 운영(PRD) | 사용 | AP | - | 172.27.1.64 | - | - | - | - | rocky-8.10-64bit | 4 | 4 | - |
| 186 | 운영(PRD) | 사용 | WEB | ys-jpt-prd-gzab-w01 | 172.27.0.76 | 10.48.219.70 | - | - | - | rocky-8.10-64bit | 4 | 8 | Apache/2.4.63 |
| 187 | 운영(PRD) | 사용 | WEB | ys-jpt-prd-gzab-w02 | 172.27.0.82 | 10.48.219.71 | - | - | - | rocky-8.10-64bit | 4 | 8 | Apache/2.4.63 |
| 188 | 운영(PRD) | 사용 | LB | ys-jpt-prd-hap-a01 | 172.27.0.73 | 10.48.219.68 | - | - | 172.27.0.101 | rocky-8.10-64bit | 4 | 4 | HAProxy version 2.6.1 |
| 189 | 운영(PRD) | 사용 | LB | ys-jpt-prd-hap-a02 | 172.27.0.18 | 10.48.219.69 | - | - | - | rocky-8.10-64bit | 4 | 4 | HAProxy version 2.6.1 |
| 190 | 테스트 | 미사용 | AP | - | 172.27.0.35 | - | - | - | - | rocky-8.10-64bit | 4 | 4 | - |
| 191 | 운영(PRD) | 사용 | AP | ys-jpt-prd-url-p01 | 10.48.224.137 | - | - | - | 10.48.224.140 | rocky-8.10-64bit | 8 | 8 | sqlite-3.26.0-19, zabbix_proxy 7.0.3 |
| 192 | 운영(PRD) | 사용 | AP | ys-jpt-prd-url-p02 | 10.48.224.147 | - | - | - | - | rocky-8.10-64bit | 8 | 8 | sqlite-3.26.0-19, zabbix_proxy 7.0.3 |
| 193 | 테스트 | 미사용 | AP | - | 10.48.224.132 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | - |
| 205 | 개발(DEV) | 사용 | WEB | p-mon-mk1-w03 | 10.0.1.49 | - | - | 10.217.17.21 | - | centos-7.9-64bit | 2 | 4 | Apache/2.4.34 |
| 216 | 운영(PRD) | 사용 | LB | ca-jpt-prd-hap-a01 | 10.0.8.199 | - | 10.220.255.127 | - | 10.0.8.219
10.0.8.142 | centos-7.9-64bit | 8 | 8 | HAProxy version 2.6.1 |
| 217 | 운영(PRD) | 사용 | LB | ca-jpt-prd-hap-a02 | 10.0.8.206 | - | 10.220.255.129 | - | - | centos-7.9-64bit | 8 | 8 | HAProxy version 2.6.1 |
| 218 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-a01 | 10.0.8.223 | - | 10.220.255.135 | - | 10.0.8.143 | centos-7.9-64bit | 4 | 8 | zabbix_server 5.0.25 |
| 219 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-a02 | 10.0.8.224 | - | 10.220.255.137 | - | - | centos-7.9-64bit | 4 | 8 | - |
| 220 | 운영(PRD) | 사용 | DB | ca-jpt-prd-zab-d01 | 10.0.8.191 | - | 10.220.255.111 | - | 10.0.8.215 | centos-7.9-64bit | 8 | 16 | PostgreSQL 13.5 |
| 221 | 운영(PRD) | 사용 | DB | ca-jpt-prd-zab-d02 | 10.0.8.192 | - | 10.220.255.113 | - | - | centos-7.9-64bit | 8 | 16 | PostgreSQL 13.5 |
| 222 | 운영(PRD) | 사용 | DB | ca-jpt-prd-zab-d03 | 10.0.8.197 | - | 10.220.255.123 | - | 10.0.8.218 | centos-7.9-64bit | 8 | 16 | PostgreSQL 13.5 |
| 223 | 운영(PRD) | 사용 | DB | ca-jpt-prd-zab-d04 | 10.0.8.198 | - | 10.220.255.125 | - | - | centos-7.9-64bit | 8 | 16 | PostgreSQL 13.5 |
| 224 | 운영(PRD) | 사용 | DB | ca-jpt-prd-zab-d05 | 10.0.8.225 | - | 10.220.255.139 | - | - | centos-7.9-64bit | 4 | 8 | PostgreSQL 13.5 |
| 225 | 운영(PRD) | 사용 | DB | ca-jpt-prd-zab-d06 | 10.0.8.226 | - | 10.220.255.141 | - | 10.0.8.144 | centos-7.9-64bit | 4 | 8 | PostgreSQL 13.5 |
| 226 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-log01 | 10.0.8.119 | - | 10.220.255.163 | - | 10.0.8.78 | rocky-8.10-64bit | 8 | 8 | syslog-ng 4.8.0 |
| 227 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-log02 | 10.0.8.120 | - | 10.220.255.164 | - | - | rocky-8.10-64bit | 8 | 8 | - |
| 228 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-p01 | 10.0.8.186 | - | 10.220.255.103 | - | 10.0.8.213 | centos-7.9-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 229 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-p02 | 10.0.8.187 | - | 10.220.255.105 | - | - | centos-7.9-64bit | 8 | 8 | - |
| 230 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-p03 | 10.0.8.188 | - | 10.220.255.107 | - | 10.0.8.214 | centos-7.9-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 231 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-p04 | 10.0.8.189 | - | 10.220.255.109 | - | - | centos-7.9-64bit | 8 | 8 | - |
| 232 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-p05 | 10.0.8.193 | - | 10.220.255.115 | - | 10.0.8.216 | centos-7.9-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 233 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-p06 | 10.0.8.194 | - | 10.220.255.117 | - | - | centos-7.9-64bit | 8 | 8 | - |
| 234 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-p07 | 10.0.8.195 | - | 10.220.255.119 | - | 10.0.8.217 | centos-7.9-64bit | 16 | 16 | zabbix_proxy 5.0.25 |
| 235 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-p08 | 10.0.8.196 | - | 10.220.255.121 | - | - | centos-7.9-64bit | 8 | 8 | - |
| 236 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-p09 | 10.0.8.115 | - | 10.220.255.159 | - | 10.0.8.76 | rocky-8.10-64bit | 16 | 16 | zabbix_proxy 7.0.3 |
| 237 | 운영(PRD) | 사용 | AP | ca-jpt-prd-zab-p10 | 10.0.8.116 | - | 10.220.255.160 | - | - | rocky-8.10-64bit | 16 | 16 | - |
| 238 | 운영(PRD) | 사용 | DB | ca-jpt-prd-zab-pd07 | 10.0.8.117 | - | 10.220.255.161 | - | 10.0.8.77 | rocky-8.10-64bit | 8 | 16 | PostgreSQL 15.8 |
| 239 | 운영(PRD) | 사용 | DB | ca-jpt-prd-zab-pd08 | 10.0.8.118 | - | 10.220.255.162 | - | - | rocky-8.10-64bit | 8 | 16 | PostgreSQL 15.8 |
| 240 | 운영(PRD) | 사용 | WEB | ca-jpt-prd-zab-w01 | 10.0.8.221 | - | - | - | - | centos-7.9-64bit | 4 | 8 | Apache/2.4.63 |
| 241 | 운영(PRD) | 사용 | WEB | ca-jpt-prd-zab-w02 | 10.0.8.222 | - | - | - | - | centos-7.9-64bit | 4 | 8 | Apache/2.4.63 |
| 242 | 스테이징(STG) | 사용 | AP | ca-jpt-stg-zab-a01 | 10.0.8.208 | - | - | - | - | rocky-8.10-64bit | 8 | 8 | zabbix_server 7.0.3 |
| 243 | 스테이징(STG) | 사용 | DB | ca-jpt-stg-zab-d01 | 10.0.8.47 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | PostgreSQL 15.8 |
| 244 | 스테이징(STG) | 사용 | AP | ca-jpt-stg-zab-p01 | 10.0.8.46 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | zabbix_proxy 7.0.3 |
| 245 | 스테이징(STG) | 사용 | WEB | ca-jpt-stg-zab-w01 | 10.0.8.207 | - | - | - | - | rocky-8.10-64bit | 8 | 8 | Apache/2.4.63 |
| 246 | 스테이징(STG) | 사용 | DB | p-mon-db-01 | 10.4.224.95 | - | 10.217.192.22 | - | 10.4.224.97 | centos-7.9-64bit | 16 | 32 | PostgreSQL 13.5 |
| 247 | 스테이징(STG) | 사용 | DB | p-mon-db-02 | 10.4.224.96 | - | - | - | - | centos-7.9-64bit | 16 | 32 | - |
| 253 | 스테이징(STG) | 사용 | WEB | p-mon-web-01 | 10.4.224.91 | - | - | 10.217.192.13 | 10.217.192.15 | centos-7.9-64bit | 4 | 4 | Apache/2.4.63 |
| 254 | 스테이징(STG) | 사용 | WEB | p-mon-web-02 | 10.4.224.92 | - | - | 10.217.192.14 | - | centos-7.9-64bit | 4 | 4 | Apache/2.4.63 |
| 255 | 스테이징(STG) | 사용 | AP | p-mon-zabbix-ap-01 | 10.4.224.33 | - | - | - | - | centos-7.9-64bit | 4 | 8 | - |
| 256 | 스테이징(STG) | 사용 | DB | p-mon-zabbix-db-01 | 10.4.224.34 | - | - | - | - | centos-7.9-64bit | 4 | 8 | PostgreSQL 13.5 |
| 257 | 스테이징(STG) | 사용 | AP | p-mon-zabbix-proxy-01 | 10.4.224.40 | - | - | - | - | centos-7.9-64bit | 2 | 4 | zabbix_proxy 5.0.25 |
| 258 | 스테이징(STG) | 사용 | WEB | p-mon-zabbix-web-01 | 10.4.224.30 | - | - | 10.217.192.25 | - | centos-7.9-64bit | 4 | 8 | Apache/2.4.63 |
| 259 | 운영(PRD) | 사용 | AP | BD-JPT-PRD-ZAB-P01 | 172.31.187.240 | - | - | 172.31.50.153
172.31.206.196 | - | centos-7.9-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 260 | 운영(PRD) | 사용 | AP | BD-JPT-PRD-ZAB-P03 | 172.31.187.244 | - | - | 172.31.50.154
172.31.206.198 | - | centos-7.9-64bit | 8 | 8 | zabbix_proxy 5.0.25 |
| 261 | 운영(PRD) | 사용 | DB | BD-JPT-PRD-ZAB-D01 | 172.31.187.242 | - | - | 172.31.206.197 | - | centos-7.9-64bit | 8 | 8 | PostgreSQL 13.5 |
| 262 | 운영(PRD) | 사용 | DB | BD-JPT-PRD-ZAB-D03 | 172.31.187.246 | - | - | 172.31.206.199 | - | centos-7.9-64bit | 8 | 8 | PostgreSQL 13.5 |

## LUPPITER(M-Kate)

| # | 환경 | 상태 | 역할 | hostname | 기본 IP | NAT/Float IP | Storage IP | Services IP | Virtual IP | OS | CPU | MEM | SW |
|---|------|------|------|----------|---------|--------------|------------|-------------|------------|----|-----|-----|-----|
| 24 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-kmon-a01 | 172.25.1.130 | 10.221.45.114 | - | - | - | centos-7.9-64bit | 4 | 4 | JAR_FILE: luppiter-web-mkate.war Spring Boot Version: 2.7.5 |
| 25 | 운영(PRD) | 사용 | AP | m1-jpt-prd-kmon-a01 | 172.25.1.13 | 10.230.7.115 | - | - | - | rocky-8.10-64bit | 4 | 4 | JAR_FILE: luppiter-web-mkate.war Spring Boot Version: 2.7.5 |
| 26 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-kmon-a02 | 172.25.1.174 | 10.221.45.115 | - | - | - | centos-7.9-64bit | 4 | 4 | JAR_FILE: luppiter-web-mkate.war Spring Boot Version: 2.7.5 |
| 27 | 운영(PRD) | 사용 | AP | m1-jpt-prd-kmon-a02 | 172.25.1.14 | 10.230.7.116 | - | - | - | rocky-8.10-64bit | 4 | 4 | JAR_FILE: luppiter-web-mkate.war Spring Boot Version: 2.7.5 |
| 28 | 운영(PRD) | 미사용 | WEB | m1-jpt-prd-kmon-w01 | 172.25.0.103 | 10.221.45.118 | - | - | - | centos-7.9-64bit | 4 | 4 | Apache/2.4.34 |
| 29 | 운영(PRD) | 사용 | WEB | m1-jpt-prd-kmon-w01 | 172.25.0.11 | 10.230.7.113 | - | - | - | rocky-8.10-64bit | 4 | 4 | Apache/2.4.63 |
| 30 | 운영(PRD) | 미사용 | WEB | m1-jpt-prd-kmon-w02 | 172.25.0.59 | 10.221.45.119 | - | - | - | centos-7.9-64bit | 4 | 4 | Apache/2.4.34 |
| 31 | 운영(PRD) | 사용 | WEB | m1-jpt-prd-kmon-w02 | 172.25.0.12 | 10.230.7.114 | - | - | - | rocky-8.10-64bit | 4 | 4 | Apache/2.4.63 |
| 33 | 스테이징(STG) | 미사용 | AP | m1-jpt-stg-kmon-a01 | 172.25.2.13 | 10.230.9.43 | - | - | - | centos-7.9-64bit | 4 | 4 | JAR_FILE: luppiter-web-mkate.war Spring Boot Version: 2.7.5 |
| 34 | 스테이징(STG) | 사용 | AP | m1-jpt-stg-kmon-a01 | 172.25.2.15 | 10.230.13.27 | - | - | - | rocky-8.10-64bit | 4 | 4 | JAR_FILE: luppiter-web-mkate.war Spring Boot Version: 2.7.5 |
| 35 | 스테이징(STG) | 사용 | AP | m1-jpt-stg-kmon-a02 | 172.25.2.16 | 10.230.13.28 | - | - | - | rocky-8.10-64bit | 4 | 4 | JAR_FILE: luppiter-web-mkate.war Spring Boot Version: 2.7.5 |
| 36 | 스테이징(STG) | 미사용 | WEB | m1-jpt-stg-kmon-w01 | 172.25.3.11 | 10.230.9.41 | - | - | - | centos-7.9-64bit | 4 | 4 | Apache/2.4.34 |
| 37 | 스테이징(STG) | 사용 | WEB | m1-jpt-stg-kmon-w01 | 172.25.3.13 | 10.230.13.25 | - | - | - | rocky-8.10-64bit | 4 | 4 | Apache/2.4.63 |
| 38 | 스테이징(STG) | 미사용 | WEB | m1-jpt-stg-kmon-w02 | 172.25.3.12 | 10.230.9.42 | - | - | - | centos-7.9-64bit | 4 | 4 | Apache/2.4.34 |
| 39 | 스테이징(STG) | 사용 | WEB | m1-jpt-stg-kmon-w02 | 172.25.3.14 | 10.230.13.26 | - | - | - | rocky-8.10-64bit | 4 | 4 | Apache/2.4.63 |

## LUPPITER(Prometheus)

| # | 환경 | 상태 | 역할 | hostname | 기본 IP | NAT/Float IP | Storage IP | Services IP | Virtual IP | OS | CPU | MEM | SW |
|---|------|------|------|----------|---------|--------------|------------|-------------|------------|----|-----|-----|-----|
| 111 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-pro-a01 | 10.2.14.131 | - | 10.2.8.212 | - | 10.2.14.155 | centos-7.9-64bit | 8 | 8 | Docker version 24.0.2 |
| 112 | 운영(PRD) | 미사용 | AP | m1-jpt-prd-pro-a03 | 10.2.14.133 | - | 10.2.8.216 | - | 10.2.14.156 | centos-7.9-64bit | 8 | 8 | prometheus version 2.39.1 |
| 249 | 스테이징(STG) | 미사용 | AP | p-mon-grafana-01 | 10.4.224.29 | - | - | 10.217.192.24 | - | centos-7.9-64bit | 4 | 8 | grafana-8.5.5 |
| 250 | 스테이징(STG) | 미사용 | AP | p-mon-prometheus-01 | 10.4.224.35 | - | - | - | - | centos-7.9-64bit | 8 | 8 | prometheus version 2.39.1 |

## LUPPITER(Topology)

| # | 환경 | 상태 | 역할 | hostname | 기본 IP | NAT/Float IP | Storage IP | Services IP | Virtual IP | OS | CPU | MEM | SW |
|---|------|------|------|----------|---------|--------------|------------|-------------|------------|----|-----|-----|-----|
| 50 | 운영(PRD) | 미사용 | AP | m1-clb-prd-topo-a01 | 10.2.14.172 | - | - | - | - | centos-7.9-64bit | 4 | 8 | - |

## HERA

| # | 환경 | 상태 | 역할 | hostname | 기본 IP | NAT/Float IP | Storage IP | Services IP | Virtual IP | OS | CPU | MEM | SW |
|---|------|------|------|----------|---------|--------------|------------|-------------|------------|----|-----|-----|-----|
| 74 | 개발(DEV) | 사용 | AP | m1-hera-apigw-a01 | 10.2.14.166 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | JAR_FILE: apigw-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 JAR_FILE: hera_dbgw-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 |
| 75 | 개발(DEV) | 사용 | AP | m1-hera-apigw-b01 | 10.2.14.167 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | JAR_FILE: batch_runner-0.0.1-SNAPSHOT.jar Spring Boot Version: 3.3.5 |
| 76 | 개발(DEV) | 사용 | DB | m1-hera-apigw-d01 | 10.2.14.170 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | Mariadb 11.4.4 |
| 77 | 운영(PRD) | 사용 | AP | m1-hera-apigw-prd-a01 | 10.2.14.194 | - | 10.2.8.217 | - | - | rocky-8.10-64bit | 16 | 16 | - |
| 78 | 운영(PRD) | 사용 | AP | m1-hera-apigw-prd-a02 | 10.2.14.195 | - | 10.2.8.218 | - | 10.2.14.196 | rocky-8.10-64bit | 16 | 16 | JAR_FILE: apigw-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 JAR_FILE: hera_dbgw-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 |
| 79 | 운영(PRD) | 사용 | AP | m1-hera-apigw-prd-b01 | 10.2.14.198 | - | 10.2.8.219 | - | - | rocky-8.10-64bit | 32 | 32 | - |
| 80 | 운영(PRD) | 사용 | AP | m1-hera-apigw-prd-b02 | 10.2.14.200 | - | 10.2.8.220 | - | 10.2.14.201 | rocky-8.10-64bit | 32 | 32 | - |
| 81 | 운영(PRD) | 사용 | DB | m1-hera-apigw-prd-d01 | 10.2.14.202 | - | 10.2.8.180 | - | 10.2.14.204 | rocky-8.10-64bit | 16 | 32 | Mariadb 11.4.4 |
| 82 | 운영(PRD) | 사용 | DB | m1-hera-apigw-prd-d02 | 10.2.14.203 | - | 10.2.8.182 | - | - | rocky-8.10-64bit | 16 | 32 | Mariadb 11.4.4 |
| 83 | 개발(DEV) | 사용 | AP | m1-hera-comm-a01 | 10.2.14.165 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | JAR_FILE: hera-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 |
| 84 | 개발(DEV) | 사용 | DB | m1-hera-comm-d01 | 10.2.14.169 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | Mariadb 11.4.4 |
| 85 | 운영(PRD) | 사용 | AP | m1-hera-comm-prd-a01 | 10.2.14.183 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | JAR_FILE: hera-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 |
| 86 | 운영(PRD) | 사용 | AP | m1-hera-comm-prd-a02 | 10.2.14.184 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | JAR_FILE: hera-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 |
| 87 | 운영(PRD) | 사용 | DB | m1-hera-comm-prd-d01 | 10.2.14.191 | - | 10.2.8.176 | - | - | rocky-8.10-64bit | 16 | 16 | Mariadb 11.4.4 |
| 88 | 운영(PRD) | 사용 | DB | m1-hera-comm-prd-d02 | 10.2.14.192 | - | 10.2.8.178 | - | 10.2.14.193 | rocky-8.10-64bit | 16 | 16 | Mariadb 11.4.4 |
| 89 | 운영(PRD) | 사용 | WEB | m1-hera-comm-prd-w01 | 10.2.14.178 | - | - | - | - | rocky-8.10-64bit | 4 | 16 | Apache/2.4.63 |
| 90 | 운영(PRD) | 사용 | WEB | m1-hera-comm-prd-w02 | 10.2.14.180 | - | - | - | - | rocky-8.10-64bit | 4 | 16 | Apache/2.4.63 |
| 91 | 개발(DEV) | 사용 | WEB | m1-hera-comm-w01 | 10.2.14.163 | - | - | - | - | rocky-8.10-64bit | 2 | 4 | Apache/2.4.63 |
| 92 | 운영(PRD) | 사용 | LB | m1-hera-hap-prd-a01 | 10.2.14.59 | - | - | - | 10.2.14.176
10.2.14.182 | rocky-8.10-64bit | 4 | 4 | HAProxy version 3.0.5 |
| 93 | 운영(PRD) | 사용 | LB | m1-hera-hap-prd-a02 | 10.2.14.174 | - | - | - | - | rocky-8.10-64bit | 4 | 4 | HAProxy version 3.0.5 |
| 156 | 개발(DEV) | 사용 | AP | ys-hera-gapigw-a01 | 10.48.220.162 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | JAR_FILE: apigw-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 JAR_FILE: hera_dbgw-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 |
| 157 | 개발(DEV) | 사용 | AP | ys-hera-gapigw-b01 | 10.48.220.163 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | JAR_FILE: batch_runner-0.0.1-SNAPSHOT.jar Spring Boot Version: 3.3.5 |
| 158 | 개발(DEV) | 사용 | DB | ys-hera-gapigw-d01 | 10.48.220.164 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | Mariadb 11.4.2 Mariadb 11.4.4 |
| 159 | 운영(PRD) | 사용 | AP | ys-hera-gapigw-prd-a01 | 10.48.220.194 | - | - | - | - | rocky-8.10-64bit | 16 | 16 | - |
| 160 | 운영(PRD) | 사용 | AP | ys-hera-gapigw-prd-a02 | 10.48.220.195 | - | - | - | 10.48.220.196 | rocky-8.10-64bit | 16 | 16 | JAR_FILE: apigw-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 JAR_FILE: hera_dbgw-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 |
| 161 | 운영(PRD) | 사용 | AP | ys-hera-gapigw-prd-b01 | 10.48.220.197 | - | - | - | 10.48.220.199 | rocky-8.10-64bit | 32 | 32 | - |
| 162 | 운영(PRD) | 사용 | AP | ys-hera-gapigw-prd-b02 | 10.48.220.198 | - | - | - | - | rocky-8.10-64bit | 32 | 32 | - |
| 163 | 운영(PRD) | 사용 | DB | ys-hera-gapigw-prd-d01 | 10.48.220.200 | - | - | - | 10.48.220.202 | rocky-8.10-64bit | 16 | 32 | Mariadb 11.4.4 |
| 164 | 운영(PRD) | 사용 | DB | ys-hera-gapigw-prd-d02 | 10.48.220.201 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | Mariadb 11.4.4 |
| 165 | 스테이징(STG) | 미사용 | AP | ys-hera-gapigw-stg-a01 | 10.48.220.165 | - | - | - | 10.48.220.167 | rocky-8.10-64bit | 8 | 16 | - |
| 166 | 스테이징(STG) | 미사용 | AP | ys-hera-gapigw-stg-a02 | 10.48.220.166 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | - |
| 167 | 스테이징(STG) | 미사용 | AP | ys-hera-gapigw-stg-b01 | 10.48.220.168 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | - |
| 168 | 스테이징(STG) | 미사용 | AP | ys-hera-gapigw-stg-b02 | 10.48.220.169 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | - |
| 169 | 스테이징(STG) | 미사용 | DB | ys-hera-gapigw-stg-d01 | 10.48.220.171 | - | - | - | 10.48.220.173 | rocky-8.10-64bit | 16 | 32 | - |
| 170 | 스테이징(STG) | 미사용 | DB | ys-hera-gapigw-stg-d02 | 10.48.220.172 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | - |
| 196 | 개발(DEV) | 사용 | AP | m1-hera-apigw-a03 | 10.0.1.36 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | JAR_FILE: apigw-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 JAR_FILE: hera_dbgw-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 |
| 197 | 개발(DEV) | 사용 | AP | m1-hera-apigw-b03 | 10.0.1.37 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | JAR_FILE: batch_runner-0.0.1-SNAPSHOT.jar Spring Boot Version: 3.3.5 |
| 198 | 개발(DEV) | 사용 | DB | m1-hera-apigw-d03 | 10.0.1.38 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | Mariadb 11.4.4 |
| 199 | 스테이징(STG) | 미사용 | AP | m1-hera-apigw-stg-a03 | 10.0.1.112 | - | 3.1.16.147 | - | 10.0.1.118 | rocky-8.10-64bit | 8 | 16 | - |
| 200 | 스테이징(STG) | 미사용 | AP | m1-hera-apigw-stg-a04 | 10.0.1.113 | - | 3.1.16.148 | - | - | rocky-8.10-64bit | 8 | 16 | - |
| 201 | 스테이징(STG) | 미사용 | AP | m1-hera-apigw-stg-b03 | 10.0.1.114 | - | 3.1.16.149 | - | 10.0.1.119 | rocky-8.10-64bit | 16 | 32 | - |
| 202 | 스테이징(STG) | 미사용 | AP | m1-hera-apigw-stg-b04 | 10.0.1.115 | - | 3.1.16.150 | - | - | rocky-8.10-64bit | 16 | 32 | - |
| 203 | 스테이징(STG) | 미사용 | DB | m1-hera-apigw-stg-d03 | 10.0.1.116 | - | 3.1.16.145 | - | 10.0.1.120 | rocky-8.10-64bit | 16 | 32 | Mariadb 11.4.4 |
| 204 | 스테이징(STG) | 미사용 | DB | m1-hera-apigw-stg-d04 | 10.0.1.117 | - | 3.1.16.146 | - | - | rocky-8.10-64bit | 16 | 32 | Mariadb 11.4.4 |
| 210 | 운영(PRD) | 사용 | AP | ca-hera-apigw-prd-a03 | 10.0.8.51 | - | 10.220.255.167 | - | 10.0.8.57 | rocky-8.10-64bit | 16 | 16 | JAR_FILE: apigw-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 JAR_FILE: hera_dbgw-0.0.1-SNAPSHOT.war Spring Boot Version: 3.3.5 |
| 211 | 운영(PRD) | 사용 | AP | ca-hera-apigw-prd-a04 | 10.0.8.52 | - | 10.220.255.168 | - | - | rocky-8.10-64bit | 16 | 16 | - |
| 212 | 운영(PRD) | 사용 | AP | ca-hera-apigw-prd-b03 | 10.0.8.53 | - | 10.220.255.169 | - | 10.0.8.58 | rocky-8.10-64bit | 32 | 32 | - |
| 213 | 운영(PRD) | 사용 | AP | ca-hera-apigw-prd-b04 | 10.0.8.54 | - | 10.220.255.170 | - | - | rocky-8.10-64bit | 32 | 32 | - |
| 214 | 운영(PRD) | 사용 | DB | ca-hera-apigw-prd-d03 | 10.0.8.55 | - | 10.220.255.165 | - | 10.0.8.59 | rocky-8.10-64bit | 16 | 32 | Mariadb 11.4.4 |
| 215 | 운영(PRD) | 사용 | DB | ca-hera-apigw-prd-d04 | 10.0.8.56 | - | 10.220.255.166 | - | - | rocky-8.10-64bit | 16 | 32 | Mariadb 11.4.4 |

## GAIA

| # | 환경 | 상태 | 역할 | hostname | 기본 IP | NAT/Float IP | Storage IP | Services IP | Virtual IP | OS | CPU | MEM | SW |
|---|------|------|------|----------|---------|--------------|------------|-------------|------------|----|-----|-----|-----|
| 40 | 운영(PRD) | 사용 | AP | ca-gaia-prd-ansible-ep01 | 10.48.0.129 | - | - | - | - | rocky-8.10-64bit | 8 | 8 | - |
| 51 | 운영(PRD) | 사용 | AP | m1-gaia-ans-prd-a01 | 10.2.14.97 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | - |
| 52 | 운영(PRD) | 사용 | AP | m1-gaia-ans-prd-a02 | 10.2.14.98 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | - |
| 53 | 운영(PRD) | 사용 | AP | m1-gaia-ans-prd-a03 | 10.2.14.99 | - | - | - | - | rocky-8.10-64bit | 8 | 16 | - |
| 54 | 운영(PRD) | 사용 | AP | m1-gaia-cm-prd-c01 | 10.2.14.64 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | kubernetes-cni-1.2.0-150500.2.1.x86_64 kubectl-1.28.15-150500.1.1.x86_64 kubelet-1.28.15-150500.1.1.x86_64 kubeadm-1.28.15-150500.1.1.x86_64 |
| 55 | 운영(PRD) | 사용 | AP | m1-gaia-cm-prd-c02 | 10.2.14.65 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | kubernetes-cni-1.2.0-150500.2.1.x86_64 kubelet-1.28.15-150500.1.1.x86_64 kubectl-1.28.15-150500.1.1.x86_64 kubeadm-1.28.15-150500.1.1.x86_64 |
| 56 | 운영(PRD) | 사용 | AP | m1-gaia-cm-prd-c03 | 10.2.14.66 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | kubernetes-cni-1.2.0-150500.2.1.x86_64 kubelet-1.28.15-150500.1.1.x86_64 kubectl-1.28.15-150500.1.1.x86_64 kubeadm-1.28.15-150500.1.1.x86_64 |
| 57 | 운영(PRD) | 사용 | DB | m1-gaia-comm-prd-d01 | 10.2.14.92 | - | - | - | - | rocky-8.10-64bit | 32 | 64 | PostgreSQL 15.14 |
| 58 | 운영(PRD) | 사용 | DB | m1-gaia-comm-prd-d02 | 10.2.14.93 | - | - | - | - | rocky-8.10-64bit | 32 | 64 | PostgreSQL 15.14 |
| 59 | 운영(PRD) | 사용 | AP | m1-gaia-cw-prd-c01 | 10.2.14.67 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | kubernetes-cni-1.2.0-150500.2.1.x86_64 kubelet-1.28.15-150500.1.1.x86_64 kubectl-1.28.15-150500.1.1.x86_64 kubeadm-1.28.15-150500.1.1.x86_64 |
| 60 | 운영(PRD) | 사용 | AP | m1-gaia-cw-prd-c02 | 10.2.14.217 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | kubernetes-cni-1.2.0-150500.2.1.x86_64 kubelet-1.28.15-150500.1.1.x86_64 kubectl-1.28.15-150500.1.1.x86_64 kubeadm-1.28.15-150500.1.1.x86_64 |
| 61 | 운영(PRD) | 사용 | AP | m1-gaia-cw-prd-c03 | 10.2.14.218 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | kubernetes-cni-1.2.0-150500.2.1.x86_64 kubelet-1.28.15-150500.1.1.x86_64 kubectl-1.28.15-150500.1.1.x86_64 kubeadm-1.28.15-150500.1.1.x86_64 |
| 62 | 개발(DEV) | 사용 | AP | m1-gaia-dev-ansible-a01 | 10.2.14.160 | - | - | - | - | rocky-8.10-64bit | 32 | 96 | kubernetes-cni-1.5.1-150500.1.1.x86_64 kubeadm-1.31.0-150500.1.1.x86_64 kubectl-1.31.0-150500.1.1.x86_64 kubelet-1.31.0-150500.1.1.x86_64 |
| 63 | 개발(DEV) | 사용 | AP | m1-gaia-dev-ansible-p01 | 10.2.14.158 | - | - | - | - | rocky-8.10-64bit | 2 | 8 | - |
| 64 | 개발(DEV) | 미사용 | AP | - | 10.2.14.159 | - | - | - | - | rocky-8.10-64bit | 2 | 8 | - |
| 65 | 개발(DEV) | 사용 | WEB | m1-gaia-dev-ansible-w01 | 10.2.14.157 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | - |
| 66 | 운영(PRD) | 사용 | LB | m1-gaia-hap-prd-a01 | 10.2.14.62 | - | - | - | 10.2.14.61 | rocky-8.10-64bit | 4 | 4 | HAProxy version 1.8.27 |
| 67 | 운영(PRD) | 사용 | LB | m1-gaia-hap-prd-a02 | 10.2.14.63 | - | - | - | - | rocky-8.10-64bit | 4 | 4 | HA-Proxy version 1.8.27 |
| 68 | 운영(PRD) | 사용 | AP | m1-gaia-mq-prd-a01 | 10.2.14.94 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | kubeadm-1.28.15-150500.1.1.x86_64 kubectl-1.28.15-150500.1.1.x86_64 kubelet-1.28.15-150500.1.1.x86_64 kubernetes-cni-1.2.0-150500.2.1.x86_64 |
| 69 | 운영(PRD) | 사용 | AP | m1-gaia-mq-prd-a02 | 10.2.14.95 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | kubelet-1.28.15-150500.1.1.x86_64 kubectl-1.28.15-150500.1.1.x86_64 kubernetes-cni-1.2.0-150500.2.1.x86_64 kubeadm-1.28.15-150500.1.1.x86_64 |
| 70 | 운영(PRD) | 사용 | AP | m1-gaia-mq-prd-a03 | 10.2.14.96 | - | - | - | - | rocky-8.10-64bit | 4 | 8 | kubelet-1.28.15-150500.1.1.x86_64 kubectl-1.28.15-150500.1.1.x86_64 kubernetes-cni-1.2.0-150500.2.1.x86_64 kubeadm-1.28.15-150500.1.1.x86_64 |
| 71 | 운영(PRD) | 사용 | AP | m1-gaia-prd-ansible-a02 | 10.2.14.58 | - | - | - | - | rocky-8.10-64bit | 12 | 16 | - |
| 72 | 운영(PRD) | 사용 | AP | m1-gaia-prd-ansible-p01-new | 10.2.14.132 | - | - | - | - | rocky-8.10-64bit | 24 | 16 | - |
| 73 | 운영(PRD) | 사용 | AP | m1-gaia-prd-ansible-p02 | 10.2.14.134 | - | - | - | - | rocky-8.10-64bit | 8 | 8 | - |
| 152 | 운영(PRD) | 미사용 | AP | - | 172.27.1.31 | - | - | - | - | centos-7.9-64bit | 8 | 16 | - |
| 153 | 운영(PRD) | 미사용 | AP | - | 172.27.1.28 | - | - | - | - | centos-7.9-64bit | 8 | 16 | - |
| 154 | 운영(PRD) | 사용 | AP | ys-gaia-prd-ansible-p01 | 172.27.1.41 | 10.48.219.82 | - | - | - | rocky-8.10-64bit | 8 | 16 | - |
| 155 | 운영(PRD) | 사용 | AP | ys-gaia-prd-ansible-p02 | 172.27.1.59 | 10.48.219.83 | - | - | - | rocky-8.10-64bit | 8 | 16 | - |
| 206 | 운영(PRD) | 미사용 | AP | ca-cla-prd-a01 | 10.0.8.44 | - | - | - | - | centos-7.9-64bit | 8 | 16 | - |
| 207 | 운영(PRD) | 미사용 | DB | ca-cla-prd-d01 | 10.0.8.45 | - | - | - | - | centos-7.9-64bit | 16 | 32 | - |
| 208 | 운영(PRD) | 사용 | AP | ca-gaia-prd-ansible-p01 | 10.0.8.42 | - | - | - | - | rocky-8.10-64bit | 12 | 20 | - |
| 209 | 운영(PRD) | 사용 | DB | ca-gaia-prd-ansible-p02 | 10.0.8.43 | - | - | - | - | rocky-8.10-64bit | 16 | 32 | - |

## GIT

| # | 환경 | 상태 | 역할 | hostname | 기본 IP | NAT/Float IP | Storage IP | Services IP | Virtual IP | OS | CPU | MEM | SW |
|---|------|------|------|----------|---------|--------------|------------|-------------|------------|----|-----|-----|-----|
| 94 | 개발(DEV) | 미사용 | AP | m1-jpt-com-git-01 | 10.2.14.228 | - | - | - | - | centos-7.9-64bit | 4 | 8 | - |
| 148 | 개발(DEV) | 미사용 | AP | m1-ops-com-git-01 | 10.2.14.229 | - | - | - | - | centos-7.9-64bit | 4 | 8 | - |
| 248 | 운영(PRD) | 사용 | AP/DB | p-mon-git-01 | 10.4.224.36 | - | - | 10.217.192.26 | - | centos-7.9-64bit | 8 | 16 | (gitlab) redis 7.0.14 (gitlab) PostgreSQL 13.12, (gitlab) nginx/1.24.0, gitlab 16.7.2 |

## COA

| # | 환경 | 상태 | 역할 | hostname | 기본 IP | NAT/Float IP | Storage IP | Services IP | Virtual IP | OS | CPU | MEM | SW |
|---|------|------|------|----------|---------|--------------|------------|-------------|------------|----|-----|-----|-----|
| 194 | 개발(DEV) | 사용 | AP/DB | dev-coa | 10.0.1.144 | - | - | 10.217.17.109 | - | centos-6.3-64bit | 8 | 16 | Mysql 14.14, Apache/2.2.15 |
| 195 | 운영(PRD) | 사용 | AP/DB | hub | 10.0.1.253 | - | - | 10.217.17.252 | - | centos-6.2-64bit | 8 | 16 | Mysql 14.14, Apache/2.2.15 |

## CMDB

| # | 환경 | 상태 | 역할 | hostname | 기본 IP | NAT/Float IP | Storage IP | Services IP | Virtual IP | OS | CPU | MEM | SW |
|---|------|------|------|----------|---------|--------------|------------|-------------|------------|----|-----|-----|-----|
| 49 | 운영(PRD) | 미사용 | DB | m1-clb-prd-inv-d01 | 10.2.14.173 | - | 10.2.8.112 | - | - | centos-7.9-64bit | 8 | 16 | PostgreSQL 13.5 |
