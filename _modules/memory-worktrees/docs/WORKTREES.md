# 병렬 워크트리 관리

> 여러 Claude Code 인스턴스가 동시 작업할 때의 상태 기록.
> 각 워크트리의 현황을 추적하고 TIMELINE.md와 연결.

---

## 🔀 활성 워크트리

**현재 돌아가는 중인 작업들.**

| 워크트리 | 브랜치 | 담당 | 시작 | 진행 | 상태 |
|---|---|---|---|---|---|
| nextauth-migration | worktree-nextauth-migration | claude (pane 2) | 2026-04-22 00:45 | 0% | 대기 |
| core-people | worktree-core-people | (미배정) | 2026-04-22 02:00 | 0% | 대기 |
| asset | worktree-asset | (미배정) | 2026-04-22 02:00 | 0% | 대기 |
| portal-shell | worktree-portal-shell | (미배정) | 2026-04-22 02:00 | 0% | 대기 |

### 컬럼 설명

- **워크트리**: `.claude/worktrees/[이름]/`의 이름
- **브랜치**: 해당 워크트리의 Git 브랜치
- **담당**: `main-session` 또는 subagent 이름 (예: `module-builder`)
- **시작**: 시작 시각 (YYYY-MM-DD HH:MM)
- **진행**: 대략적 진행률 (0~100%)
- **상태**: `진행중`, `대기`, `block`, `리뷰대기`

---

## ⏸ 병합 대기

**작업 완료됐으나 아직 main에 병합 안 된 워크트리.**

| 워크트리 | 브랜치 | 완료 | 요약 | 리뷰어 | 상태 |
|---|---|---|---|---|---|
| ontology-setup | worktree-ontology-setup | 2026-04-22 01:10 | 온톨로지 스키마 보강 + packages/database 골격 + 텔레그램 훅 (98f2908) | - | 병합완료 |

### 컬럼 설명

- **요약**: 변경 내용 한 줄
- **리뷰어**: 리뷰 담당자 (없으면 -)
- **상태**: `리뷰대기`, `수정중`, `승인완료`, `병합준비`

---

## 🚫 블록된 워크트리

**진행 불가 상태 (의존성·충돌·질문 등).**

| 워크트리 | 블록 원인 | 필요 조치 | 블록 시작 |
|---|---|---|---|
| _(비어있음)_ | | | |

---

## 📋 워크트리 실행 템플릿

### 새 워크트리 시작 시

**활성 워크트리** 테이블에 추가:

```markdown
| asset-v2 | feat/asset-module | module-builder | 2026-04-22 09:00 | 0% | 진행중 |
```

Subagent 세션 시작 시:
```bash
./docs/scripts/spawn-worktree.sh asset-v2 "asset 모듈 v2 구현. 10-ontology.md 읽고 시작"
```

### 작업 중 상태 업데이트

10분마다 또는 의미있는 진전 시:

```markdown
| asset-v2 | feat/asset-module | module-builder | 2026-04-22 09:00 | 45% | 진행중 |
```

### 작업 완료 시

**활성**에서 제거 → **병합 대기**로 이동:

```markdown
| asset-v2 | feat/asset-module | 2026-04-22 14:30 | 자산 CRUD + 배정 기능 구현 | - | 리뷰대기 |
```

동시에 `TIMELINE.md`에도 세션 기록 추가.

### 병합 완료 시

**병합 대기**에서 제거 → `TIMELINE.md`에만 남음.

```bash
# 워크트리 정리
git worktree remove .claude/worktrees/asset-v2

# 또는 일괄 정리
./docs/scripts/cleanup-worktrees.sh
```

---

## 🔄 워크트리 간 의존성 관리

### 의존성이 있을 때

```markdown
## 의존성

- `purum-module` 워크트리는 `core-people` 완료 후 시작
- `asset-ui` 워크트리는 `asset-module` 완료 후 시작

## 대기 중

| 워크트리 | 대기 원인 | 대기 시작 |
|---|---|---|
| purum-module | core-people 완료 대기 | 2026-04-22 09:00 |
```

### 파일 충돌 위험

동일 파일 수정 예정이면:
```markdown
## 파일 충돌 예상

`packages/ui/Button.tsx`:
- asset-ui 워크트리 (수정 예정)
- purum-ui 워크트리 (수정 예정)

→ 순차 실행: asset-ui 먼저, 완료 후 purum-ui
```

---

## 🛡 충돌 방지 규칙

### Do's (권장)

- 한 파일은 한 워크트리에서만 수정
- 공통 코드 변경은 단일 에이전트에게
- 워크트리 시작 전 이 문서 확인
- 완료 즉시 병합 대기로 옮기기

### Don'ts (금지)

- 같은 파일 동시 수정
- 작업 완료 미기록
- 블록된 상태 방치
- 병합 대기 장기 방치 (1주 이상)

---

## 📊 워크트리 상태 스냅샷

**자동 업데이트: `./docs/scripts/status.sh` 실행 결과를 주기적으로 반영**

### 최근 스냅샷

**(스크립트로 자동 갱신)**

```
마지막 업데이트: _______________

활성 워크트리: 0개
병합 대기: 0개
블록됨: 0개

오늘의 완료: 0개
이번 주 완료: 0개
```

---

## 🔗 관련 문서

- **TIMELINE.md**: 병합 완료된 작업은 여기로 통합
- **`docs/context/operations/60-environment.md`**: 워크트리 환경 설정
- **`docs/scripts/`**: 워크트리 관리 스크립트

---

## 📖 워크트리 이해 가이드

### 왜 워크트리인가

Claude Code의 여러 세션이 **같은 파일**을 동시에 수정하면 충돌.
Git worktree는 **각 세션에 독립된 파일시스템**을 제공.

### 워크트리 명령어

```bash
# 목록 확인
git worktree list

# 새 워크트리 생성
git worktree add ../{{project-slug}}-asset feat/asset

# 워크트리 제거
git worktree remove ../{{project-slug}}-asset

# 정리 (삭제된 디렉토리)
git worktree prune
```

### Claude Code 통합

```bash
# 자동 워크트리 생성 + Claude Code 실행
claude --worktree asset-module

# 기존 워크트리에서 실행
cd .claude/worktrees/asset-module && claude

# Subagent는 AGENTS.md에 isolation: worktree 선언 시 자동
```

---

## 🧹 정리 가이드

### 정기 정리 (주 1회 권장)

```bash
# 1. 병합된 워크트리 제거
./docs/scripts/cleanup-worktrees.sh

# 2. Git 병합 브랜치 삭제
git branch --merged | grep worktree- | xargs git branch -d

# 3. 원격 브랜치 정리
git fetch --prune

# 4. 이 문서의 "병합 대기" 항목 중 완료된 것 정리
#    (수동으로 삭제 + TIMELINE에 반영)
```

### 장기 방치 대응

1주일 이상 "진행중" 상태면:
1. 담당자에게 확인
2. 블록됐으면 "블록된 워크트리"로 이동
3. 중단 결정 시 브랜치 삭제

---

*v1.0 - 2026-04-21*
*신규 추가 파일 (기존 템플릿 보강)*
