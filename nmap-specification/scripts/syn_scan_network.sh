: "
name: syn_scan_network.sh
description: 使用Nmap的SYN模式扫描整个网段
parameters: $1=网段地址(例如: 192.168.1.0/24)
"
#!/usr/bin/env bash
# nmap_network_scan.sh — SYN scan network segment for live hosts, open ports, services and OS
# Usage: ./nmap_network_scan.sh <network>
# Example: ./nmap_network_scan.sh 192.168.1.0/24

set -euo pipefail

NETWORK="${1:-}"

if [[ -z "$NETWORK" ]]; then
    echo "Usage: $0 <network>"
    echo "  network: CIDR notation, e.g. 192.168.1.0/24"
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

echo "[*] Scanning network: $NETWORK"
echo "[*] Mode: SYN discovery + port scan + OS & service detection"
echo ""

sudo nmap -sS \
     -O \
     -sV \
     --version-intensity 5 \
     --osscan-limit \
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
