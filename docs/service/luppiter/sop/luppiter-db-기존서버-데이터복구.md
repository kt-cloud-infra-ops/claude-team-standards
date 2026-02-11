# Luppiter DB 복구 절차 - 기존 DB 서버

## 개요

| 항목 | 내용 |
|------|------|
| 시나리오 | 기존 PostgreSQL 서버에 데이터 복구 |
| 대상 DB | PostgreSQL 16.9 (ktcmon) |
| 백업 원본 버전 | PostgreSQL 13.5 |
| 백업 방식 | pg_dump (스키마/데이터/메타 분리) |
| 작성일 | 2026-01-30 |
| 최종 수정일 | 2026-02-04 |

---

## 접속 정보

### DB 서버

| 항목 | 값 |
|------|------|
| Host | 192.168.128.11 |
| Port | 5432 |
| Database | ktcmon |
| SSH User | root |
| SSH Password | P@ssw0rd |

### DB 사용자

| Username | Password | 권한 |
|----------|----------|------|
| luppiter | Dbvlxpfm!1 | 전체 (테이블 소유자) |
| ktcmon | zmffkdnem3# | 전체 |
| luppiter_admin | zmffkdnem3# | 전체 |
| luppiter_user | zmffkdnem3# | 조회만 (SELECT) |

---

## Step 1. 백업 파일 확인

```bash
# 백업 파일 위치 확인
ls -lah ~/Downloads/ | grep -i luppiter
```

**실행 결과:**
```
-rw-r--r--@  1 user  staff   177M Jan 30 08:48 backup_luppiter_db_20260129.tar.gz
```

---

## Step 2. 백업 파일 압축 해제

```bash
cd ~/Downloads
tar -xzf backup_luppiter_db_20260129.tar.gz -C /tmp/
```

**압축 해제 결과:**
```
/tmp/archive/backup_luppiter_schema_20260129.dump  # 스키마
/tmp/archive/backup_luppiter_data_20260129.dump    # 데이터
/tmp/archive/backup_luppiter_meta_20260129.dump    # 메타
```

---

## Step 3. PostgreSQL 접속 설정

**주의:** 비밀번호에 특수문자(!)가 있어 환경변수 방식은 실패함. `.pgpass` 파일 사용 필수.

```bash
echo '192.168.128.11:5432:ktcmon:luppiter:Dbvlxpfm!1' > ~/.pgpass
chmod 600 ~/.pgpass
```

---

## Step 4. DB 접속 테스트

```bash
psql -h 192.168.128.11 -p 5432 -U luppiter -d ktcmon -c "SELECT version();"
```

**실행 결과:**
```
                              version
----------------------------------------------------------------------------------------------------------------
 PostgreSQL 16.9 on aarch64-unknown-linux-gnu, compiled by gcc (GCC) 11.5.0 20240719 (Red Hat 11.5.0-5), 64-bit
(1 row)
```

---

## Step 5. 기존 DB 상태 확인

```bash
psql -h 192.168.128.11 -p 5432 -U luppiter -d ktcmon -c "
SELECT count(*) as table_count
FROM information_schema.tables
WHERE table_schema = 'public';"
```

**실행 결과:**
```
 table_count
-------------
          70
(1 row)
```

---

## Step 6. 기존 연결 강제 종료 (SSH 필요)

**중요:** 다른 세션이 테이블을 사용 중이면 DROP 시 데드락 발생.

```bash
expect -c '
spawn ssh -o StrictHostKeyChecking=no root@192.168.128.11
expect "password:"
send "P@ssw0rd\r"
expect "# "
send "sudo -u postgres psql -d ktcmon -c \"SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '\''ktcmon'\'' AND pid <> pg_backend_pid();\"\r"
expect "# "
send "exit\r"
expect eof
'
```

---

## Step 7. 기존 테이블 삭제 (agent_message 제외)

```bash
psql -h 192.168.128.11 -p 5432 -U luppiter -d ktcmon -c "
DO \$\$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT tablename FROM pg_tables
              WHERE schemaname = 'public'
              AND tablename <> 'agent_message') LOOP
        EXECUTE 'DROP TABLE IF EXISTS public.' || quote_ident(r.tablename) || ' CASCADE';
    END LOOP;
END \$\$;
"
```

---

## Step 8. 스키마 복구 (agent_message 제외)

```bash
# agent_message 관련 내용 제외한 스키마 파일 생성
grep -v "agent_message" /tmp/archive/backup_luppiter_schema_20260129.dump > /tmp/schema_no_agent.dump

# 스키마 복구
psql -h 192.168.128.11 -p 5432 -U luppiter -d ktcmon -f /tmp/schema_no_agent.dump
```

---

## Step 9. 테이블 생성 확인

```bash
psql -h 192.168.128.11 -p 5432 -U luppiter -d ktcmon -c "
SELECT count(*) as table_count
FROM information_schema.tables
WHERE table_schema = 'public';"
```

**예상 결과:** 87개

---

## Step 10. 데이터 복구 (agent_message 제외)

```bash
# agent_message 관련 내용 제외한 데이터 파일 생성
grep -v "agent_message" /tmp/archive/backup_luppiter_data_20260129.dump > /tmp/data_no_agent.dump

# 데이터 복구 (시간 소요: 약 50분, 1.3GB 기준)
psql -h 192.168.128.11 -p 5432 -U luppiter -d ktcmon -f /tmp/data_no_agent.dump
```

**주의:** 대용량 복구 시 일부 테이블 데이터가 누락될 수 있음. Step 17에서 반드시 검증 필요.

---

## Step 11. agent_message 테이블 비우기

```bash
psql -h 192.168.128.11 -p 5432 -U luppiter -d ktcmon -c "TRUNCATE TABLE agent_message;"
```

---

## Step 12. DB 사용자 생성

**주의:** 이미 존재하는 사용자면 에러 발생하므로 IF NOT EXISTS 패턴 사용

```bash
psql -h 192.168.128.11 -p 5432 -U luppiter -d ktcmon -c "
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'ktcmon') THEN
        CREATE ROLE ktcmon WITH LOGIN PASSWORD 'zmffkdnem3#';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'luppiter_user') THEN
        CREATE ROLE luppiter_user WITH LOGIN PASSWORD 'zmffkdnem3#';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'luppiter_admin') THEN
        CREATE ROLE luppiter_admin WITH LOGIN PASSWORD 'zmffkdnem3#';
    END IF;
END \$\$;
"
```

---

## Step 13. 권한 부여 (SSH로 postgres 사용자 필요)

```bash
expect -c '
spawn ssh -o StrictHostKeyChecking=no root@192.168.128.11
expect "password:"
send "P@ssw0rd\r"
expect "# "
send "sudo -u postgres psql -d ktcmon -c \"GRANT ALL ON SCHEMA public TO luppiter_user, luppiter_admin, ktcmon;\"\r"
expect "# "
send "sudo -u postgres psql -d ktcmon -c \"GRANT ALL ON ALL TABLES IN SCHEMA public TO luppiter, luppiter_admin, ktcmon;\"\r"
expect "# "
send "sudo -u postgres psql -d ktcmon -c \"GRANT SELECT ON ALL TABLES IN SCHEMA public TO luppiter_user;\"\r"
expect "# "
send "sudo -u postgres psql -d ktcmon -c \"GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO luppiter, luppiter_admin, ktcmon;\"\r"
expect "# "
send "sudo -u postgres psql -d ktcmon -c \"GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO luppiter_user;\"\r"
expect "# "
send "exit\r"
expect eof
'
```

---

## Step 14. luppiter_user 권한 조정 (조회만 허용)

```bash
expect -c '
spawn ssh -o StrictHostKeyChecking=no root@192.168.128.11
expect "password:"
send "P@ssw0rd\r"
expect "# "
send "sudo -u postgres psql -d ktcmon -c \"REVOKE ALL ON SCHEMA public FROM luppiter_user; GRANT USAGE ON SCHEMA public TO luppiter_user;\"\r"
expect "# "
send "sudo -u postgres psql -d ktcmon -c \"REVOKE ALL ON ALL TABLES IN SCHEMA public FROM luppiter_user; GRANT SELECT ON ALL TABLES IN SCHEMA public TO luppiter_user;\"\r"
expect "# "
send "sudo -u postgres psql -d ktcmon -c \"REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM luppiter_user; GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO luppiter_user;\"\r"
expect "# "
send "exit\r"
expect eof
'
```

---

## Step 15. 권한 테스트

```bash
# ktcmon 사용자 테스트
echo '192.168.128.11:5432:ktcmon:ktcmon:zmffkdnem3#' > ~/.pgpass && chmod 600 ~/.pgpass
psql -h 192.168.128.11 -p 5432 -U ktcmon -d ktcmon -c "CREATE SEQUENCE test_seq; DROP SEQUENCE test_seq; SELECT 'OK';"

# luppiter_user 테스트 (SELECT만 가능해야 함)
echo '192.168.128.11:5432:ktcmon:luppiter_user:zmffkdnem3#' > ~/.pgpass && chmod 600 ~/.pgpass
psql -h 192.168.128.11 -p 5432 -U luppiter_user -d ktcmon -c "SELECT count(*) FROM c00_common_code;"

# luppiter_user CREATE 시도 (실패해야 정상)
psql -h 192.168.128.11 -p 5432 -U luppiter_user -d ktcmon -c "CREATE SEQUENCE test_fail;"
```

---

## Step 16. 데이터 복구 검증

```bash
# .pgpass 원복
echo '192.168.128.11:5432:ktcmon:luppiter:Dbvlxpfm!1' > ~/.pgpass && chmod 600 ~/.pgpass

# 주요 테이블 데이터 확인
psql -h 192.168.128.11 -p 5432 -U luppiter -d ktcmon -c "
SELECT 'cmon_event_info' as tbl, count(*) FROM cmon_event_info
UNION ALL SELECT 'cmon_user', count(*) FROM cmon_user
UNION ALL SELECT 'cmon_group', count(*) FROM cmon_group
UNION ALL SELECT 'cmon_group_user', count(*) FROM cmon_group_user
UNION ALL SELECT 'cmon_group_layer', count(*) FROM cmon_group_layer
UNION ALL SELECT 'inventory_master', count(*) FROM inventory_master
UNION ALL SELECT 'c00_common_code', count(*) FROM c00_common_code
UNION ALL SELECT 'agent_message', count(*) FROM agent_message
ORDER BY 1;
"
```

**예상 결과:**
```
       tbl        | count
------------------+--------
 agent_message    |      0
 c00_common_code  |   1926
 cmon_event_info  | 474690
 cmon_group       |     40
 cmon_group_layer |   2517
 cmon_group_user  |    694
 cmon_user        |    251
 inventory_master |  16371
```

**주의:** inventory_master가 0건이면 Step 17 수행 필수

---

## Step 17. 누락 데이터 추가 복구 (필수 확인)

**중요:** 대용량 데이터 복구 시 특정 테이블 데이터가 누락될 수 있음. Step 16에서 inventory_master 등이 0건이면 반드시 수행.

```bash
# inventory_master 데이터 복구 (누락 시)
grep "INSERT INTO public.inventory_master " /tmp/archive/backup_luppiter_data_20260129.dump | \
psql -h 192.168.128.11 -p 5432 -U luppiter -d ktcmon

# 다른 테이블 누락 시 동일 패턴으로 복구
grep "INSERT INTO public.테이블명 " /tmp/archive/backup_luppiter_data_20260129.dump | \
psql -h 192.168.128.11 -p 5432 -U luppiter -d ktcmon
```

---

## Step 18. PostgreSQL 16 호환성 이슈 수정 (애플리케이션)

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

**수정 후:** 애플리케이션 재빌드 및 재시작

---

## Step 19. 최종 확인

- [ ] 테이블 수 확인 (87개)
- [ ] 주요 테이블 데이터 건수 확인
- [ ] 사용자 접속 테스트 (4명)
- [ ] 권한 테스트 (luppiter_user는 SELECT만)
- [ ] 애플리케이션 재시작
- [ ] 주요 화면 정상 조회 확인
  - [ ] 설비권한그룹-사용자
  - [ ] 설비권한그룹-호스트그룹 매핑
  - [ ] 대시보드
  - [ ] 인시던트 대응

---

## 트러블슈팅

### 연결 거부
```bash
nc -zv 192.168.128.11 5432
firewall-cmd --list-all
```

### 인증 실패
```bash
sudo -u postgres cat /var/lib/pgsql/16/data/pg_hba.conf | grep -v "^#" | grep -v "^$"
```

### 데드락 발생
```bash
sudo -u postgres psql -d ktcmon -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'ktcmon' AND pid <> pg_backend_pid();"
```

### 특정 테이블 데이터 누락
```bash
grep "INSERT INTO public.테이블명 " /tmp/archive/backup_luppiter_data_*.dump | \
psql -h 192.168.128.11 -p 5432 -U luppiter -d ktcmon
```

---

**최종 업데이트**: 2026-02-04
