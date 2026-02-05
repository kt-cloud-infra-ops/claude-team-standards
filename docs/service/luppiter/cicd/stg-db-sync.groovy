/**
 * 스테이징 DB 동기화 파이프라인
 *
 * 용도: 운영 DB → 스테이징 DB 동기화
 * 실행 주기: 필요시 (월 1회 권장)
 * 예상 소요: 30분~2시간
 *
 * 흐름:
 * 1. 운영 백업 Git에서 가져오기
 * 2. 스테이징 DB에 복원
 * 3. STG 전용 데이터 INSERT (stg-data.sql)
 */

pipeline {
    agent any

    environment {
        // DB 동기화 관련
        BACKUP_GIT_URL = 'git@10.217.192.26:all/backup.git'
        BACKUP_FOLDER = 'luppiter_m1-jpt-prd-mon-d01_10.2.14.105'
        BACKUP_LOCAL_PATH = '/data/db_sync'

        // STG 데이터 SQL (Git 관리)
        STG_DATA_GIT_URL = 'git@10.217.192.26:infraops/claude.git'
        STG_DATA_SQL_PATH = 'docs/service/luppiter/cicd/stg-data/stg-data.sql'

        // 스테이징 DB
        STG_DB_HOST = '10.4.224.97'
        STG_DB_PORT = '5432'
        STG_DB_NAME = 'ktcmon'
        STG_DB_USER = 'ktcmon'
    }

    stages {

        stage('준비') {
            steps {
                script {
                    echo "========== 스테이징 DB 동기화 시작 =========="
                    sh "mkdir -p ${BACKUP_LOCAL_PATH}"
                }
            }
        }

        stage('운영 백업 가져오기') {
            steps {
                script {
                    echo "▶️ 운영 백업 Git에서 가져오기..."

                    sh """
                        if [ -d ${BACKUP_LOCAL_PATH}/backup/.git ]; then
                            cd ${BACKUP_LOCAL_PATH}/backup && git pull origin main
                        else
                            cd ${BACKUP_LOCAL_PATH} && GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no' git clone ${BACKUP_GIT_URL} backup
                        fi
                    """

                    def latestBackup = sh(
                        script: "ls -t ${BACKUP_LOCAL_PATH}/backup/${BACKUP_FOLDER}/backup_luppiter_db_*.tar.gz | head -1",
                        returnStdout: true
                    ).trim()

                    echo "최신 백업 파일: ${latestBackup}"
                    env.LATEST_BACKUP = latestBackup
                }
            }
        }

        stage('STG 데이터 SQL 가져오기') {
            steps {
                script {
                    echo "▶️ STG 데이터 SQL 가져오기..."

                    sh """
                        if [ -d ${BACKUP_LOCAL_PATH}/claude/.git ]; then
                            cd ${BACKUP_LOCAL_PATH}/claude && git pull origin main
                        else
                            cd ${BACKUP_LOCAL_PATH} && GIT_SSH_COMMAND='ssh -o StrictHostKeyChecking=no' git clone ${STG_DATA_GIT_URL} claude
                        fi
                    """
                }
            }
        }

        stage('백업 압축 해제') {
            steps {
                script {
                    echo "▶️ 백업 파일 압축 해제..."

                    sh """
                        cd ${BACKUP_LOCAL_PATH}
                        rm -rf extracted
                        mkdir -p extracted
                        tar -xzf ${LATEST_BACKUP} -C extracted
                    """
                }
            }
        }

        stage('스테이징 DB 복원') {
            steps {
                script {
                    echo "▶️ 스테이징 DB에 복원 (시간 소요)..."

                    def schemaFile = sh(
                        script: "ls ${BACKUP_LOCAL_PATH}/extracted/archive/backup_luppiter_schema_*.dump | head -1",
                        returnStdout: true
                    ).trim()

                    def dataFile = sh(
                        script: "ls ${BACKUP_LOCAL_PATH}/extracted/archive/backup_luppiter_data_*.dump | head -1",
                        returnStdout: true
                    ).trim()

                    sh "PGPASSWORD=\$STG_DB_PWD psql -h ${STG_DB_HOST} -p ${STG_DB_PORT} -U ${STG_DB_USER} -d ${STG_DB_NAME} < ${schemaFile} || true"
                    sh "PGPASSWORD=\$STG_DB_PWD psql -h ${STG_DB_HOST} -p ${STG_DB_PORT} -U ${STG_DB_USER} -d ${STG_DB_NAME} < ${dataFile} || true"
                }
            }
        }

        stage('STG 데이터 INSERT') {
            steps {
                script {
                    echo "▶️ STG 전용 데이터 INSERT..."

                    sh "PGPASSWORD=\$STG_DB_PWD psql -h ${STG_DB_HOST} -p ${STG_DB_PORT} -U ${STG_DB_USER} -d ${STG_DB_NAME} -f ${BACKUP_LOCAL_PATH}/claude/${STG_DATA_SQL_PATH}"
                }
            }
        }

        stage('검증') {
            steps {
                script {
                    echo "▶️ DB 동기화 검증..."

                    sh """
                        PGPASSWORD=\$STG_DB_PWD psql -h ${STG_DB_HOST} -p ${STG_DB_PORT} -U ${STG_DB_USER} -d ${STG_DB_NAME} << 'EOSQL'
                        SELECT '계위(STG)' as category, COUNT(*) as cnt FROM cmon_layer_code_info WHERE layer_cd LIKE 'STG%'
                        UNION ALL SELECT '인벤토리(STG)', COUNT(*) FROM inventory_master WHERE host_group_nm LIKE '%STG%'
                        UNION ALL SELECT '배치설정(ES9)', COUNT(*) FROM c01_batch_event WHERE system_code LIKE 'ES9%'
                        UNION ALL SELECT 'STG그룹-사용자', COUNT(*) FROM cmon_group_user WHERE group_id = 'STG_GROUP';
EOSQL
                    """
                }
            }
        }

        stage('정리') {
            steps {
                script {
                    sh "rm -rf ${BACKUP_LOCAL_PATH}/extracted"
                    echo "✅ 임시 파일 정리 완료"
                }
            }
        }
    }

    post {
        success {
            echo "========== 스테이징 DB 동기화 성공 =========="
        }
        failure {
            echo "========== 스테이징 DB 동기화 실패 =========="
        }
    }
}
