# Document Organization Rules

## CRITICAL: 공통 설정 변경 시 동기화 필수

**공통 의사결정/규칙 변경 요청 시:**
1. 반드시 현재 값 확인
2. 변경 내용 명확히 파악
3. 관련된 모든 위치 업데이트:
   - `~/.claude/rules/` (개인 홈)
   - `.claude/rules/` (프로젝트 repo)
   - `CLAUDE.md` (참조하는 경우)

---

## Default Storage Locations

When creating or saving documents, use these rules:

### Common/Shared Items → Upper Level

Save to `docs/guides/` or `docs/` when:
- Language-specific coding standards (java/, db/, common/)
- Design patterns applicable across projects
- SRE/operations guidelines
- Reusable automation patterns
- General best practices

```
docs/
├── guides/           # Language/topic guides
│   ├── java/         # Java-specific
│   ├── db/           # Database-specific
│   └── common/       # Cross-language
├── automations/      # Reusable automation patterns
└── decisions/        # Cross-project ADRs
```

### Project-Specific Items → Project Folders

Save to `docs/projects/<project_name>/` when:
- Project-specific architecture/design docs
- **Project-specific ADRs** (decisions/)
- SOPs for specific systems
- E2E test specs
- API documentation for that project
- Implementation guides for that project

```
docs/projects/<project>/
├── architecture/     # Project architecture
├── api/              # API documentation
├── decisions/        # Project-specific ADRs
├── sop/              # Standard operating procedures
├── e2e/              # E2E test documentation
└── guide/            # Project-specific guides
```

### Cross-Project/Global Decisions → docs/decisions/

Save to `docs/decisions/` when:
- Team-wide policy decisions
- Cross-project architectural decisions
- Tool/technology selection affecting multiple projects
- Process/workflow changes

### Temporary Items → temp/

Save to `docs/temp/` when:
- Work-in-progress documents
- Analysis reports (before moving to final location)
- Session-specific notes
- Draft documents

## 자동 저장 규칙

Claude는 현재 작업 컨텍스트를 기반으로 자동 결정:

### 프로젝트 작업 중일 때
특정 프로젝트(luppiter_scheduler, luppiter_web 등) 작업 중이면 → **해당 프로젝트 폴더에 저장**

```
docs/projects/<현재_프로젝트>/
├── decisions/    # 설계 결정, 이슈 해결 기록
├── guide/        # 프로젝트 특화 가이드
└── ...
```

### 프로젝트 무관할 때만 → 상위 폴더
- 팀 전체 정책/도구 → `docs/decisions/`
- 언어별 공통 패턴 → `docs/guides/<언어>/`
- 자동화 패턴 → `docs/automations/`

### /wrap 시 자동 분류

| 세션 컨텍스트 | 저장 위치 |
|-------------|----------|
| luppiter_scheduler 작업 | `docs/projects/luppiter_scheduler/decisions/` |
| luppiter_web 작업 | `docs/projects/luppiter_web/decisions/` |
| 팀 설정/도구 작업 | `docs/decisions/` |
| 공통 학습 (패턴, 기법) | `docs/guides/<언어>/` |

## Naming Conventions

- Use kebab-case for filenames: `design-patterns.md`
- No file numbers (e.g., ~~004-design-patterns.md~~)
- Use descriptive names that indicate content
- Include project name prefix for project-specific docs when needed

## README Files

Each project folder should have a `README.md` with:
- Project overview (name, language, role)
- Document list with descriptions
- Links to relevant common guides
