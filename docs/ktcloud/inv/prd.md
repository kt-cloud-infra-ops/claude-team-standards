# PRD Environment Inventory

> Source: [Confluence - PRD](https://ktcloud.atlassian.net/wiki/spaces/CL23/pages/952010073)
> 동기화일: 2026-02-09
> 서버 수: 195대

## 통합Dashboard

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 24 | m1-jpt-prd-kmon-a01 | AP | 172.25.1.130 | - | 10.221.45.114 | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 25 | m1-jpt-prd-kmon-a01 | AP | 172.25.1.13 | - | 10.230.7.115 | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 26 | m1-jpt-prd-kmon-a02 | AP | 172.25.1.174 | - | 10.221.45.115 | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 27 | m1-jpt-prd-kmon-a02 | AP | 172.25.1.14 | - | 10.230.7.116 | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 28 | m1-jpt-prd-kmon-w01 | WEB | 172.25.0.103 | - | 10.221.45.118 | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 29 | m1-jpt-prd-kmon-w01 | WEB | 172.25.0.11 | - | 10.230.7.113 | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 30 | m1-jpt-prd-kmon-w02 | WEB | 172.25.0.59 | - | 10.221.45.119 | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 31 | m1-jpt-prd-kmon-w02 | WEB | 172.25.0.12 | - | 10.230.7.114 | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 97 | m1-jpt-prd-hap-a01 | LB | 10.2.14.144 | - | - | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 98 | m1-jpt-prd-hap-a02 | LB | 10.2.14.145 | - | - | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 99 | m1-jpt-prd-hap-a03 | LB | 10.2.14.161 | - | - | 목동 | centos-7.9-64bit | - | 4 | 8 |
| 100 | m1-jpt-prd-hap-a04 | LB | 10.2.14.162 | - | - | 목동 | centos-7.9-64bit | - | 4 | 8 |
| 101 | m1-jpt-prd-mon-a01 | AP | 10.2.14.103 | - | - | 목동 | centos-7.9-64bit | - | 8 | 16 |
| 102 | m1-jpt-prd-mon-a02 | AP | 10.2.14.104 | - | - | 목동 | centos-7.9-64bit | - | 8 | 16 |
| 103 | m1-jpt-prd-mon-a03 | AP | 10.2.14.107 | - | - | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 104 | m1-jpt-prd-mon-a04 | AP | 10.2.14.108 | - | - | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 105 | m1-jpt-prd-mon-a05 | AP | 10.2.14.205 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 106 | m1-jpt-prd-mon-a06 | AP | 10.2.14.206 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 107 | m1-jpt-prd-mon-d01 | DB | 10.2.14.105 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 16 | 32 |
| 108 | m1-jpt-prd-mon-d02 | DB | 10.2.14.106 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 16 | 32 |
| 109 | m1-jpt-prd-mon-w01 | WEB | 10.2.14.101 | - | - | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 110 | m1-jpt-prd-mon-w02 | WEB | 10.2.14.102 | - | - | 목동 | centos-7.9-64bit | - | 4 | 4 |

## ZabbixServer

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 113 | m1-jpt-prd-zab-a01 | AP | 10.2.14.111 | - | - | 목동 | centos-7.9-64bit | - | 16 | 16 |
| 114 | m1-jpt-prd-zab-a02 | AP | 10.2.14.112 | - | - | 목동 | centos-7.9-64bit | - | 16 | 16 |
| 115 | m1-jpt-prd-zab-a03 | AP | 10.2.14.117 | - | - | 목동 | centos-7.9-64bit | - | 16 | 32 |
| 116 | m1-jpt-prd-zab-a04 | AP | 10.2.14.118 | - | - | 목동 | centos-7.9-64bit | - | 16 | 16 |
| 117 | m1-jpt-prd-zab-a05 | AP | 10.2.14.211 | - | - | 목동 | rocky-8.10-64bit | - | 8 | 16 |
| 118 | m1-jpt-prd-zab-a06 | AP | 10.2.14.212 | - | - | 목동 | rocky-8.10-64bit | - | 8 | 16 |
| 119 | m1-jpt-prd-zab-d01 | DB | 10.2.14.113 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 MariaDB 10.5.16 | 16 | 32 |
| 120 | m1-jpt-prd-zab-d02 | DB | 10.2.14.114 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 16 | 32 |
| 121 | m1-jpt-prd-zab-d03 | DB | 10.2.14.119 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 16 | 32 |
| 122 | m1-jpt-prd-zab-d04 | DB | 10.2.14.120 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 16 | 32 |
| 123 | m1-jpt-prd-zab-d05 | DB | 10.2.14.135 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 16 |
| 124 | m1-jpt-prd-zab-d06 | DB | 10.2.14.136 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 16 |
| 125 | m1-jpt-prd-zab-d07 | DB | 10.2.14.129 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 16 |
| 126 | m1-jpt-prd-zab-d08 | DB | 10.2.14.130 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 16 |
| 127 | m1-jpt-prd-zab-d09 | DB | 10.2.14.214 | - | - | 목동 | rocky-8.10-64bit | PostgreSQL 15.8 | 16 | 32 |
| 128 | m1-jpt-prd-zab-d10 | DB | 10.2.14.215 | - | - | 목동 | rocky-8.10-64bit | PostgreSQL 15.8 | 16 | 32 |
| 139 | m1-jpt-prd-zab-w01 | WEB | 10.2.14.109 | - | - | 목동 | centos-7.9-64bit | - | 4 | 8 |
| 140 | m1-jpt-prd-zab-w02 | WEB | 10.2.14.110 | - | - | 목동 | centos-7.9-64bit | - | 4 | 8 |
| 141 | m1-jpt-prd-zab-w03 | WEB | 10.2.14.115 | - | - | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 142 | m1-jpt-prd-zab-w04 | WEB | 10.2.14.116 | - | - | 목동 | centos-7.9-64bit | - | 4 | 4 |
| 143 | m1-jpt-prd-zab-w05 | WEB | 10.2.14.208 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 144 | m1-jpt-prd-zab-w06 | WEB | 10.2.14.209 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 218 | ca-jpt-prd-zab-a01 | AP | 10.0.8.223 | - | - | 천안 | centos-7.9-64bit | - | 4 | 8 |
| 219 | ca-jpt-prd-zab-a02 | AP | 10.0.8.224 | - | - | 천안 | centos-7.9-64bit | - | 4 | 8 |
| 220 | ca-jpt-prd-zab-d01 | DB | 10.0.8.191 | - | - | 천안 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 16 |
| 221 | ca-jpt-prd-zab-d02 | DB | 10.0.8.192 | - | - | 천안 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 16 |
| 222 | ca-jpt-prd-zab-d03 | DB | 10.0.8.197 | - | - | 천안 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 16 |
| 223 | ca-jpt-prd-zab-d04 | DB | 10.0.8.198 | - | - | 천안 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 16 |
| 224 | ca-jpt-prd-zab-d05 | DB | 10.0.8.225 | - | - | 천안 | centos-7.9-64bit | PostgreSQL 13.5 | 4 | 8 |
| 225 | ca-jpt-prd-zab-d06 | DB | 10.0.8.226 | - | - | 천안 | centos-7.9-64bit | PostgreSQL 13.5 | 4 | 8 |
| 240 | ca-jpt-prd-zab-w01 | WEB | 10.0.8.221 | - | - | 천안 | centos-7.9-64bit | - | 4 | 8 |
| 241 | ca-jpt-prd-zab-w02 | WEB | 10.0.8.222 | - | - | 천안 | centos-7.9-64bit | - | 4 | 8 |

## ZabbixProxy

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 4 | m1-jpt-prd-d1zab-a01 | AP | 172.25.1.34 | - | 10.230.9.59 | 목동 | centos-7.9-64bit | - | 8 | 16 |
| 5 | m1-jpt-prd-d1zab-a01 | AP | 172.25.1.53 | - | 10.230.7.83 | 목동 | rocky-8.10-64bit | - | 8 | 16 |
| 6 | m1-jpt-prd-d1zab-a02 | AP | 172.25.1.35 | - | 10.230.9.60 | 목동 | centos-7.9-64bit | - | 8 | 16 |
| 7 | m1-jpt-prd-d1zab-a02 | AP | 172.25.1.54 | - | 10.230.7.84 | 목동 | rocky-8.10-64bit | - | 8 | 16 |
| 8 | m1-jpt-prd-d1zab-d01 | DB | 172.25.1.37 | - | 10.230.9.61 | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 16 | 32 |
| 9 | m1-jpt-prd-d1zab-d01 | DB | 172.25.1.55 | - | 10.230.7.85 | 목동 | rocky-8.10-64bit | PostgreSQL 16.9 | 16 | 32 |
| 10 | m1-jpt-prd-d1zab-d02 | DB | 172.25.1.38 | - | 10.230.9.62 | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 16 | 32 |
| 11 | m1-jpt-prd-d1zab-d02 | DB | 172.25.1.56 | - | 10.230.7.86 | 목동 | rocky-8.10-64bit | PostgreSQL 16.9 | 16 | 32 |
| 12 | m1-jpt-prd-d1zab-p01 | AP | 172.25.1.23 | - | 10.221.45.116 | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 13 | m1-jpt-prd-d1zab-p01 | AP | 172.25.1.57 | - | 10.230.7.87 | 목동 | rocky-8.10-64bit | - | 8 | 8 |
| 14 | m1-jpt-prd-d1zab-p02 | AP | 172.25.1.89 | - | 10.221.45.117 | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 15 | m1-jpt-prd-d1zab-p02 | AP | 172.25.1.58 | - | 10.230.7.88 | 목동 | rocky-8.10-64bit | - | 8 | 8 |
| 16 | m1-jpt-prd-d1zab-pd01 | DB | 172.25.1.166 | - | 10.221.45.122 | 목동 | centos-7.9-64bit | POstgreSQL 13.5 | 8 | 16 |
| 17 | m1-jpt-prd-d1zab-pd01 | DB | 172.25.1.59 | - | 10.230.7.89 | 목동 | rocky-8.10-64bit | PostgreSQL 16.9 | 8 | 16 |
| 18 | m1-jpt-prd-d1zab-pd02 | DB | 172.25.1.24 | - | 10.221.45.123 | 목동 | centos-7.9-64bit | POstgreSQL 13.5 | 8 | 16 |
| 19 | m1-jpt-prd-d1zab-pd02 | DB | 172.25.1.60 | - | 10.230.7.90 | 목동 | rocky-8.10-64bit | PostgreSQL 16.9 | 8 | 16 |
| 20 | m1-jpt-prd-d1zab-w01 | WEB | 172.25.1.31 | - | 10.230.9.57 | 목동 | centos-7.9-64bit | - | 4 | 8 |
| 21 | m1-jpt-prd-d1zab-w01 | WEB | 172.25.1.51 | - | 10.230.7.81 | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 22 | m1-jpt-prd-d1zab-w02 | WEB | 172.25.1.32 | - | 10.230.9.58 | 목동 | centos-7.9-64bit | - | 4 | 8 |
| 23 | m1-jpt-prd-d1zab-w02 | WEB | 172.25.1.52 | - | 10.230.7.82 | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 41 | ca-jpt-prd-gzab-p01 | AP | 10.48.0.43 | - | - | 천안 | rocky-8.10-64bit | - | 8 | 8 |
| 42 | ca-jpt-prd-gzab-p02 | AP | 10.48.0.46 | - | - | 천안 | rocky-8.10-64bit | - | 8 | 8 |
| 43 | ca-jpt-prd-gzab-p03 | AP | 10.48.0.47 | - | - | 천안 | rocky-8.10-64bit | - | 8 | 8 |
| 44 | ca-jpt-prd-gzab-p04 | AP | 10.48.0.48 | - | - | 천안 | rocky-8.10-64bit | - | 8 | 8 |
| 45 | ca-jpt-prd-gzab-pd01 | DB | 10.48.0.60 | - | - | 천안 | rocky-8.10-64bit | PostgreSQL 16.9 | 8 | 16 |
| 46 | ca-jpt-prd-gzab-pd01 | DB | 10.48.0.49 | - | - | 천안 | rocky-8.10-64bit | PostgreSQL 13.5 | 8 | 16 |
| 47 | ca-jpt-prd-gzab-pd02 | DB | 10.48.0.61 | - | - | 천안 | rocky-8.10-64bit | PostgreSQL 16.9 | 8 | 16 |
| 48 | ca-jpt-prd-gzab-pd02 | DB | 10.48.0.54 | - | - | 천안 | rocky-8.10-64bit | PostgreSQL 13.5 | 8 | 16 |
| 95 | m1-jpt-prd-zab-pd09 | DB | 10.2.14.187 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 16 |
| 96 | m1-jpt-prd-zab-pd10 | DB | 10.2.14.188 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 16 |
| 129 | m1-jpt-prd-zab-p01 | AP | 10.2.14.121 | - | - | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 130 | m1-jpt-prd-zab-p02 | AP | 10.2.14.122 | - | - | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 131 | m1-jpt-prd-zab-p03 | AP | 10.2.14.123 | - | - | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 132 | m1-jpt-prd-zab-p04 | AP | 10.2.14.124 | - | - | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 133 | m1-jpt-prd-zab-p05 | AP | 10.2.14.125 | - | - | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 134 | m1-jpt-prd-zab-p06 | AP | 10.2.14.126 | - | - | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 135 | m1-jpt-prd-zab-p07 | AP | 10.2.14.127 | - | - | 목동 | centos-7.9-64bit | - | 8 | 16 |
| 136 | m1-jpt-prd-zab-p08 | AP | 10.2.14.128 | - | - | 목동 | centos-7.9-64bit | - | 8 | 16 |
| 137 | m1-jpt-prd-zab-p09 | AP | 10.2.14.185 | - | - | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 138 | m1-jpt-prd-zab-p10 | AP | 10.2.14.186 | - | - | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 171 | ys-jpt-prd-gzab-a01 | AP | 172.27.1.20 | - | 10.48.219.72 | 용산 | rocky-8.10-64bit | - | 16 | 16 |
| 172 | ys-jpt-prd-gzab-a02 | AP | 172.27.1.89 | - | 10.48.219.73 | 용산 | rocky-8.10-64bit | - | 16 | 16 |
| 173 | ys-jpt-prd-gzab-d01 | DB | 172.27.1.85 | - | 10.48.219.74 | 용산 | rocky-8.10-64bit | PostgreSQL 16.9 | 16 | 32 |
| 174 | ys-jpt-prd-gzab-d01 | DB | 172.27.1.49 | - | 10.48.219.90 | 용산 | rocky-8.10-64bit | PostgreSQL 13.5 | 16 | 32 |
| 175 | ys-jpt-prd-gzab-d02 | DB | 172.27.1.60 | - | 10.48.219.75 | 용산 | rocky-8.10-64bit | PostgreSQL 16.9 | 16 | 32 |
| 176 | ys-jpt-prd-gzab-d02 | DB | 172.27.1.38 | - | 10.48.219.91 | 용산 | rocky-8.10-64bit | PostgreSQL 13.5 | 16 | 32 |
| 177 | ys-jpt-prd-gzab-p01 | AP | 172.27.1.39 | - | 10.48.219.76 | 용산 | rocky-8.10-64bit | - | 8 | 8 |
| 178 | ys-jpt-prd-gzab-p02 | AP | 172.27.1.74 | - | 10.48.219.77 | 용산 | rocky-8.10-64bit | - | 8 | 8 |
| 179 | ys-jpt-prd-gzab-p03 | AP | 172.27.1.55 | - | 10.48.219.78 | 용산 | rocky-8.10-64bit | - | 8 | 8 |
| 180 | ys-jpt-prd-gzab-p04 | AP | 172.27.1.52 | - | 10.48.219.79 | 용산 | rocky-8.10-64bit | - | 8 | 8 |
| 181 | ys-jpt-prd-gzab-pd01 | DB | 172.27.1.58 | - | 10.48.219.80 | 용산 | rocky-8.10-64bit | PostgreSQL 16.9 | 8 | 16 |
| 182 | - | DB | 172.27.1.4 | - | - | 용산 | rocky-8.10-64bit | - | 8 | 16 |
| 183 | ys-jpt-prd-gzab-pd02 | DB | 172.27.1.86 | - | 10.48.219.81 | 용산 | rocky-8.10-64bit | PostgreSQL 16.9 | 8 | 16 |
| 184 | - | DB | 172.27.1.47 | - | - | 용산 | rocky-8.10-64bit | - | 8 | 16 |
| 185 | - | AP | 172.27.1.64 | - | - | 용산 | rocky-8.10-64bit | - | 4 | 4 |
| 186 | ys-jpt-prd-gzab-w01 | WEB | 172.27.0.76 | - | 10.48.219.70 | 용산 | rocky-8.10-64bit | - | 4 | 8 |
| 187 | ys-jpt-prd-gzab-w02 | WEB | 172.27.0.82 | - | 10.48.219.71 | 용산 | rocky-8.10-64bit | - | 4 | 8 |
| 188 | ys-jpt-prd-hap-a01 | LB | 172.27.0.73 | - | 10.48.219.68 | 용산 | rocky-8.10-64bit | - | 4 | 4 |
| 189 | ys-jpt-prd-hap-a02 | LB | 172.27.0.18 | - | 10.48.219.69 | 용산 | rocky-8.10-64bit | - | 4 | 4 |
| 191 | ys-jpt-prd-url-p01 | AP | 10.48.224.137 | - | - | 용산 | rocky-8.10-64bit | sqlite-3.26.0-19 | 8 | 8 |
| 192 | ys-jpt-prd-url-p02 | AP | 10.48.224.147 | - | - | 용산 | rocky-8.10-64bit | sqlite-3.26.0-19 | 8 | 8 |
| 216 | ca-jpt-prd-hap-a01 | LB | 10.0.8.199 | - | - | 천안 | centos-7.9-64bit | - | 8 | 8 |
| 217 | ca-jpt-prd-hap-a02 | LB | 10.0.8.206 | - | - | 천안 | centos-7.9-64bit | - | 8 | 8 |
| 226 | ca-jpt-prd-zab-log01 | AP | 10.0.8.119 | - | - | 천안 | rocky-8.10-64bit | - | 8 | 8 |
| 227 | ca-jpt-prd-zab-log02 | AP | 10.0.8.120 | - | - | 천안 | rocky-8.10-64bit | - | 8 | 8 |
| 228 | ca-jpt-prd-zab-p01 | AP | 10.0.8.186 | - | - | 천안 | centos-7.9-64bit | - | 8 | 8 |
| 229 | ca-jpt-prd-zab-p02 | AP | 10.0.8.187 | - | - | 천안 | centos-7.9-64bit | - | 8 | 8 |
| 230 | ca-jpt-prd-zab-p03 | AP | 10.0.8.188 | - | - | 천안 | centos-7.9-64bit | - | 8 | 8 |
| 231 | ca-jpt-prd-zab-p04 | AP | 10.0.8.189 | - | - | 천안 | centos-7.9-64bit | - | 8 | 8 |
| 232 | ca-jpt-prd-zab-p05 | AP | 10.0.8.193 | - | - | 천안 | centos-7.9-64bit | - | 8 | 8 |
| 233 | ca-jpt-prd-zab-p06 | AP | 10.0.8.194 | - | - | 천안 | centos-7.9-64bit | - | 8 | 8 |
| 234 | ca-jpt-prd-zab-p07 | AP | 10.0.8.195 | - | - | 천안 | centos-7.9-64bit | - | 16 | 16 |
| 235 | ca-jpt-prd-zab-p08 | AP | 10.0.8.196 | - | - | 천안 | centos-7.9-64bit | - | 8 | 8 |
| 236 | ca-jpt-prd-zab-p09 | AP | 10.0.8.115 | - | - | 천안 | rocky-8.10-64bit | - | 16 | 16 |
| 237 | ca-jpt-prd-zab-p10 | AP | 10.0.8.116 | - | - | 천안 | rocky-8.10-64bit | - | 16 | 16 |
| 238 | ca-jpt-prd-zab-pd07 | DB | 10.0.8.117 | - | - | 천안 | rocky-8.10-64bit | PostgreSQL 15.8 | 8 | 16 |
| 239 | ca-jpt-prd-zab-pd08 | DB | 10.0.8.118 | - | - | 천안 | rocky-8.10-64bit | PostgreSQL 15.8 | 8 | 16 |
| 259 | BD-JPT-PRD-ZAB-P01 | AP | 172.31.187.240 | - | - | 분당 | centos-7.9-64bit | - | 8 | 8 |
| 260 | BD-JPT-PRD-ZAB-P03 | AP | 172.31.187.244 | - | - | 분당 | centos-7.9-64bit | - | 8 | 8 |
| 261 | BD-JPT-PRD-ZAB-D01 | DB | 172.31.187.242 | - | - | 분당 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 8 |
| 262 | BD-JPT-PRD-ZAB-D03 | DB | 172.31.187.246 | - | - | 분당 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 8 |

## HERA

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 77 | m1-hera-apigw-prd-a01 | AP | 10.2.14.194 | - | - | 목동 | rocky-8.10-64bit | - | 16 | 16 |
| 78 | m1-hera-apigw-prd-a02 | AP | 10.2.14.195 | - | - | 목동 | rocky-8.10-64bit | - | 16 | 16 |
| 79 | m1-hera-apigw-prd-b01 | AP | 10.2.14.198 | - | - | 목동 | rocky-8.10-64bit | - | 32 | 32 |
| 80 | m1-hera-apigw-prd-b02 | AP | 10.2.14.200 | - | - | 목동 | rocky-8.10-64bit | - | 32 | 32 |
| 81 | m1-hera-apigw-prd-d01 | DB | 10.2.14.202 | - | - | 목동 | rocky-8.10-64bit | Mariadb 11.4.4 | 16 | 32 |
| 82 | m1-hera-apigw-prd-d02 | DB | 10.2.14.203 | - | - | 목동 | rocky-8.10-64bit | Mariadb 11.4.4 | 16 | 32 |
| 85 | m1-hera-comm-prd-a01 | AP | 10.2.14.183 | - | - | 목동 | rocky-8.10-64bit | - | 8 | 16 |
| 86 | m1-hera-comm-prd-a02 | AP | 10.2.14.184 | - | - | 목동 | rocky-8.10-64bit | - | 8 | 16 |
| 87 | m1-hera-comm-prd-d01 | DB | 10.2.14.191 | - | - | 목동 | rocky-8.10-64bit | Mariadb 11.4.4 | 16 | 16 |
| 88 | m1-hera-comm-prd-d02 | DB | 10.2.14.192 | - | - | 목동 | rocky-8.10-64bit | Mariadb 11.4.4 | 16 | 16 |
| 89 | m1-hera-comm-prd-w01 | WEB | 10.2.14.178 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 16 |
| 90 | m1-hera-comm-prd-w02 | WEB | 10.2.14.180 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 16 |
| 92 | m1-hera-hap-prd-a01 | LB | 10.2.14.59 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 93 | m1-hera-hap-prd-a02 | LB | 10.2.14.174 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 159 | ys-hera-gapigw-prd-a01 | AP | 10.48.220.194 | - | - | 용산 | rocky-8.10-64bit | - | 16 | 16 |
| 160 | ys-hera-gapigw-prd-a02 | AP | 10.48.220.195 | - | - | 용산 | rocky-8.10-64bit | - | 16 | 16 |
| 161 | ys-hera-gapigw-prd-b01 | AP | 10.48.220.197 | - | - | 용산 | rocky-8.10-64bit | - | 32 | 32 |
| 162 | ys-hera-gapigw-prd-b02 | AP | 10.48.220.198 | - | - | 용산 | rocky-8.10-64bit | - | 32 | 32 |
| 163 | ys-hera-gapigw-prd-d01 | DB | 10.48.220.200 | - | - | 용산 | rocky-8.10-64bit | Mariadb 11.4.4 | 16 | 32 |
| 164 | ys-hera-gapigw-prd-d02 | DB | 10.48.220.201 | - | - | 용산 | rocky-8.10-64bit | Mariadb 11.4.4 | 16 | 32 |
| 210 | ca-hera-apigw-prd-a03 | AP | 10.0.8.51 | - | - | 천안 | rocky-8.10-64bit | - | 16 | 16 |
| 211 | ca-hera-apigw-prd-a04 | AP | 10.0.8.52 | - | - | 천안 | rocky-8.10-64bit | - | 16 | 16 |
| 212 | ca-hera-apigw-prd-b03 | AP | 10.0.8.53 | - | - | 천안 | rocky-8.10-64bit | - | 32 | 32 |
| 213 | ca-hera-apigw-prd-b04 | AP | 10.0.8.54 | - | - | 천안 | rocky-8.10-64bit | - | 32 | 32 |
| 214 | ca-hera-apigw-prd-d03 | DB | 10.0.8.55 | - | - | 천안 | rocky-8.10-64bit | Mariadb 11.4.4 | 16 | 32 |
| 215 | ca-hera-apigw-prd-d04 | DB | 10.0.8.56 | - | - | 천안 | rocky-8.10-64bit | Mariadb 11.4.4 | 16 | 32 |

## Cloudbot

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 195 | hub | AP/DB | 10.0.1.253 | - | - | 목동 | centos-6.2-64bit | Mysql 14.14 | 8 | 16 |

## 기타

| # | hostname | 기능 | MgmtIP | ServiceIP | VIP/NATIP | 센터 | OS | DB | CPU | MEM |
|---|----------|------|--------|-----------|-----------|------|----|----|----|-----|
| 40 | ca-gaia-prd-ansible-ep01 | AP | 10.48.0.129 | - | - | 천안 | rocky-8.10-64bit | - | 8 | 8 |
| 49 | m1-clb-prd-inv-d01 | DB | 10.2.14.173 | - | - | 목동 | centos-7.9-64bit | PostgreSQL 13.5 | 8 | 16 |
| 50 | m1-clb-prd-topo-a01 | AP | 10.2.14.172 | - | - | 목동 | centos-7.9-64bit | - | 4 | 8 |
| 51 | m1-gaia-ans-prd-a01 | AP | 10.2.14.97 | - | - | 목동 | rocky-8.10-64bit | - | 8 | 16 |
| 52 | m1-gaia-ans-prd-a02 | AP | 10.2.14.98 | - | - | 목동 | rocky-8.10-64bit | - | 8 | 16 |
| 53 | m1-gaia-ans-prd-a03 | AP | 10.2.14.99 | - | - | 목동 | rocky-8.10-64bit | - | 8 | 16 |
| 54 | m1-gaia-cm-prd-c01 | AP | 10.2.14.64 | - | - | 목동 | rocky-8.10-64bit | - | 16 | 32 |
| 55 | m1-gaia-cm-prd-c02 | AP | 10.2.14.65 | - | - | 목동 | rocky-8.10-64bit | - | 16 | 32 |
| 56 | m1-gaia-cm-prd-c03 | AP | 10.2.14.66 | - | - | 목동 | rocky-8.10-64bit | - | 16 | 32 |
| 57 | m1-gaia-comm-prd-d01 | DB | 10.2.14.92 | - | - | 목동 | rocky-8.10-64bit | PostgreSQL 15.14 | 32 | 64 |
| 58 | m1-gaia-comm-prd-d02 | DB | 10.2.14.93 | - | - | 목동 | rocky-8.10-64bit | PostgreSQL 15.14 | 32 | 64 |
| 59 | m1-gaia-cw-prd-c01 | AP | 10.2.14.67 | - | - | 목동 | rocky-8.10-64bit | - | 16 | 32 |
| 60 | m1-gaia-cw-prd-c02 | AP | 10.2.14.217 | - | - | 목동 | rocky-8.10-64bit | - | 16 | 32 |
| 61 | m1-gaia-cw-prd-c03 | AP | 10.2.14.218 | - | - | 목동 | rocky-8.10-64bit | - | 16 | 32 |
| 66 | m1-gaia-hap-prd-a01 | LB | 10.2.14.62 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 67 | m1-gaia-hap-prd-a02 | LB | 10.2.14.63 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 4 |
| 68 | m1-gaia-mq-prd-a01 | AP | 10.2.14.94 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 69 | m1-gaia-mq-prd-a02 | AP | 10.2.14.95 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 70 | m1-gaia-mq-prd-a03 | AP | 10.2.14.96 | - | - | 목동 | rocky-8.10-64bit | - | 4 | 8 |
| 71 | m1-gaia-prd-ansible-a02 | AP | 10.2.14.58 | - | - | 목동 | rocky-8.10-64bit | - | 12 | 16 |
| 72 | m1-gaia-prd-ansible-p01-new | AP | 10.2.14.132 | - | - | 목동 | rocky-8.10-64bit | - | 24 | 16 |
| 73 | m1-gaia-prd-ansible-p02 | AP | 10.2.14.134 | - | - | 목동 | rocky-8.10-64bit | - | 8 | 8 |
| 111 | m1-jpt-prd-pro-a01 | AP | 10.2.14.131 | - | - | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 112 | m1-jpt-prd-pro-a03 | AP | 10.2.14.133 | - | - | 목동 | centos-7.9-64bit | - | 8 | 8 |
| 152 | - | AP | 172.27.1.31 | - | - | 용산 | centos-7.9-64bit | - | 8 | 16 |
| 153 | - | AP | 172.27.1.28 | - | - | 용산 | centos-7.9-64bit | - | 8 | 16 |
| 154 | ys-gaia-prd-ansible-p01 | AP | 172.27.1.41 | - | 10.48.219.82 | 용산 | rocky-8.10-64bit | - | 8 | 16 |
| 155 | ys-gaia-prd-ansible-p02 | AP | 172.27.1.59 | - | 10.48.219.83 | 용산 | rocky-8.10-64bit | - | 8 | 16 |
| 206 | ca-cla-prd-a01 | AP | 10.0.8.44 | - | - | 천안 | centos-7.9-64bit | - | 8 | 16 |
| 207 | ca-cla-prd-d01 | DB | 10.0.8.45 | - | - | 천안 | centos-7.9-64bit | - | 16 | 32 |
| 208 | ca-gaia-prd-ansible-p01 | AP | 10.0.8.42 | - | - | 천안 | rocky-8.10-64bit | - | 12 | 20 |
| 209 | ca-gaia-prd-ansible-p02 | DB | 10.0.8.43 | - | - | 천안 | rocky-8.10-64bit | - | 16 | 32 |
| 248 | p-mon-git-01 | AP/DB | 10.4.224.36 | - | - | 천안 | centos-7.9-64bit | (gitlab) redis 7.0.14 (gitlab) PostgreSQL 13.12 | 8 | 16 |
