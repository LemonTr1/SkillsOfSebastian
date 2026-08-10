: "
name: syn_scan_target.sh
description: 使用Nmap的SYN模式扫描目的主机的全端口信息，服务类型和操作系统类型
parameters: $1=目的主机的IP地址
"
#!/usr/bin/env bash
# nmap_fullscan.sh — SYN stealth full-port scan with OS & service detection
# Usage: ./nmap_fullscan.sh <target>
# Note: User must have sudo privileges for nmap.

set -euo pipefail

TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
    echo "Usage: $0 <target>"
    echo "  target: IP, hostname, or CIDR"
    exit 1
fi

if ! command -v nmap &>/dev/null; then
    echo "[!] nmap not found. Install: apt install nmap / brew install nmap"
    exit 1
fi

if ! sudo -n true 2>/dev/null; then
    echo "[*] sudo required for SYN scan. Enter password if prompted."
    sudo -v || { echo "[!] sudo authentication failed."; exit 1; }
fi

echo "[*] Starting SYN scan on $TARGET ..."
echo "[*] Ports: 1-65535 | OS detect | Service detect"
echo ""

sudo nmap -sS -p- -O -sV --version-intensity 5 --osscan-limit --reason -T4 -v --open "$TARGET"

echo ""
echo "[*] Scan complete."
