#!/usr/bin/env bash
# pack.sh — 将 theHarvester skill 打包为可迁移的 tar.gz
# 说明：打包时排除 .venv（venv 内路径绑定，跨主机需重建），
#       目标主机解压后运行 setup.sh 自动重建环境即可
# 用法：bash pack.sh [输出目录]（默认 $HOME/.sebastian/skills/）

# 动态定位 skill 目录（规范化为绝对路径，与 setup.sh / theharvester_enum.sh 风格一致）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
SKILL_NAME="$(basename "$SKILL_DIR")"
BASE_DIR="$(dirname "$SKILL_DIR")"

OUT_DIR="${1:-$HOME/.sebastian/skills}"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_FILE="$OUT_DIR/${SKILL_NAME}_$STAMP.tar.gz"

# /dev/null is read-only inside the sandbox; use a writable tmp file instead
DEVNULL="/tmp/.sebastian_pack_devnull_$$"
: > "$DEVNULL" 2>&1 || DEVNULL="/tmp/.sebastian_pack_devnull"
trap 'rm -f "$DEVNULL"' EXIT

echo "📦 正在打包（排除 .venv 以减小体积并保证跨主机可用）..."

# 校验输出目录
if ! command -v tar > "$DEVNULL" 2>&1; then
    echo "❌ 错误: 未找到 tar 命令" >&2
    exit 1
fi
if ! mkdir -p "$OUT_DIR"; then
    echo "❌ 错误: 无法创建输出目录 $OUT_DIR" >&2
    exit 1
fi

# 执行打包；tar 失败时立即报错退出，避免"假成功"
tar --exclude='vendor/theHarvester/.venv' \
    --exclude='__pycache__' \
    -czf "$OUT_FILE" \
    -C "$BASE_DIR" \
    "$SKILL_NAME"
TAR_RC=$?
if [ $TAR_RC -ne 0 ]; then
    echo "❌ 打包失败 (tar exit=$TAR_RC)" >&2
    rm -f "$OUT_FILE" 2> "$DEVNULL"
    exit 1
fi

# 复核产物完整性（关键：确认 .venv 已被排除）
VENV_COUNT=$(tar -tzf "$OUT_FILE" 2> "$DEVNULL" | grep -c '\.venv' || true)
if [ "$VENV_COUNT" -ne 0 ]; then
    echo "⚠️  警告: 产物中检测到 $VENV_COUNT 个 .venv 条目（预期为 0）" >&2
fi

echo "✅ 打包完成: $OUT_FILE"
echo "   大小: $(du -h "$OUT_FILE" | cut -f1)"
echo
echo "🚀 迁移到其他主机后执行："
echo "   tar -xzf $(basename "$OUT_FILE") -C ~/.sebastian/skills/"
echo "   bash ~/.sebastian/skills/$SKILL_NAME/scripts/setup.sh"
