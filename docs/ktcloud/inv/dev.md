# DEV Environment Inventory

> Source: [Confluence - DEV](https://ktcloud.atlassian.net/wiki/spaces/CL23/pages/954303335)
> 동기화일: 2026-02-09
> 서버 수: 29대

## 통합Dashboard

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 1 | - | AP | 172.25.0.98 | - | - | 목동 | centos-7.9-64bit | - | 4 | 4 |

## ZabbixProxy

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 2 | m1-jpt-dev-d1zab-p01 | AP | 172.25.2.20 | - | 10.221.45.68 | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 3 | m1-jpt-dev-d1zab-pd01 | DB | 172.25.2.21 | - | 10.221.45.69 | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 4 | 8 |
| 32 | - | AP | 172.25.2.14 | - | 10.230.9.44 | 목동 | ubuntu-24.04-64bit | - | 2 | 4 |
| 149 | p-mon-mk1-d01 | DB | 10.2.14.54 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 4 | 16 |
| 150 | p-mon-mk1-w01 | WEB | 10.2.14.52 | - | - | 목동 | centos-7.9-64bit | - | 16 | 32 |
| 151 | p-mon-mk1-w02 | WEB | 10.2.14.55 | - | - | 목동 | Windows 2016 Standard | - | 4 | 4 |
| 190 | - | AP | 172.27.0.35 | - | - | 용산 | rocky-8.10-64bit | - | 4 | 4 |
| 193 | - | AP | 10.48.224.132 | - | - | 용산 | rocky-8.10-64bit | - | 4 | 8 |
| 205 | p-mon-mk1-w03 | WEB | 10.0.1.49 | - | - | 목동 | centos-7.9-64bit | - | 2 | 4 |

## HERA

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 74 | m1-hera-apigw-a01 | AP | 10.2.14.166 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 75 | m1-hera-apigw-b01 | AP | 10.2.14.167 | - | - | 목동 | rocky-8.10-64bit | - | 16 | 32 |
| 76 | m1-hera-apigw-d01 | DB | 10.2.14.170 | - | - | 목동 | rocky-8.10-64bit | Mariadb 11.4.4 | 8 | 16 |
| 83 | m1-hera-comm-a01 | AP | 10.2.14.165 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 84 | m1-hera-comm-d01 | DB | 10.2.14.169 | - | - | 목동 | rocky-8.10-64bit | Mariadb 11.4.4 | 8 | 16 |
| 91 | m1-hera-comm-w01 | WEB | 10.2.14.163 | - | - | 목동 | rocky-8.10-64bit | - | 2 | 4 |
| 156 | ys-hera-gapigw-a01 | AP | 10.48.220.162 | - | - | 용산 | rocky-8.10-64bit | - | 4 | 8 |
| 157 | ys-hera-gapigw-b01 | AP | 10.48.220.163 | - | - | 용산 | rocky-8.10-64bit | - | 16 | 32 |
| 158 | ys-hera-gapigw-d01 | DB | 10.48.220.164 | - | - | 용산 | rocky-8.10-64bit | Mariadb 11.4.2 Mariadb 11.4.4 | 8 | 16 |
| 196 | m1-hera-apigw-a03 | AP | 10.0.1.36 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 197 | m1-hera-apigw-b03 | AP | 10.0.1.37 | - | - | 목동 | rocky-8.10-64bit | - | 16 | 32 |
| 198 | m1-hera-apigw-d03 | DB | 10.0.1.38 | - | - | 목동 | rocky-8.10-64bit | Mariadb 11.4.4 | 8 | 16 |

## Cloudbot

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 194 | dev-coa | AP/DB | 10.0.1.144 | - | - | 목동 | centos-6.3-64bit | Mysql 14.14 | 8 | 16 |

## 기타

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 62 | m1-gaia-dev-ansible-a01 | AP | 10.2.14.160 | - | - | 목동 | rocky-8.10-64bit | - | 32 | 96 |
| 63 | m1-gaia-dev-ansible-p01 | AP | 10.2.14.158 | - | - | 목동 | rocky-8.10-64bit | - | 2 | 8 |
| 64 | - | AP | 10.2.14.159 | - | - | 목동 | rocky-8.10-64bit | - | 2 | 8 |
| 65 | m1-gaia-dev-ansible-w01 | WEB | 10.2.14.157 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 94 | m1-jpt-com-git-01 | AP | 10.2.14.228 | - | - | 목동 | centos-7.9-64bit | - | 4 | 8 |
| 148 | m1-ops-com-git-01 | AP | 10.2.14.229 | - | - | 목동 | centos-7.9-64bit | - | 4 | 8 |
