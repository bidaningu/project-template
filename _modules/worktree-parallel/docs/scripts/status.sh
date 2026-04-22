#!/bin/bash
# {{PROJECT_NAME}} 전체 상태 한눈에 보기
#
# 사용법:
#   ./docs/scripts/status.sh

cd "/{{project-slug}}" 2>/dev/null || {
    echo "❌ 프로젝트 디렉토리 없음"
    exit 1
}

echo "╔══════════════════════════════════════════════════╗"
echo "║        {{PROJECT_NAME}} — Status Snapshot              ║"
echo "╚══════════════════════════════════════════════════╝"
echo ""
echo "📅 $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. Git 상태
echo "━━━ 🌲 Git 상태 ━━━"
echo "현재 브랜치: $(git branch --show-current 2>/dev/null || echo '?')"
echo "변경 파일: $(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
echo "최근 커밋: $(git log -1 --format='%h - %s (%ar)' 2>/dev/null || echo '없음')"
echo ""

# 2. tmux 세션
echo "━━━ 🪟 tmux 세션 ━━━"
if tmux has-session -t {{project-slug}} 2>/dev/null; then
    echo "세션 '{{project-slug}}': 실행 중"
    echo ""
    echo "창 목록:"
    tmux list-windows -t {{project-slug}} -F "  #{window_index}: #{window_name} (#{?window_active,🟢 활성,}#{?window_last_flag,⏮ 최근,})"
else
    echo "세션 '{{project-slug}}': 없음"
    echo "시작: ./docs/scripts/tmux-session.sh"
fi
echo ""

# 3. 워크트리
echo "━━━ 🌳 워크트리 ━━━"
WORKTREE_COUNT=$(git worktree list 2>/dev/null | wc -l | tr -d ' ')
echo "총 $WORKTREE_COUNT개"
echo ""
git worktree list 2>/dev/null

echo ""

# 4. 각 워크트리 상세
if [ -d ".claude/worktrees" ] && [ -n "$(ls -A .claude/worktrees 2>/dev/null)" ]; then
    echo "━━━ 📋 각 워크트리 상세 ━━━"
    for worktree_path in .claude/worktrees/*/; do
        if [ -d "$worktree_path" ]; then
            name=$(basename "$worktree_path")
            branch=$(cd "$worktree_path" && git branch --show-current 2>/dev/null)
            changes=$(cd "$worktree_path" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
            last_commit=$(cd "$worktree_path" && git log -1 --format='%ar' 2>/dev/null)
            
            echo ""
            echo "[$name]"
            echo "  브랜치: $branch"
            echo "  변경: $changes 파일"
            echo "  마지막 커밋: $last_commit"
        fi
    done
    echo ""
fi

# 5. 서비스 상태
echo "━━━ 🔧 서비스 ━━━"

# PostgreSQL
if pgrep -x "postgres" > /dev/null; then
    echo "PostgreSQL: 🟢 실행 중"
    DB_EXISTS=$(psql -l 2>/dev/null | grep -c "ga_portal_dev" || true)
    if [ "$DB_EXISTS" -gt 0 ]; then
        TABLE_COUNT=$(psql ga_portal_dev -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public'" 2>/dev/null | tr -d ' ')
        echo "  DB ga_portal_dev: 있음 ($TABLE_COUNT 테이블)"
    else
        echo "  DB ga_portal_dev: 없음 (createdb 필요)"
    fi
else
    echo "PostgreSQL: 🔴 중지"
    echo "  시작: brew services start postgresql@18"
fi

# Tailscale
if command -v tailscale &> /dev/null; then
    TAILSCALE_STATUS=$(tailscale status 2>/dev/null | head -1 || echo "?")
    echo "Tailscale: $TAILSCALE_STATUS"
fi

echo ""

# 6. 문서 상태
echo "━━━ 📚 문서 ━━━"
if [ -f "docs/TIMELINE.md" ]; then
    LAST_SESSION=$(grep -m1 "^#### " docs/TIMELINE.md 2>/dev/null || echo "기록 없음")
    echo "최근 세션: $LAST_SESSION"
fi

if [ -f "docs/WORKTREES.md" ]; then
    ACTIVE_COUNT=$(grep -c "^| " docs/WORKTREES.md 2>/dev/null || echo "0")
    echo "WORKTREES.md 기록: $ACTIVE_COUNT 항목"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "💡 팁: 변경 후 docs/TIMELINE.md 업데이트 필수"
