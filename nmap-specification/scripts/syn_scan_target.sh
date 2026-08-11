: "
name: syn_scan_target.sh
description: 使用Nmap的TCP connect模式扫描目的主机的全端口信息，服务类型和操作系统类型（非root环境可用）
parameters: $1=目的主机的IP地址
"
#!/usr/bin/env bash
# nmap_fullscan.sh — TCP connect full-port scan with service detection
# Usage: ./nmap_fullscan.sh <target>
# Note: No root required. Uses -sT (TCP connect) instead of -sS (SYN, needs root).
#       -O (OS detection) needs root too, so it's replaced with -A light fingerprints.

set -euo pipefail

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 <target>"
    echo "  target: IP, hostname, or CIDR"
    exit 1
fi

if ! command -v nmap; then
    echo "[!] nmap not found. Install: apt install nmap / brew install nmap"
    exit 1
fi

echo "[*] Starting TCP connect scan on $TARGET ..."
echo "[*] Ports: 1-65535 | Service detect | Light fingerprint (no root)"
echo ""

nmap -sT -Pn -p- -sV --version-intensity 5 --reason -T4 -v --open "$TARGET"

echo ""
echo "[*] Scan complete."
