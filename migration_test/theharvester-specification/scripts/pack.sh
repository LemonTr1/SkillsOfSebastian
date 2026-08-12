#!/usr/bin/env bash
# pack.sh — 将 theHarvester skill 打包为可迁移的 tar.gz
# 说明：打包时排除 .venv（venv 内路径绑定，跨主机需重建），
#       目标主机解压后运行 setup.sh 自动重建环境即可
# 用法：bash pack.sh [输出目录]（默认 ~/.sebastian/skills/）

OUT_DIR="${1:-/home/lem0ntr1/.sebastian/skills}"
SKILL_DIR="/home/lem0ntr1/.sebastian/skills/theharvester-specification"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$OUT_DIR/theharvester-specification_$STAMP.tar.gz"

echo "📦 正在打包（排除 .venv 以减小体积并保证跨主机可用）..."
tar --exclude='vendor/theHarvester/.venv' \
    --exclude='__pycache__' \
    -czf "$OUT_FILE" \
    -C /home/lem0ntr1/.sebastian/skills \
    theharvester-specification

echo "✅ 打包完成: $OUT_FILE"
echo "   大小: $(du -h "$OUT_FILE" | cut -f1)"
echo
echo "🚀 迁移到其他主机后执行："
echo "   tar -xzf $(basename "$OUT_FILE") -C ~/.sebastian/skills/"
echo "   bash ~/.sebastian/skills/theharvester-specification/scripts/setup.sh"
