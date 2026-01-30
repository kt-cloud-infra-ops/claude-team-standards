# Luppiter DB 복구 절차 - 신규 DB 서버

## 개요

| 항목 | 내용 |
|------|------|
| 시나리오 | 신규 서버에 PostgreSQL 설치 및 데이터 복구 |
| 대상 OS | Rocky Linux 9 |
| PostgreSQL 버전 | 16.x |
| 백업 원본 버전 | PostgreSQL 13.5 |
| 백업 방식 | pg_dump (스키마/데이터/메타 분리) |
| 작성일 | 2026-01-30 |

---

## 접속 정보 (복구 후)

### DB 사용자

| Username | Password | 권한 |
|----------|----------|------|
| luppiter | Dbvlxpfm!1 | 전체 (테이블 소유자) |
| ktcmon | zmffkdnem3# | 전체 |
| luppiter_admin | zmffkdnem3# | 전체 |
| luppiter_user | zmffkdnem3# | 조회만 (SELECT) |

---

## Step 1. SSH로 신규 서버 접속

```bash
ssh root@<NEW_SERVER_IP>
# Password: <ROOT_PASSWORD>
```

---

## Step 2. PostgreSQL 16 설치 (Rocky Linux 9)

```bash
# PostgreSQL 공식 저장소 추가
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-aarch64/pgdg-redhat-repo-latest.noarch.rpm

# 기본 PostgreSQL 모듈 비활성화
dnf -qy module disable postgresql

# PostgreSQL 16 설치
dnf install -y postgresql16-server postgresql16
```

---

## Step 3. PostgreSQL 초기화 및 시작

```bash
# 데이터베이스 초기화
/usr/pgsql-16/bin/postgresql-16-setup initdb

# 서비스 활성화 및 시작
systemctl enable postgresql-16
systemctl start postgresql-16

# 상태 확인
systemctl status postgresql-16
```

**예상 결과:**
```
● postgresql-16.service - PostgreSQL 16 database server
     Loaded: loaded (/usr/lib/systemd/system/postgresql-16.service; enabled)
     Active: active (running)
```

---

## Step 4. PostgreSQL 원격 접속 설정

### pg_hba.conf 수정

```bash
vi /var/lib/pgsql/16/data/pg_hba.conf
```

파일 맨 아래에 추가:
```
host    all             all             0.0.0.0/0               md5
```

### postgresql.conf 수정

```bash
vi /var/lib/pgsql/16/data/postgresql.conf
```

아래 설정 변경:
```
listen_addresses = '*'
```

### PostgreSQL 재시작

```bash
systemctl restart postgresql-16
```

---

## Step 5. 방화벽 설정

```bash
# PostgreSQL 포트 허용
firewall-cmd --add-port=5432/tcp --permanent
firewall-cmd --reload

# 확인
firewall-cmd --list-ports
```

**예상 결과:**
```
5432/tcp
```

---

## Step 6. 데이터베이스 및 사용자 생성

```bash
# postgres 사용자로 전환하여 psql 실행
sudo -u postgres psql
```

```sql
-- 데이터베이스 생성
CREATE DATABASE ktcmon WITH ENCODING 'UTF8' LC_COLLATE = 'C' LC_CTYPE = 'C' TEMPLATE template0;

-- 사용자 생성
CREATE ROLE luppiter WITH LOGIN PASSWORD 'Dbvlxpfm!1' CREATEDB CREATEROLE;
CREATE ROLE ktcmon WITH LOGIN PASSWORD 'zmffkdnem3#';
CREATE ROLE luppiter_admin WITH LOGIN PASSWORD 'zmffkdnem3#';
CREATE ROLE luppiter_user WITH LOGIN PASSWORD 'zmffkdnem3#';

-- 데이터베이스 소유권 변경
ALTER DATABASE ktcmon OWNER TO luppiter;

-- 종료
\q
```

---

## Step 7. 백업 파일 준비

```bash
# 백업 파일 다운로드 (Git clone)
cd /tmp
git clone <백업_저장소_URL> backup_repo
cd backup_repo

# 압축 해제
tar -xzf backup_luppiter_db_YYYYMMDD.tar.gz

# 파일 확인
ls -la archive/
```

**예상 결과:**
```
-rw-r--r-- 1 root root  xxx backup_luppiter_schema_YYYYMMDD.dump
-rw-r--r-- 1 root root  xxx backup_luppiter_data_YYYYMMDD.dump
-rw-r--r-- 1 root root  xxx backup_luppiter_meta_YYYYMMDD.dump
```

---

## Step 8. 스키마 복구

```bash
# .pgpass 설정
echo '<NEW_SERVER_IP>:5432:ktcmon:luppiter:Dbvlxpfm!1' > ~/.pgpass
chmod 600 ~/.pgpass

# agent_message 제외한 스키마 복구
grep -v "agent_message" /tmp/backup_repo/archive/backup_luppiter_schema_YYYYMMDD.dump > /tmp/schema_filtered.dump

psql -h <NEW_SERVER_IP> -p 5432 -U luppiter -d ktcmon -f /tmp/schema_filtered.dump
```

---

## Step 9. 데이터 복구

```bash
# agent_message 제외한 데이터 복구
grep -v "agent_message" /tmp/backup_repo/archive/backup_luppiter_data_YYYYMMDD.dump > /tmp/data_filtered.dump

psql -h <NEW_SERVER_IP> -p 5432 -U luppiter -d ktcmon -f /tmp/data_filtered.dump
```

**소요 시간:** 약 10분 (데이터 크기에 따라 변동)

---

## Step 10. 권한 부여

```bash
sudo -u postgres psql -d ktcmon << 'EOF'
-- 스키마 권한
GRANT ALL ON SCHEMA public TO luppiter, luppiter_admin, ktcmon;
GRANT USAGE ON SCHEMA public TO luppiter_user;

-- 테이블 권한 (전체)
GRANT ALL ON ALL TABLES IN SCHEMA public TO luppiter, luppiter_admin, ktcmon;
-- 테이블 권한 (조회만)
GRANT SELECT ON ALL TABLES IN SCHEMA public TO luppiter_user;

-- 시퀀스 권한 (전체)
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO luppiter, luppiter_admin, ktcmon;
-- 시퀀스 권한 (조회만)
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO luppiter_user;
EOF
```

---

## Step 11. 복구 검증

### 테이블 수 확인

```bash
psql -h <NEW_SERVER_IP> -p 5432 -U luppiter -d ktcmon -c "
SELECT count(*) as table_count
FROM information_schema.tables
WHERE table_schema = 'public';"
```

**예상 결과:** 87개

### 주요 테이블 데이터 확인

```bash
psql -h <NEW_SERVER_IP> -p 5432 -U luppiter -d ktcmon -c "
SELECT 'cmon_event_info' as tbl, count(*) FROM cmon_event_info
UNION ALL SELECT 'cmon_user', count(*) FROM cmon_user
UNION ALL SELECT 'inventory_master', count(*) FROM inventory_master
ORDER BY 1;"
```

### 사용자 접속 테스트

```bash
# ktcmon 테스트
echo '<NEW_SERVER_IP>:5432:ktcmon:ktcmon:zmffkdnem3#' > ~/.pgpass && chmod 600 ~/.pgpass
psql -h <NEW_SERVER_IP> -p 5432 -U ktcmon -d ktcmon -c "SELECT 1 as test;"

# luppiter_admin 테스트
echo '<NEW_SERVER_IP>:5432:ktcmon:luppiter_admin:zmffkdnem3#' > ~/.pgpass && chmod 600 ~/.pgpass
psql -h <NEW_SERVER_IP> -p 5432 -U luppiter_admin -d ktcmon -c "SELECT 1 as test;"

# luppiter_user 테스트
echo '<NEW_SERVER_IP>:5432:ktcmon:luppiter_user:zmffkdnem3#' > ~/.pgpass && chmod 600 ~/.pgpass
psql -h <NEW_SERVER_IP> -p 5432 -U luppiter_user -d ktcmon -c "SELECT 1 as test;"
```

---

## 애플리케이션 설정 변경

### 1. application.properties 수정

```properties
# DB 접속 정보 변경
spring.datasource.hikari.jdbc-url=jdbc:log4jdbc:postgresql://<NEW_SERVER_IP>:5432/ktcmon?charSet=UTF-8
spring.datasource.hikari.username=luppiter
spring.datasource.hikari.password=ENC(암호화된비밀번호)
```

### 2. PostgreSQL 16 호환성 이슈 수정

**문제:** PostgreSQL 13 → 16 업그레이드 시 SQL 구문 호환성 문제

**원인:** `CAST(#{pageNo}AS INTEGER)`에서 `}`와 `AS` 사이에 공백 없음

**해결:**
```bash
cd /path/to/luppiter_web/src/main/resources/sqlmap

# 영향받는 파일들의 패턴 수정
sed -i '' 's/}AS INTEGER/} AS INTEGER/g' sql-ctl.xml sql-evt.xml sql-icd.xml sql-stt.xml

# 확인
grep -rn "}AS INTEGER" *.xml  # 결과 없어야 정상
```

### 3. 애플리케이션 재빌드 및 배포

```bash
mvn clean package -DskipTests
# WAR 파일 배포
```

---

## 최종 확인 체크리스트

### DB 서버

- [ ] PostgreSQL 서비스 정상 실행
- [ ] 원격 접속 가능 (5432 포트)
- [ ] 방화벽 설정 완료

### 데이터

- [ ] 테이블 수 확인 (87개)
- [ ] cmon_event_info: ~47만건
- [ ] cmon_user: ~250건
- [ ] inventory_master: ~1.6만건

### 권한

- [ ] luppiter: 전체 권한
- [ ] ktcmon: 전체 권한
- [ ] luppiter_admin: 전체 권한
- [ ] luppiter_user: SELECT만

### 애플리케이션

- [ ] DB 접속 정보 변경
- [ ] SQL 호환성 수정
- [ ] 재빌드 및 배포
- [ ] 주요 화면 정상 조회

---

## 트러블슈팅

### PostgreSQL 설치 실패

```bash
# 저장소 확인
dnf repolist

# 캐시 초기화
dnf clean all
dnf makecache
```

### 원격 접속 불가

```bash
# pg_hba.conf 확인
cat /var/lib/pgsql/16/data/pg_hba.conf | grep -v "^#" | grep -v "^$"

# postgresql.conf 확인
grep listen_addresses /var/lib/pgsql/16/data/postgresql.conf

# 방화벽 확인
firewall-cmd --list-all
```

### 권한 오류

```bash
# postgres 슈퍼유저로 권한 재부여
sudo -u postgres psql -d ktcmon -c "
GRANT ALL ON ALL TABLES IN SCHEMA public TO luppiter;"
```

### 데이터 복구 실패

```bash
# 에러 로그 확인
tail -100 /var/lib/pgsql/16/data/log/postgresql-*.log

# 특정 테이블만 복구
grep "INSERT INTO public.테이블명 " backup_luppiter_data_*.dump | \
psql -h <NEW_SERVER_IP> -p 5432 -U luppiter -d ktcmon
```

---

## 주의사항

### 제외 테이블

| 테이블 | 제외 사유 |
|--------|----------|
| agent_message | 실시간 에이전트 메시지, 복구 불필요 |

### 특수문자 비밀번호 처리

비밀번호에 `!` 등 특수문자가 있으면 환경변수(`PGPASSWORD`)로 전달 시 문제 발생.

**해결:** `.pgpass` 파일 사용
```bash
echo 'host:port:database:username:password' > ~/.pgpass
chmod 600 ~/.pgpass
```

---

**최종 업데이트**: 2026-01-30
