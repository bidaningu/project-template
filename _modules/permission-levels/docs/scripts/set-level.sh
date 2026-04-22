#!/bin/bash
# 권한 레벨 전환. 사용: set-level.sh L1|L2|L3|L4|L5
#
# 현재 레벨은 .claude/LEVEL 한 줄 파일로 관리.
# butler 서브에이전트가 이 값을 읽고 의사결정 분기.
# 상세: docs/PERMISSION_LEVELS.md

set -e

NEW="$1"

if [[ -z "$NEW" ]]; then
    CUR=$(cat .claude/LEVEL 2>/dev/null || echo "L3")
    echo "현재 권한 레벨: $CUR"
    echo "사용: $0 L1|L2|L3|L4|L5"
    echo "상세: docs/PERMISSION_LEVELS.md"
    exit 0
fi

if [[ ! "$NEW" =~ ^L[1-5]$ ]]; then
    echo "❌ 레벨은 L1~L5 중 하나. 입력: $NEW"
    exit 1
fi

CUR=$(cat .claude/LEVEL 2>/dev/null || echo "(없음)")

if [ "$CUR" = "$NEW" ]; then
    echo "이미 $NEW 입니다."
    exit 0
fi

mkdir -p .claude
echo "$NEW" > .claude/LEVEL
echo "✅ 권한 레벨: $CUR → $NEW"
echo ""
case "$NEW" in
    L1) echo "관찰자 — 모든 결정 사용자 승인. 초기 셋업 권장." ;;
    L2) echo "검토자 — 자동영역만 auto. 아키텍처 확정 전 권장." ;;
    L3) echo "협업자 — butler가 중간지대 판단. 기본." ;;
    L4) echo "자율 — butler가 main push도 판단. 안정 운영." ;;
    L5) echo "전권 — 외부 repo·비가역만 사용자. 장기 유지보수." ;;
esac
echo ""
echo "활성 Claude 세션은 새 레벨 반영 위해 재시작 권장."
