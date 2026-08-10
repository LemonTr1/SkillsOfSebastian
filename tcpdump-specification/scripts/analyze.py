#!/usr/bin/env python3
"""
tcpdump-skill :: analyze.py
Offline pcap analyzer. Reads a pcap file and produces structured output
without needing live capture privileges.

Usage:
    python3 analyze.py --pcap /tmp/cap.pcap --format json
    python3 analyze.py --pcap /tmp/cap.pcap --format text --top 20

Dependencies: tcpdump (for -r parsing), optionally scapy (for deep inspection)
"""
import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path
from collections import Counter

PCAP_MAGIC = b"\xa1\xb2\xc3\xd4"  # big-endian pcap magic
PCAP_MAGIC_LE = b"\xd4\xc3\xb2\xa1"  # little-endian

def validate_pcap(pcap_path: Path) -> bool:
    if not pcap_path.exists():
        return False
    with open(pcap_path, "rb") as f:
        header = f.read(4)
    return header in (PCAP_MAGIC, PCAP_MAGIC_LE)

def read_packets_text(pcap_path: Path) -> list[dict]:
    """Use tcpdump -r to produce human-readable lines, then parse."""
    result = subprocess.run(
        ["tcpdump", "-r", str(pcap_path), "-nn", "-tttt"],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        return [{"error": result.stderr.strip()}]

    packets = []
    for line in result.stdout.strip().splitlines():
        if not line or "reading from" in line.lower():
            continue
        # Parse: "2024-01-15 10:23:45.123456 IP 1.2.3.4.56789 > 5.6.7.8.80: Flags [S], seq ..."
        m = re.match(
            r"^(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2}:\d{2}\.\d+)\s+"
            r"(IP6?|ARP)\s+(\S+)\s+([><])\s+(\S+):(.*)$",
            line
        )
        if m:
            packets.append({
                "date": m.group(1),
                "time": m.group(2),
                "proto_l3": m.group(3),
                "src": m.group(4),
                "direction": m.group(5),
                "dst": m.group(6),
                "info": m.group(7).strip(),
                "raw": line,
            })
        else:
            packets.append({"raw": line})
    return packets

def summarize(packets: list[dict]) -> dict:
    total = len(packets)
    l3_counter = Counter(p.get("proto_l3", "unknown") for p in packets)
    src_counter = Counter(p.get("src", "unknown") for p in packets if "src" in p)
    dst_counter = Counter(p.get("dst", "unknown") for p in packets if "dst" in p)

    # Extract TCP flags from info field
    flags = {"SYN": 0, "ACK": 0, "PSH": 0, "FIN": 0, "RST": 0, "URG": 0}
    for p in packets:
        info = p.get("info", "")
        for flag in flags:
            if f"Flags [{flag}" in info or f"[{flag}.]" in info or f"[.{flag}]" in info:
                flags[flag] += 1

    # Detect anomalies
    anomalies = []
    if flags["RST"] > total * 0.3 and total > 0:
        anomalies.append(f"High RST ratio ({flags['RST']}/{total}) — possible port scan or connection issues")
    if l3_counter.get("ARP", 0) > 10:
        anomalies.append(f"High ARP activity ({l3_counter['ARP']} packets)")

    return {
        "total_packets": total,
        "layer3_breakdown": dict(l3_counter),
        "top_sources": dict(src_counter.most_common(10)),
        "top_destinations": dict(dst_counter.most_common(10)),
        "tcp_flags": flags,
        "anomalies": anomalies,
        "sample_packets": packets[:5],
    }

def format_text(summary: dict, top: int = 20) -> str:
    lines = [
        f"Total packets: {summary['total_packets']}",
        f"Layer-3 breakdown: {summary['layer3_breakdown']}",
        "",
        "Top sources:",
    ]
    for src, cnt in list(summary["top_sources"].items())[:top]:
        lines.append(f"  {src}: {cnt}")
    lines.append("")
    lines.append("Top destinations:")
    for dst, cnt in list(summary["top_destinations"].items())[:top]:
        lines.append(f"  {dst}: {cnt}")
    lines.append("")
    lines.append("TCP flags:")
    for flag, cnt in summary["tcp_flags"].items():
        lines.append(f"  {flag}: {cnt}")
    if summary["anomalies"]:
        lines.append("")
        lines.append("Anomalies detected:")
        for a in summary["anomalies"]:
            lines.append(f"  ! {a}")
    return "\n".join(lines)

def main():
    parser = argparse.ArgumentParser(description="pcap analyzer")
    parser.add_argument("--pcap", required=True, help="Path to pcap file")
    parser.add_argument("--format", choices=["json", "text"], default="text", help="Output format")
    parser.add_argument("--top", type=int, default=20, help="Top N entries for text mode")
    args = parser.parse_args()

    pcap_path = Path(args.pcap).resolve()
    if not validate_pcap(pcap_path):
        print(json.dumps({"error": "Invalid or missing pcap file", "path": str(pcap_path)}))
        sys.exit(1)

    packets = read_packets_text(pcap_path)
    if packets and "error" in packets[0]:
        print(json.dumps({"error": packets[0]["error"]}))
        sys.exit(2)

    summary = summarize(packets)

    if args.format == "json":
        print(json.dumps(summary, indent=2))
    else:
        print(format_text(summary, top=args.top))

if __name__ == "__main__":
    main()
