#!/bin/bash
# {{PROJECT_NAME}} 작업용 tmux 세션 생성·재연결
#
# 사용법:
#   ./docs/scripts/tmux-session.sh
#   또는 alias: gap
#
# 기존 세션 있으면 attach, 없으면 새로 생성.

set -e

SESSION_NAME="{{project-slug}}"
PROJECT_DIR="/{{project-slug}}"

# 프로젝트 디렉토리 체크
if [ ! -d "$PROJECT_DIR" ]; then
    echo "❌ 프로젝트 디렉토리 없음: $PROJECT_DIR"
    exit 1
fi

# 이미 세션 있으면 attach
if tmux has-session -t $SESSION_NAME 2>/dev/null; then
    echo "📌 세션 '$SESSION_NAME' 이미 존재. Attaching..."
    tmux attach -t $SESSION_NAME
    exit 0
fi

echo "🚀 새 tmux 세션 생성: $SESSION_NAME"

# 새 세션 + 창 0 (메인)
tmux new-session -d -s $SESSION_NAME -n "main" -c "$PROJECT_DIR"
tmux send-keys -t $SESSION_NAME:main "clear" C-m
tmux send-keys -t $SESSION_NAME:main "echo '📂 {{PROJECT_NAME}} Main'" C-m
tmux send-keys -t $SESSION_NAME:main "git status" C-m

# 창 1: 상태 모니터
tmux new-window -t $SESSION_NAME -n "status" -c "$PROJECT_DIR"
tmux send-keys -t $SESSION_NAME:status "clear" C-m
tmux send-keys -t $SESSION_NAME:status "./docs/scripts/status.sh" C-m

# 창 2: DB
tmux new-window -t $SESSION_NAME -n "db" -c "$PROJECT_DIR"
tmux send-keys -t $SESSION_NAME:db "clear" C-m
tmux send-keys -t $SESSION_NAME:db "psql ga_portal_dev 2>/dev/null || echo 'DB 연결 실패. createdb ga_portal_dev 필요할 수 있음'" C-m

# 첫 창으로
tmux select-window -t $SESSION_NAME:main

echo "✅ 세션 생성 완료"
echo ""
echo "📋 단축키:"
echo "  Ctrl+a 0,1,2...  창 전환"
echo "  Ctrl+a w         창 목록"
echo "  Ctrl+a c         새 창"
echo "  Ctrl+a d         세션 detach (유지)"
echo "  Ctrl+a |         세로 분할"
echo "  Ctrl+a -         가로 분할"
echo ""
echo "🔌 Attaching..."

tmux attach -t $SESSION_NAME
