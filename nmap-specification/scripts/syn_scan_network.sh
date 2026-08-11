: "
name: syn_scan_network.sh
description: 使用Nmap的TCP connect模式扫描整个网段（非root环境可用）
parameters: $1=网段地址(例如: 192.168.1.0/24)
"
#!/usr/bin/env bash
# nmap_network_scan.sh — TCP connect scan network segment for live hosts, open ports and services
# Usage: ./nmap_network_scan.sh <network>
# Example: ./nmap_network_scan.sh 192.168.1.0/24
# Note: No root required. Uses -sT (TCP connect) instead of -sS (SYN, needs root).

set -euo pipefail

NETWORK="${1:-}"

if [[ -z "$NETWORK" ]]; then
    echo "Usage: $0 <network>"
    echo "  network: CIDR notation, e.g. 192.168.1.0/24"
    exit 1
fi

if ! command -v nmap; then
    echo "[!] nmap not found. Install: apt install nmap / brew install nmap"
    exit 1
fi

echo "[*] Scanning network: $NETWORK"
echo "[*] Mode: TCP connect discovery + port scan + service detection (no root)"
echo ""

nmap -sT -Pn \
     -sV \
     --version-intensity 5 \
     --reason \
     -T4 \
     -v \
     --open \
     --max-retries 2 \
     --host-timeout 5m \
     --stats-every 30s \
     "$NETWORK"

echo ""
echo "[*] Scan complete."
