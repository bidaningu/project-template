#!/bin/bash
# 새 워크트리 + Claude Code 인스턴스 생성 (tmux 창으로)
#
# 사용법:
#   ./docs/scripts/spawn-worktree.sh <worktree-name> [initial-prompt]
#
# 예시:
#   ./docs/scripts/spawn-worktree.sh core-people
#   ./docs/scripts/spawn-worktree.sh asset "asset 모듈 구현 시작"

set -e

NAME=$1
INITIAL_PROMPT=$2

if [ -z "$NAME" ]; then
    echo "❌ 사용법: spawn-worktree.sh <worktree-name> [initial-prompt]"
    echo ""
    echo "예시:"
    echo "  spawn-worktree.sh core-people"
    echo "  spawn-worktree.sh asset \"asset 모듈 스펙 읽고 구현 시작\""
    exit 1
fi

SESSION="{{project-slug}}"
PROJECT_DIR="/{{project-slug}}"

# 이름 검증 (영숫자, 하이픈만)
if [[ ! "$NAME" =~ ^[a-zA-Z0-9-]+$ ]]; then
    echo "❌ 워크트리 이름은 영숫자·하이픈만 가능: $NAME"
    exit 1
fi

# tmux 세션 확인
if ! tmux has-session -t $SESSION 2>/dev/null; then
    echo "⚠️  tmux 세션 '$SESSION' 없음. 먼저 세션 생성..."
    "$PROJECT_DIR/docs/scripts/tmux-session.sh" &
    sleep 2
fi

# 이미 같은 이름 창 있으면 이동
if tmux list-windows -t $SESSION -F "#{window_name}" 2>/dev/null | grep -q "^${NAME}$"; then
    echo "📌 창 '$NAME' 이미 존재. 이동..."
    tmux select-window -t $SESSION:$NAME
    tmux attach -t $SESSION 2>/dev/null || true
    exit 0
fi

echo "🌳 워크트리 생성: $NAME"

# 새 tmux 창
tmux new-window -t $SESSION -n "$NAME" -c "$PROJECT_DIR"

# Claude Code를 워크트리 모드로 실행
# 기본 플래그: --dangerously-skip-permissions (bypass permissions 모드)
# auto 모드는 기동 후 세션 내 슬래시 커맨드로 활성화.
CLAUDE_FLAGS="--dangerously-skip-permissions --worktree $NAME"

if [ -n "$INITIAL_PROMPT" ]; then
    ESCAPED_PROMPT=$(echo "$INITIAL_PROMPT" | sed "s/'/'\\\\''/g")
    tmux send-keys -t $SESSION:$NAME "claude $CLAUDE_FLAGS '$ESCAPED_PROMPT'" C-m
else
    tmux send-keys -t $SESSION:$NAME "claude $CLAUDE_FLAGS" C-m
fi

# WORKTREES.md 업데이트 알림
NOW=$(date '+%Y-%m-%d %H:%M')
echo ""
echo "✅ 워크트리 '$NAME' 시작됨 (@ $NOW)"
echo ""
echo "📝 다음을 docs/WORKTREES.md 활성 워크트리에 추가:"
echo ""
echo "| $NAME | worktree-$NAME | claude | $NOW | 0% | 진행중 |"
echo ""
echo "🔌 tmux 창으로 전환:"
echo "  tmux select-window -t $SESSION:$NAME"
echo "  또는 Ctrl+a w 후 선택"
