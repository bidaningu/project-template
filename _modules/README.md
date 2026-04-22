# `_modules/` — 선택형 자동화 모듈

> 각 폴더 = 독립 모듈. 필요한 것만 `cp -r` 로 프로젝트 루트에 merge.
> 위저드·Node 의존성 없음. `cp` 만 알면 됨.

---

## 적용 방법 (의존성 0)

```bash
# 1. template clone
git clone git@github.com:bidaningu/project-template.git my-new-project
cd my-new-project

# 2. 필요한 모듈만 cp -r (점 포함 주의)
cp -r _modules/butler-agent/. .
cp -r _modules/permission-levels/. .
cp -r _modules/status-dashboard/. .

# 3. 플레이스홀더 치환
grep -rl '{{PROJECT_NAME}}' . | xargs sed -i '' 's/{{PROJECT_NAME}}/My Project/g'
grep -rl '{{project-slug}}' . | xargs sed -i '' 's/{{project-slug}}/my-new-project/g'

# 4. _modules/ 삭제 (선택)
rm -rf _modules

# 5. git init
git init && git add . && git commit -m "chore: scaffold from project-template"
```

---

## 모듈 목록

| 모듈 | 무엇이 | 언제 필요 |
|---|---|---|
| **butler-agent** | `AGENTS.md` + `PRINCIPLES.md` + `PERSONA.md` — 자잘한 결정 쳐내는 집사 subagent | 팀 작업·에이전트 다수·사용자 개입 줄이기 |
| **permission-levels** | L1~L5 권한 단계 + `set-level.sh` | butler 와 세트. 프로젝트 단계별 자율성 조정 |
| **status-dashboard** | `update-status.sh` → `STATUS.md` 실시간 집계 | 워크트리·pane 많아질 때 |
| **telegram-notify** | Notification 훅 + 전송 스크립트 | 중요 알림 외부 수신 |
| **worktree-parallel** | tmux 세션·spawn-worktree·cleanup 스크립트 | 병렬 작업 워크플로우 |
| **memory-worktrees** | `WORKTREES.md` + `MEMORY.md` 템플릿 | 워크트리 상태·장기 기억 |

> PR #1 에서 먼저 들어온 `.context/journal/` (일일·주간 회고 cron) 도 같이 쓰면 완성형.

---

## 모듈 의존

```
butler-agent ← permission-levels (같이 써야 LEVEL 분기 동작)
butler-agent → PRINCIPLES·PERSONA (butler 의 시스템 프롬프트)
telegram-notify → .claude/settings.local.json 의 env (token)
status-dashboard ← tmux 세션 있어야 pane 정보 수집
```

단독으로도 쓸 수 있으나 위 의존 조합이 전형.

---

## 설계 철학

- **단순 > 기교** — Node·inquirer 없는 디렉토리 cp
- **토큰 절약** — butler 참조 파일은 PRINCIPLES/PERSONA/LEVEL 최소, 로그는 tail 만
- **반대 의견 가능** — butler 는 yes-man 아님 (CHALLENGE + 3-strike)
- **궁극 목적** — 자동화로 반복 제거 → 사람은 본질(가족·삶·전략)에 시간

원 구현: `github.com/bidaningu/ga-portal` (2026-04-22~).
