# 일지·회고 (자동화)

> 원격 Claude 에이전트가 cron 으로 자동 작성하는 **선택적** 시스템. 이 기능을 쓰지 않으면 이 폴더는 무시.

---

## 구조

```
.context/journal/
├── README.md               # 이 파일
├── cron-setup.md           # cron trigger 등록 가이드
├── YYYY-MM-DD.md           # 일일 회고 (매일 KST 00:00 자동)
└── weekly/
    └── YYYY-WW.md          # 주간 회고 (매주 금요일 KST 18:00 자동)
```

## 자동화

| 트리거 | 크론 (UTC) | KST 환산 | 목적 |
|---|---|---|---|
| `{{PROJECT}}-daily-journal` | `0 15 * * *` | 매일 00:00 | 전일 활동 회고·개선안 기록 |
| `{{PROJECT}}-weekly-review` | `0 9 * * 5` | 매주 금요일 18:00 | 주간 통합 분석·rule化 |

등록 절차: [`cron-setup.md`](./cron-setup.md)
관리 UI: https://claude.ai/code/scheduled

## 일일 포맷

```markdown
# YYYY-MM-DD (요일) 일일 회고

## ① 요약
## ② 완료        — [워크트리/영역] 작업 요약 — <commit SHA>
## ③ 진행 중
## ④ 블록·지연    — 항목 — 원인 — 대기 대상
## ⑤ 소통·맥락 문제 (없으면 '없음')
## ⑥ 개선 제안 + 반영 위치  ← rule / memory / script / CLAUDE.md / 기타
```

## 주간 포맷

```markdown
# YYYY-WW 주간 회고 (M/D ~ M/D)

## 지표       — 커밋 N / 활성 워크트리 N / 완료 N / 일일회고 N
## 반복되는 블록 패턴 — 패턴 — 빈도 — 근본 원인
## 소통·맥락 이슈    — 패턴 — 예시 일자
## Rule化된 개선     — MEMORY.md 에 추가할 feedback
## 미해결·이월
## 다음 주 우선순위 (1~3개 구체)
```

## 원칙

- **관찰 기반**. git log·TIMELINE·WORKTREES 에 근거. 추측·희망 금지.
- **개선 제안은 반영 위치까지 명시** — "제안만 하고 소멸" 방지가 이 시스템의 핵심 가치.
- **커밋 0건 날은 파일 생성 X** — 노이즈 줄이기.
- **원격 에이전트 한계 인지**: 로컬 머신·DB·`.env`·`.claude/settings.local.json` 접근 불가. git repo 내용만.

## 비활성화

이 기능을 쓰지 않으려면 이 폴더를 삭제하거나, `.gitignore` 에 추가하지 말고 그냥 두고 cron trigger 를 등록하지 않으면 됨 (등록된 cron 만 동작).
