#!/bin/bash
# 여러 워크트리를 한 번에 병렬 시작
#
# 사용법:
#   ./docs/scripts/spawn-parallel.sh [worktree-names...]
#
# 인자 없으면 기본 목록 사용.
#
# 예시:
#   ./docs/scripts/spawn-parallel.sh asset purum tests
#   ./docs/scripts/spawn-parallel.sh   # 기본 목록

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPAWN_SCRIPT="$SCRIPT_DIR/spawn-worktree.sh"

# 기본 워크트리 (편집 가능)
DEFAULT_WORKTREES=(
    "core-people"
    "asset"
    "tests"
    "docs-update"
)

# 인자 받은 목록 있으면 사용
if [ $# -gt 0 ]; then
    WORKTREES=("$@")
else
    echo "📋 기본 워크트리 목록 사용:"
    printf '  - %s\n' "${DEFAULT_WORKTREES[@]}"
    echo ""
    WORKTREES=("${DEFAULT_WORKTREES[@]}")
fi

echo "🚀 병렬 워크트리 시작: ${#WORKTREES[@]}개"
echo ""

# 각 워크트리 생성
for wt in "${WORKTREES[@]}"; do
    echo "▶️  '$wt' 생성 중..."
    "$SPAWN_SCRIPT" "$wt"
    echo ""
    sleep 1
done

echo ""
echo "✅ 모든 워크트리 생성 완료"
echo ""
echo "📊 상태 확인:"
echo "  tmux list-windows -t {{project-slug}}"
echo "  또는 ./docs/scripts/status.sh"
echo ""
echo "🔌 접속:"
echo "  tmux attach -t {{project-slug}}"
echo ""
echo "⚠️  docs/WORKTREES.md를 열어 활성 워크트리 테이블 업데이트하세요."
