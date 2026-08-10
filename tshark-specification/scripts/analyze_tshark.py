#!/usr/bin/env python3
"""
tshark-specification :: analyze_tshark.py
Deep offline pcap analysis using TShark statistics modules:
  - Protocol hierarchy   (tshark -q -z io,phs)
  - Conversations        (tshark -q -z conv,tcp / conv,udp / conv,ip)
  - Endpoints            (tshark -q -z endpoints,ip)
  - Expert info          (tshark -q -z expert,error)
  - Field extraction     (tshark -T json -e <field> ... with optional display filter)

Usage:
    python3 analyze_tshark.py --pcap /tmp/cap.pcap --format text --top 15
    python3 analyze_tshark.py --pcap /tmp/cap.pcap --format json
    python3 analyze_tshark.py --pcap /tmp/dns.pcap --filter dns --fields "dns.qry.name,ip.src,ip.dst"

Exit codes:
    0  success
    1  invalid pcap / missing file
    2  tshark error
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

PCAP_MAGIC = b"\xa1\xb2\xc3\xd4"
PCAP_MAGIC_LE = b"\xd4\xc3\xb2\xa1"
PCAPNG_MAGIC = b"\x0a\x0d\x0d\x0a"


def validate_pcap(p: Path) -> bool:
    if not p.exists():
        return False
    try:
        with open(p, "rb") as f:
            hdr = f.read(4)
    except OSError:
        return False
    return hdr in (PCAP_MAGIC, PCAP_MAGIC_LE, PCAPNG_MAGIC)


def run_tshark(args: list) -> str:
    r = subprocess.run(["tshark", "-r", str(args[0])] + args[1:],
                       capture_output=True, text=True, timeout=600)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip() or f"tshark failed (rc={r.returncode})")
    return r.stdout


def parse_phs(text: str) -> list:
    """Parse `-z io,phs` -> [{protocol, packets, percent, bytes}, ...]"""
    rows = []
    for line in text.splitlines():
        line = line.rstrip()
        m = re.match(r"^\s*(\S+)\s+(\d+)\s+([\d.]+)%\s+([\d.]+\s+\S+)", line)
        if m:
            rows.append({
                "protocol": m.group(1),
                "packets": int(m.group(2)),
                "percent": float(m.group(3)),
                "bytes": m.group(4),
            })
    return rows


def parse_conv(text: str, proto: str) -> list:
    """Parse `-z conv,<proto>` -> [{src, dst, frames, bytes, rel_start, duration}, ...]"""
    rows = []
    for line in text.splitlines():
        line = line.strip()
        if "<->" not in line:
            continue
        left, right = line.split("<->", 1)
        src = left.strip()
        parts = right.split()
        if not parts:
            continue
        dst = parts[0]
        # Remaining tokens: fwd frames/bytes, rev frames/bytes, total frames/bytes, rel_start, duration
        nums = [t for t in parts[1:] if re.fullmatch(r"\d+(\.\d+)?", t)]
        entry = {"src": src, "dst": dst}
        if len(nums) >= 6:
            entry["frames"] = nums[-4]   # total frames
            entry["bytes"] = nums[-3]    # total bytes
            entry["rel_start"] = nums[-2]
            entry["duration"] = nums[-1]
        elif len(nums) >= 4:
            entry["frames"] = nums[-4]
            entry["bytes"] = nums[-3]
        rows.append(entry)
    return rows


def parse_endpoints(text: str) -> list:
    """Parse `-z endpoints,ip` -> [{address, packets, bytes}, ...]"""
    rows = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("==") or line.startswith("Filter:"):
            continue
        parts = line.split()
        if len(parts) >= 3 and re.match(r"^\d{1,3}(\.\d{1,3}){3}$", parts[0]):
            rows.append({
                "address": parts[0],
                "packets": parts[1],
                "bytes": parts[2],
            })
    return rows


def parse_expert(text: str) -> list:
    """Parse `-z expert,error` -> list of severity:message lines"""
    out = []
    for line in text.splitlines():
        line = line.strip()
        if line and not line.startswith("=="):
            out.append(line)
    return out


def field_extract(pcap: str, fields: list, dfilter: str = "") -> list:
    cmd = ["tshark", "-r", pcap, "-T", "json"]
    for f in fields:
        cmd += ["-e", f]
    if dfilter:
        cmd += ["-Y", dfilter]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=600)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip())
    try:
        return json.loads(r.stdout)
    except json.JSONDecodeError:
        return [{"raw": r.stdout}]


def format_text(report: dict, top: int = 20) -> str:
    lines = []
    lines.append("=" * 60)
    lines.append("TSHARK ANALYSIS REPORT")
    lines.append(f"file: {report['file']}")
    lines.append(f"packets: {report['packet_count']}")
    lines.append("=" * 60)

    phs = report.get("protocol_hierarchy", [])
    if phs:
        lines.append("\n[Protocol Hierarchy]")
        for r in phs[:top]:
            lines.append(f"  {r['protocol']:<12} {r['packets']:>8} pkts  {r['percent']:>6}%  {r['bytes']}")
    conv = report.get("conversations_tcp", []) or report.get("conversations_udp", [])
    if conv:
        lines.append(f"\n[Top {top} Conversations ({report.get('conv_kind', 'tcp')})]")
        for r in conv[:top]:
            lines.append(f"  {r['src']} <-> {r['dst']}  frames={r['frames']}  bytes={r['bytes']}")
    ep = report.get("endpoints", [])
    if ep:
        lines.append(f"\n[Top {top} IP Endpoints]")
        for r in ep[:top]:
            lines.append(f"  {r['address']:<18} packets={r['packets']}  bytes={r['bytes']}")
    ex = report.get("expert_info", [])
    if ex:
        lines.append("\n[Expert Info]")
        for msg in ex[:top]:
            lines.append(f"  ! {msg}")
    if report.get("fields"):
        lines.append("\n[Field Extraction]")
        for item in report["fields"][:top]:
            lines.append(f"  {json.dumps(item, ensure_ascii=False)}")
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="TShark deep pcap analyzer")
    parser.add_argument("--pcap", required=True, help="Path to pcap/pcapng file")
    parser.add_argument("--format", choices=["json", "text"], default="text")
    parser.add_argument("--top", type=int, default=20, help="Top N for text output")
    parser.add_argument("--filter", default="", help="Display filter (e.g. http, dns, tcp.port==443)")
    parser.add_argument("--fields", default="", help="Comma-separated fields to extract (e.g. ip.src,http.request.uri)")
    args = parser.parse_args()

    pcap = str(Path(args.pcap).resolve())
    if not validate_pcap(Path(pcap)):
        print(json.dumps({"error": "Invalid or missing pcap file", "path": pcap}, indent=2))
        sys.exit(1)

    report = {"file": pcap, "packet_count": 0, "conv_kind": "tcp"}
    try:
        # Packet count via capinfos (reliable)
        try:
            cap = subprocess.run(["capinfos", "-c", pcap], capture_output=True, text=True, timeout=60)
            m = re.search(r"Number of packets:\s+(\d+)", cap.stdout)
            report["packet_count"] = int(m.group(1)) if m else 0
        except Exception:
            report["packet_count"] = 0
        # Protocol hierarchy
        report["protocol_hierarchy"] = parse_phs(run_tshark([pcap, "-q", "-z", "io,phs"]))
        # Conversations (tcp, then udp)
        try:
            report["conversations_tcp"] = parse_conv(run_tshark([pcap, "-q", "-z", "conv,tcp"]), "tcp")
        except RuntimeError:
            pass
        try:
            report["conversations_udp"] = parse_conv(run_tshark([pcap, "-q", "-z", "conv,udp"]), "udp")
        except RuntimeError:
            pass
        # Endpoints
        report["endpoints"] = parse_endpoints(run_tshark([pcap, "-q", "-z", "endpoints,ip"]))
        # Expert info (may produce nothing on clean captures)
        try:
            report["expert_info"] = parse_expert(run_tshark([pcap, "-q", "-z", "expert,error"]))
        except RuntimeError:
            report["expert_info"] = []
        # Optional field extraction
        if args.fields:
            fields = [f.strip() for f in args.fields.split(",") if f.strip()]
            report["fields"] = field_extract(pcap, fields, args.filter)
    except RuntimeError as e:
        print(json.dumps({"error": str(e)}, indent=2))
        sys.exit(2)

    if args.format == "json":
        print(json.dumps(report, indent=2, ensure_ascii=False))
    else:
        print(format_text(report, top=args.top))


if __name__ == "__main__":
    main()
