---
tags:
  - type/reference
  - audience/team
---

# Dashboard

## 서비스별

### Luppiter
```dataview
TABLE file.folder as "위치"
FROM #service/luppiter
SORT file.folder, file.name
```

### Gaia
```dataview
TABLE file.folder as "위치"
FROM #service/gaia
SORT file.name
```

### Hera
```dataview
TABLE file.folder as "위치"
FROM #service/hera
SORT file.name
```

### InfraFE
```dataview
TABLE file.folder as "위치"
FROM #service/infrafe
SORT file.name
```

### CMDB
```dataview
TABLE file.folder as "위치"
FROM #service/cmdb
SORT file.name
```

### Hermes
```dataview
TABLE file.folder as "위치"
FROM #service/hermes
SORT file.name
```

---

## 유형별

### 설계/스펙
```dataview
TABLE file.folder as "위치"
FROM #type/spec
SORT file.folder, file.name
```

### 가이드
```dataview
TABLE file.folder as "위치"
FROM #type/guide
SORT file.folder, file.name
```

### ADR
```dataview
TABLE file.folder as "위치"
FROM #type/adr
SORT file.name
```

### 자동화 패턴
```dataview
TABLE file.folder as "위치"
FROM #type/automation
SORT file.name
```

---

## 도메인별

### Java
```dataview
TABLE file.folder as "위치"
FROM #domain/java
SORT file.folder, file.name
```

### DB
```dataview
TABLE file.folder as "위치"
FROM #domain/db
SORT file.folder, file.name
```

### Jira
```dataview
TABLE file.folder as "위치"
FROM #domain/jira
SORT file.folder, file.name
```

### Observability
```dataview
TABLE file.folder as "위치"
FROM #domain/observability
SORT file.folder, file.name
```

---

## 내 문서

```dataview
TABLE file.folder as "위치"
FROM #personal/82253890
SORT file.mtime DESC
```

---

## 최근 수정

```dataview
TABLE file.mtime as "수정일", file.folder as "위치"
FROM "docs"
SORT file.mtime DESC
LIMIT 10
```
