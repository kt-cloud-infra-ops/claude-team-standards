# 초기 환경 설정

새 환경에서 프로젝트 clone 후 최초 1회 실행합니다.

## 실행

### 1. 환경 체크

```bash
echo "=== 환경 정보 ==="
echo "OS: $(uname -s)"
echo "User: $(whoami)"
echo "Shell: $SHELL"
```

### 2. Git 설정 확인

```bash
echo "=== Git 설정 ==="
git config user.name
git config user.email
```

**설정 안 되어 있으면** 입력 받기:
- 이름 (예: 홍길동)
- 이메일 (예: hong.gildong@kt.com)

```bash
git config --global user.name "입력받은 이름"
git config --global user.email "입력받은 이메일"
```

### 3. Jira 인증 설정

**이미 설정됨 체크**:
```bash
# 환경변수 체크
if [ -n "$JIRA_EMAIL" ] && [ -n "$JIRA_API_TOKEN" ]; then
  echo "✅ Jira 인증: 환경변수 설정됨 ($JIRA_EMAIL)"
# 로컬 파일 체크
elif [ -f ~/.jira-credentials.json ]; then
  echo "✅ Jira 인증: ~/.jira-credentials.json 존재"
else
  echo "⚠️ Jira 인증 필요"
fi
```

**설정 안 되어 있으면** 입력 받기:
- 이메일 (KT 이메일)
- API 토큰

API 토큰 발급: https://id.atlassian.com/manage-profile/security/api-tokens

```bash
# ~/.jira-credentials.json 생성
cat > ~/.jira-credentials.json << EOF
{
  "email": "입력받은 이메일",
  "apiToken": "입력받은 토큰",
  "baseUrl": "https://ktcloud.atlassian.net"
}
EOF
```

### 4. 연결 테스트

```bash
# Jira API 테스트
AUTH=$(echo -n "$JIRA_EMAIL:$JIRA_API_TOKEN" | base64)
curl -s -H "Authorization: Basic $AUTH" \
  "https://ktcloud.atlassian.net/rest/api/3/myself" | jq '{displayName, emailAddress}'
```

### 5. 완료 메시지

```
✅ 초기 설정 완료

Git:
- user.name: 홍길동
- user.email: hong.gildong@kt.com

Jira:
- 사용자: 홍길동(InfraOps개발팀)
- 이메일: hong.gildong@kt.com

이제 /tasks 로 할 일을 확인하세요.
```

---

## 설정 항목 요약

| 항목 | 저장 위치 | 용도 |
|------|----------|------|
| Git user.name | ~/.gitconfig | 커밋 작성자 |
| Git user.email | ~/.gitconfig | 커밋 이메일 |
| Jira 인증 | ~/.jira-credentials.json | Jira API 호출 |

모두 홈 디렉토리에 저장되어 브랜치/프로젝트와 무관하게 유지됩니다.
