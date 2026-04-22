#!/bin/bash
# 변경 없는 워크트리 정리
#
# 사용법:
#   ./docs/scripts/cleanup-worktrees.sh
#   ./docs/scripts/cleanup-worktrees.sh --force   # 확인 없이

set -e

FORCE=${1:-}

cd "/{{project-slug}}"

echo "🌳 현재 워크트리 목록:"
git worktree list
echo ""

echo "📊 각 워크트리 변경 사항:"
echo ""

# 변경 사항 분석
CLEAN_WORKTREES=()
DIRTY_WORKTREES=()

for worktree_path in .claude/worktrees/*/; do
    if [ -d "$worktree_path" ]; then
        name=$(basename "$worktree_path")
        changes=$(cd "$worktree_path" && git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        
        if [ "$changes" -eq 0 ]; then
            echo "  ✅ $name: 변경 없음 (정리 대상)"
            CLEAN_WORKTREES+=("$worktree_path")
        else
            echo "  📝 $name: $changes 파일 변경 (유지)"
            DIRTY_WORKTREES+=("$worktree_path")
        fi
    fi
done

echo ""

# 정리할 것 없으면 종료
if [ ${#CLEAN_WORKTREES[@]} -eq 0 ]; then
    echo "✨ 정리할 워크트리 없음"
    exit 0
fi

echo "🗑  정리 대상: ${#CLEAN_WORKTREES[@]}개"
echo ""

# 확인
if [ "$FORCE" != "--force" ]; then
    read -p "계속 진행할까요? (y/N): " confirm
    if [ "$confirm" != "y" ]; then
        echo "취소됨"
        exit 0
    fi
fi

# 삭제
echo ""
echo "🧹 정리 시작..."

for worktree_path in "${CLEAN_WORKTREES[@]}"; do
    name=$(basename "$worktree_path")
    echo "  제거: $name"
    
    # Git worktree 제거
    git worktree remove "$worktree_path" --force 2>/dev/null || true
    
    # tmux 창 제거
    tmux kill-window -t "{{project-slug}}:$name" 2>/dev/null || true
done

# Git worktree prune
echo ""
echo "🧹 Git worktree prune..."
git worktree prune

echo ""
echo "✅ 정리 완료"
echo ""
echo "📝 docs/WORKTREES.md에서도 해당 항목 제거 필요"
