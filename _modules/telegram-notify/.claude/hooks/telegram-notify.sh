#!/usr/bin/env bash
# Claude Code 훅용 텔레그램 알림 전송.
# 사용: telegram-notify.sh <emoji> <title>
#   예: telegram-notify.sh 🤔 "결정 필요"
#
# env 변수 TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID 필요 (.claude/settings.local.json 의 env).
# CLAUDE_PROJECT_DIR (Claude Code 가 주입) 기반으로 워크트리명·TIMELINE [다음] 추출.
#
# 메시지 포맷:
#   [{{PROJECT_NAME}} · <워크트리>] <emoji> <title>
#   ➡️ 다음: <TIMELINE.md 의 최신 [다음] 항목>
#
# 로그: /tmp/claude-telegram.log

set -u

EMOJI="${1:-🔔}"
TITLE="${2:-알림}"

[ -z "${TELEGRAM_BOT_TOKEN:-}" ] && exit 0
[ -z "${TELEGRAM_CHAT_ID:-}" ] && exit 0

# 워크트리명
WT="${CLAUDE_PROJECT_DIR##*/}"
[ "$WT" = "{{project-slug}}" ] && WT=main

# 단순 포맷 — 시그널만. 긴 꼬리(TIMELINE [다음]) 제거.
MSG="[{{PROJECT_NAME}} · ${WT}] ${EMOJI} ${TITLE}"

{
    echo "--- $(date '+%Y-%m-%d %H:%M:%S') [$EMOJI $TITLE] ---"
    curl -s --max-time 5 -X POST \
        "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}" \
        --data-urlencode "text=${MSG}" 2>&1
    echo ""
} >> /tmp/claude-telegram.log

exit 0
