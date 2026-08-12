#!/usr/bin/env bash
# setup.sh — theHarvester 自包含环境引导脚本
# 功能：在任意主机上为 skill 内置的 theHarvester 源码创建虚拟环境并安装依赖
# 用法：bash setup.sh
# 说明：需要 Python >= 3.12 与 pip 可用；会自动创建 vendor/theHarvester/.venv

# /dev/null is read-only inside the sandbox; use a writable tmp file instead
DEVNULL="/tmp/.sebastian_devnull_setup_$$"
: > "$DEVNULL" 2>&1 || DEVNULL="/tmp/.sebastian_devnull"
trap 'rm -f "$DEVNULL"' EXIT

set -e

# 定位脚本目录（规范化为绝对路径）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
VENDOR_DIR="$SKILL_DIR/vendor/theHarvester"
VENV_DIR="$VENDOR_DIR/.venv"

echo "📁 Skill 目录: $SKILL_DIR"
echo "📁 源码目录:  $VENDOR_DIR"

# 1. 检查源码是否就位
if [ ! -f "$VENDOR_DIR/pyproject.toml" ]; then
    echo "❌ 未找到内置源码 pyproject.toml，请确认 vendor/theHarvester 完整存在" >&2
    exit 1
fi

# 2. 检查 Python 版本
PYTHON_BIN="${PYTHON_BIN:-python3}"
if ! command -v "$PYTHON_BIN" > "$DEVNULL" 2>&1; then
    echo "❌ 未找到 $PYTHON_BIN，请先安装 Python >= 3.12" >&2
    exit 1
fi

PY_VER="$($PYTHON_BIN -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
echo "🐍 Python 版本: $PY_VER"
case "$PY_VER" in
    3.12|3.13|3.14) ;;
    *)
        echo "❌ theHarvester 需要 Python >= 3.12，当前为 $PY_VER" >&2
        exit 1
        ;;
esac

# 3. 创建虚拟环境（如不存在）
if [ ! -x "$VENV_DIR/bin/python" ]; then
    echo "🔧 创建虚拟环境 $VENV_DIR ..."
    "$PYTHON_BIN" -m venv "$VENV_DIR"
    echo "✅ 虚拟环境创建完成"
else
    echo "✅ 虚拟环境已存在"
fi

# 4. 安装依赖（使用 -e 可编辑模式，代码改动即时生效，且无需重复复制）
echo "📦 安装依赖（首次约需 2-5 分钟，视网络而定）..."
if "$VENV_DIR/bin/pip" install -e "$VENDOR_DIR" --quiet; then
    echo "✅ 依赖安装完成"
else
    echo "⚠️ pip 安装失败，尝试使用国内镜像重试..."
    "$VENV_DIR/bin/pip" install -e "$VENDOR_DIR" --quiet \
        -i https://pypi.tuna.tsinghua.edu.cn/simple || {
            echo "❌ 依赖安装失败，请检查网络后重试" >&2
            exit 1
        }
    echo "✅ 依赖安装完成（镜像源）"
fi

# 5. 验证安装
echo "🔍 验证安装..."
if "$VENV_DIR/bin/theHarvester" -h > "$DEVNULL" 2>&1; then
    echo "✅ theHarvester 安装验证通过！"
    echo "  入口: $VENV_DIR/bin/theHarvester"
else
    echo "❌ 安装验证失败，请检查错误信息" >&2
    exit 1
fi
