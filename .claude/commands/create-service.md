# Create New Service

새로운 서비스 문서 구조를 생성합니다.

## 사용법

```
/create-service {서비스명}
```

## 실행 내용

1. `docs/service/{서비스명}/` 폴더 생성
2. 기본 구조 생성:
   ```
   {서비스명}/
   ├── README.md           # 서비스 개요 + Confluence 매핑
   ├── architecture/       # 서비스 아키텍처
   ├── features/           # 주요 기능 명세
   ├── sop/                # 운영 절차서
   ├── decisions/          # 서비스 레벨 ADR
   └── projects/           # 프로젝트별 문서
   ```

3. README.md 템플릿 생성:
   - 서비스 설명
   - Confluence 동기화 정보
   - 폴더 구조 설명
   - 프로젝트 구성 테이블

## 예시

```
/create-service apollo
```

→ `docs/service/apollo/` 생성

## 참고

- 프로젝트 추가는 `/add-project` 커맨드 사용
- 서비스 삭제는 수동으로 진행
