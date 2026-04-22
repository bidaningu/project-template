# 일지 자동화 — cron 등록 가이드

> 원격 Claude 에이전트를 cron 으로 돌려 `.context/journal/` 을 자동 생성.

---

## 전제

- Anthropic Claude.ai 계정의 **remote trigger** 사용 (https://claude.ai/code/scheduled)
- 등록은 `/schedule` skill 으로 대화형 가능 (Claude Code CLI)
- 프로젝트 레포가 GitHub 에 있어야 함 (원격 에이전트가 clone)
- repo 내에 `MEMORY.md` 파일 존재 (원격 에이전트는 사용자 `~/.claude/` 접근 불가)

## 등록할 트리거 2개

### 1) `{{PROJECT}}-daily-journal`

| 필드 | 값 |
|---|---|
| cron | `0 15 * * *` (UTC) = 매일 KST **00:00** |
| model | `claude-sonnet-4-6` |
| repo | `https://github.com/<org>/<repo>` |
| tools | `Bash, Read, Write, Edit, Glob, Grep` |
| environment | Default (anthropic_cloud) |

**프롬프트 (프로젝트명/경로만 교체):**
```
당신은 {{PROJECT}} 프로젝트의 '일일 회고'를 매일 KST 00:00 에 작성하는 원격 Claude 에이전트입니다. 이전 맥락 없음.

## ⚠️ 실행 시각 인지 (반드시 먼저)
LLM 자체는 현재 시각을 모름. 반드시 bash 로 확인:
```bash
NOW_KST=$(TZ=Asia/Seoul date '+%Y-%m-%d %H:%M %Z')
TODAY_KST=$(TZ=Asia/Seoul date '+%Y-%m-%d')
YDAY_KST=$(TZ=Asia/Seoul date -d "yesterday" '+%Y-%m-%d')
echo "now=$NOW_KST today=$TODAY_KST yesterday=$YDAY_KST"
```
확인한 $YDAY_KST 가 대상 날짜. 자정 직후 실행이므로 '어제 KST' = 24시간 전 세션 전체.

## 단계
1. git log --since="24 hours ago" --all --pretty=format:'%h %ad %s' --date=iso | head -50
2. TIMELINE.md 최근 세션 (최신이 위)
3. WORKTREES.md 가 있으면 활성/병합완료/블록
4. 어제 커밋 0건이면 종료 (파일 생성 X)

## 작성 파일
.context/journal/$YDAY_KST.md (없으면 디렉토리 생성)

## 포맷
# $YDAY_KST (요일) 일일 회고
## ① 요약 (2~3문장)
## ② 완료 — [영역] 작업 — <SHA>
## ③ 진행 중
## ④ 블록·지연 — 원인 — 대기 대상
## ⑤ 소통·맥락 문제 (없으면 '없음')
## ⑥ 개선 제안 + 반영 위치 [rule|memory|script|CLAUDE.md|기타]

## 완료 후
git add .context/journal/$YDAY_KST.md
git commit -m "docs(journal): $YDAY_KST 일일 회고"
git push origin main

## 주의
- 로컬 머신/DB/로컬 env 접근 불가. git repo 내용만.
- date 명령이 GNU date(Linux) 전제. BSD 환경이면 `date -v-1d` 사용.
- 관찰 기반만. 추측·희망 금지.
```

### 2) `{{PROJECT}}-weekly-review`

| 필드 | 값 |
|---|---|
| cron | `0 9 * * 5` (UTC) = 매주 금요일 KST **18:00** |
| model | `claude-sonnet-4-6` |
| repo | 동일 |
| tools | 동일 |

**프롬프트:**
```
당신은 {{PROJECT}} 프로젝트의 '주간 회고'를 매주 금요일 KST 18:00 에 작성하는 원격 Claude 에이전트입니다. 맥락 없이 시작.

## ⚠️ 실행 시각 인지 (반드시 먼저)
```bash
NOW_KST=$(TZ=Asia/Seoul date '+%Y-%m-%d %H:%M %Z')
YEAR=$(TZ=Asia/Seoul date '+%Y')
ISO_WEEK=$(TZ=Asia/Seoul date '+%V')
WEEK_TAG="${YEAR}-W${ISO_WEEK}"
WEEK_START=$(TZ=Asia/Seoul date -d "last monday -6 days" '+%Y-%m-%d' 2>/dev/null || TZ=Asia/Seoul date -d "monday-6 days" '+%Y-%m-%d')
WEEK_END=$(TZ=Asia/Seoul date '+%Y-%m-%d')
echo "now=$NOW_KST tag=$WEEK_TAG range=$WEEK_START~$WEEK_END"
```

## 단계
1. ls .context/journal/*.md 2>/dev/null | tail -7 → 최근 7일치 Read
2. git log --since="7 days ago" --pretty=format:'%h %ad %s' --date=short
3. TIMELINE.md 이번 주 세션
4. MEMORY.md 이번 주 새 feedback 유무

## 작성 파일
.context/journal/weekly/$WEEK_TAG.md

## 포맷
# $WEEK_TAG 주간 회고 ($WEEK_START ~ $WEEK_END)
## 지표 - 커밋 N / 활성 워크트리 N / 완료 N / 일일회고 N
## 반복되는 블록 패턴 - 패턴 — 빈도 — 근본 원인
## 소통·맥락 이슈 - 패턴 — 예시 일자
## Rule化된 개선 - MEMORY.md 에 추가할 feedback (repo 내 파일)
## 미해결·이월
## 다음 주 우선순위 (1~3개 구체)

## 메모리 반영
개선안은 repo 내 MEMORY.md 에. 원격 에이전트는 ~/.claude/projects/.../memory/ 접근 불가.

## 완료 후
git add .context/journal/weekly/$WEEK_TAG.md MEMORY.md
git commit -m "docs(journal): $WEEK_TAG 주간 회고 + rule 반영"
git push origin main
```

## 등록 방법

Claude Code CLI 에서:
```
/schedule
→ 위 프롬프트 전달 + cron/repo/model 지정
```

또는 https://claude.ai/code/scheduled UI 에서 직접 생성.

## 체크 포인트

- [ ] 프롬프트의 `{{PROJECT}}` 가 실제 프로젝트명으로 교체됐는가
- [ ] repo URL 이 정확한가
- [ ] `MEMORY.md` 가 repo 내에 존재하는가 (주간 회고가 기록할 대상)
- [ ] `TIMELINE.md` 가 준비됐는가 (에이전트가 읽음)
- [ ] 원격 에이전트가 `git push` 할 권한이 있는가 (기본적으로 OK, private repo 도 OK)

## 주의

- **최소 cron 주기 1시간** (claude.ai 제약)
- cron 은 UTC 기준 — KST 로 쓰려면 9시간 빼기 (예: KST 00:00 = UTC 15:00 전날)
- 한 계정에서 여러 프로젝트 각각 등록 가능 (이름만 구분)

## 원본 구현 레퍼런스

최초 구현: `ga-portal` (2026-04-22). 거기서 패턴 이식됨.
