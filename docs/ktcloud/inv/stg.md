# STG Environment Inventory

> Source: [Confluence - STG](https://ktcloud.atlassian.net/wiki/spaces/CL23/pages/953484239)
> 동기화일: 2026-02-09
> 서버 수: 38대

## 통합Dashboard

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 33 | m1-jpt-stg-kmon-a01 | AP | 172.25.2.13 | - | 10.230.9.43 | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 34 | m1-jpt-stg-kmon-a01 | AP | 172.25.2.15 | - | 10.230.13.27 | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 35 | m1-jpt-stg-kmon-a02 | AP | 172.25.2.16 | - | 10.230.13.28 | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 36 | m1-jpt-stg-kmon-w01 | WEB | 172.25.3.11 | - | 10.230.9.41 | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 37 | m1-jpt-stg-kmon-w01 | WEB | 172.25.3.13 | - | 10.230.13.25 | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 38 | m1-jpt-stg-kmon-w02 | WEB | 172.25.3.12 | - | 10.230.9.42 | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 39 | m1-jpt-stg-kmon-w02 | WEB | 172.25.3.14 | - | 10.230.13.26 | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 145 | m1-jpt-stg-hap-a01 | LB | 10.2.14.189 | - | - | 목동 | centos-7.9-64bit | - | 2 | 4 |
| 251 | p-mon-was-01 | AP | 10.4.224.93 | - | - | 천안 | centos-7.9-64bit | - | 8 | 16 |
| 252 | p-mon-was-02 | AP | 10.4.224.94 | - | - | 천안 | centos-7.9-64bit | - | 8 | 16 |

## ZabbixServer

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 242 | ca-jpt-stg-zab-a01 | AP | 10.0.8.208 | - | - | 천안 | rocky-8.10-64bit | - | 8 | 8 |
| 243 | ca-jpt-stg-zab-d01 | DB | 10.0.8.47 | - | - | 천안 | rocky-8.10-64bit | PostgreSQL 15.8 | 16 | 32 |
| 245 | ca-jpt-stg-zab-w01 | WEB | 10.0.8.207 | - | - | 천안 | rocky-8.10-64bit | - | 8 | 8 |

## ZabbixProxy

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 146 | m1-jpt-stg-zab-p01 | AP | 10.2.14.197 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 147 | m1-jpt-stg-zab-pd01 | DB | 10.2.14.199 | - | - | 목동 | rocky-8.10-64bit | PostgreSQL 15.8 | 4 | 8 |
| 244 | ca-jpt-stg-zab-p01 | AP | 10.0.8.46 | - | - | 천안 | rocky-8.10-64bit | - | 8 | 16 |
| 246 | p-mon-db-01 | DB | 10.4.224.95 | - | - | 천안 | centos-7.9-64bit | PostgreSQL 13.5 | 16 | 32 |
| 247 | p-mon-db-02 | DB | 10.4.224.96 | - | - | 천안 | centos-7.9-64bit | - | 16 | 32 |
| 253 | p-mon-web-01 | WEB | 10.4.224.91 | - | - | 천안 | centos-7.9-64bit | - | 4 | 4 |
| 254 | p-mon-web-02 | WEB | 10.4.224.92 | - | - | 천안 | centos-7.9-64bit | - | 4 | 4 |
| 255 | p-mon-zabbix-ap-01 | AP | 10.4.224.33 | - | - | 천안 | centos-7.9-64bit | - | 4 | 8 |
| 256 | p-mon-zabbix-db-01 | DB | 10.4.224.34 | - | - | 천안 | centos-7.9-64bit | PostgreSQL 13.5 | 4 | 8 |
| 257 | p-mon-zabbix-proxy-01 | AP | 10.4.224.40 | - | - | 천안 | centos-7.9-64bit | - | 2 | 4 |
| 258 | p-mon-zabbix-web-01 | WEB | 10.4.224.30 | - | - | 천안 | centos-7.9-64bit | - | 4 | 8 |

## HERA

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 165 | ys-hera-gapigw-stg-a01 | AP | 10.48.220.165 | - | - | 용산 | rocky-8.10-64bit | - | 8 | 16 |
| 166 | ys-hera-gapigw-stg-a02 | AP | 10.48.220.166 | - | - | 용산 | rocky-8.10-64bit | - | 8 | 16 |
| 167 | ys-hera-gapigw-stg-b01 | AP | 10.48.220.168 | - | - | 용산 | rocky-8.10-64bit | - | 16 | 32 |
| 168 | ys-hera-gapigw-stg-b02 | AP | 10.48.220.169 | - | - | 용산 | rocky-8.10-64bit | - | 16 | 32 |
| 169 | ys-hera-gapigw-stg-d01 | DB | 10.48.220.171 | - | - | 용산 | rocky-8.10-64bit | - | 16 | 32 |
| 170 | ys-hera-gapigw-stg-d02 | DB | 10.48.220.172 | - | - | 용산 | rocky-8.10-64bit | - | 16 | 32 |
| 199 | m1-hera-apigw-stg-a03 | AP | 10.0.1.112 | - | - | 목동 | rocky-8.10-64bit | - | 8 | 16 |
| 200 | m1-hera-apigw-stg-a04 | AP | 10.0.1.113 | - | - | 목동 | rocky-8.10-64bit | - | 8 | 16 |
| 201 | m1-hera-apigw-stg-b03 | AP | 10.0.1.114 | - | - | 목동 | rocky-8.10-64bit | - | 16 | 32 |
| 202 | m1-hera-apigw-stg-b04 | AP | 10.0.1.115 | - | - | 목동 | rocky-8.10-64bit | - | 16 | 32 |
| 203 | m1-hera-apigw-stg-d03 | DB | 10.0.1.116 | - | - | 목동 | rocky-8.10-64bit | Mariadb 11.4.4 | 16 | 32 |
| 204 | m1-hera-apigw-stg-d04 | DB | 10.0.1.117 | - | - | 목동 | rocky-8.10-64bit | Mariadb 11.4.4 | 16 | 32 |

## 기타

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 249 | p-mon-grafana-01 | AP | 10.4.224.29 | - | - | 천안 | centos-7.9-64bit | - | 4 | 8 |
| 250 | p-mon-prometheus-01 | AP | 10.4.224.35 | - | - | 천안 | centos-7.9-64bit | - | 8 | 8 |
