: "
name: trace_route.sh
description: 追踪到目标主机的网络路径，支持ICMP/UDP/TCP三种模式和跳数限制
parameters: \$1=目标主机IP或域名(必填), \$2=模式(icmp/udp/tcp,默认icmp), \$3=最大跳数(默认30)
"
#!/usr/bin/env bash
# trace_route.sh — trace network path to target host
# Usage: ./trace_route.sh <target> [icmp|udp|tcp] [max_hops]
# Example: ./trace_route.sh 8.8.8.8
# Example: ./trace_route.sh 8.8.8.8 tcp 20

set -euo pipefail

TARGET="${1:-}"
MODE="${2:-icmp}"
MAX_HOPS="${3:-30}"

if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 <target> [icmp|udp|tcp] [max_hops]"
    echo "  target:   hostname or IP address"
    echo "  mode:     icmp (default) | udp | tcp"
    echo "  max_hops: max TTL hops (default 30)"
    exit 1
fi

case "$MODE" in
    icmp|udp|tcp) ;;
    *) echo "[!] Invalid mode: $MODE (use icmp/udp/tcp)"; exit 1 ;;
esac

if ! command -v traceroute &>/dev/null; then
    echo "[!] traceroute not found. Install: apt install traceroute"
    exit 1
fi

echo "[*] Traceroute to: $TARGET"
echo "[*] Mode: $MODE | Max hops: $MAX_HOPS"
echo ""

case "$MODE" in
    icmp) sudo -n traceroute -I -m "$MAX_HOPS" -n "$TARGET" 2>/dev/null || traceroute -I -m "$MAX_HOPS" -n "$TARGET" ;;
    udp)  sudo -n traceroute -U -m "$MAX_HOPS" -n "$TARGET" 2>/dev/null || traceroute -U -m "$MAX_HOPS" -n "$TARGET" ;;
    tcp)  sudo -n traceroute -T -m "$MAX_HOPS" -n "$TARGET" 2>/dev/null || traceroute -T -m "$MAX_HOPS" -n "$TARGET" ;;
esac

echo ""
echo "[*] Traceroute complete."
