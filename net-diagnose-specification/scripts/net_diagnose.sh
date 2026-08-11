: "
name: net_diagnose.sh
description: 执行全套网络诊断（网卡/网关/DNS/连通性/路由表/MTU）输出结构化报告
parameters: \$1=外部测试目标(默认8.8.8.8), \$2=超时时间秒(默认5)
"
#!/usr/bin/env bash
# net_diagnose.sh — comprehensive network health check
# Usage: ./net_diagnose.sh [target] [timeout_seconds]
# Example: ./net_diagnose.sh
# Example: ./net_diagnose.sh baidu.com 3

set -uo pipefail

# /dev/null is read-only inside the sandbox; use a writable tmp file instead
DEVNULL="/tmp/.sebastian_devnull_$$"
: > "$DEVNULL" 2>&1 || DEVNULL="/tmp/.sebastian_devnull"
trap 'rm -f "$DEVNULL"' EXIT

TARGET="${1:-8.8.8.8}"
TIMEOUT="${2:-5}"

echo "=============================================="
echo "  网络综合诊断报告"
echo "  时间: $(date '+%Y-%m-%d %H:%M:%S %Z')"
echo "=============================================="

# ---------- 1. 网卡状态 ----------
echo ""
echo "[1/7] 网卡状态 (ip -br addr)"
ip -br addr 2>"$DEVNULL" | grep -v "^lo" || echo "  [!] 无法获取网卡信息"

# ---------- 2. 默认网关 ----------
echo ""
echo "[2/7] 默认网关 (ip route)"
GW=$(ip route 2>"$DEVNULL" | awk '/^default/{print $3; exit}')
if [[ -n "$GW" ]]; then
    echo "  默认网关: $GW"
else
    echo "  [!] 未找到默认网关"
fi

# ---------- 3. 网关连通性 ----------
echo ""
echo "[3/7] 网关连通性 (ping)"
if [[ -n "$GW" ]]; then
    if ping -c 2 -W "$TIMEOUT" "$GW" >"$DEVNULL" 2>&1; then
        echo "  ✅ 网关 $GW 连通正常"
    else
        echo "  ❌ 网关 $GW 无响应"
    fi
else
    echo "  [-] 无网关可测试"
fi

# ---------- 4. DNS 解析 ----------
echo ""
echo "[4/7] DNS 解析 ($TARGET)"
if command -v getent &>"$DEVNULL"; then
    RESOLVED=$(getent hosts "$TARGET" 2>"$DEVNULL" | awk '{print $1; exit}')
    if [[ -n "$RESOLVED" ]]; then
        echo "  ✅ $TARGET -> $RESOLVED"
    else
        echo "  ❌ $TARGET 解析失败"
    fi
elif command -v nslookup &>"$DEVNULL"; then
    RESOLVED=$(nslookup "$TARGET" 2>"$DEVNULL" | awk '/^Address: /{print $2; exit}')
    if [[ -n "$RESOLVED" ]]; then
        echo "  ✅ $TARGET -> $RESOLVED"
    else
        echo "  ❌ $TARGET 解析失败"
    fi
else
    echo "  [-] 无 DNS 解析工具"
fi

# ---------- 5. 外部连通性 (ICMP) ----------
echo ""
echo "[5/7] 外部连通性 ICMP (ping $TARGET)"
if ping -c 2 -W "$TIMEOUT" "$TARGET" >"$DEVNULL" 2>&1; then
    PING_MS=$(ping -c 2 -W "$TIMEOUT" "$TARGET" 2>"$DEVNULL" | tail -1 | awk -F'/' '{printf "%.1f", $5}')
    echo "  ✅ $TARGET 可达 (avg ${PING_MS} ms)"
else
    echo "  ⚠️  $TARGET 无 ICMP 响应 (可能被禁ping，用HTTP验证)"
fi

# ---------- 6. 外部连通性 (HTTP) ----------
echo ""
echo "[6/7] 外部连通性 HTTP"
if [[ "$TARGET" =~ ^[0-9.]+$ ]]; then
    HTTP_TARGET="http://$TARGET"
else
    HTTP_TARGET="http://$TARGET"
fi
HTTP_CODE=$(curl -s -m "$TIMEOUT" -o "$DEVNULL" -w "%{http_code}" "$HTTP_TARGET" 2>"$DEVNULL")
if [[ "$HTTP_CODE" =~ ^[0-9]+$ ]] && [[ "$HTTP_CODE" != "000" ]]; then
    echo "  ✅ HTTP $HTTP_TARGET -> $HTTP_CODE"
else
    echo "  ⚠️  HTTP 连接失败 (超时或拒绝)"
fi

# ---------- 7. 路由表 & MTU ----------
echo ""
echo "[7/7] 路由表 & MTU"
ip route 2>"$DEVNULL" | head -10 || echo "  [!] 无法读取路由表"
echo "  --- MTU ---"
ip -br link 2>"$DEVNULL" | awk '{print "  " $1 " MTU: " $NF}' || true

echo ""
echo "=============================================="
echo "  诊断完成"
echo "=============================================="
