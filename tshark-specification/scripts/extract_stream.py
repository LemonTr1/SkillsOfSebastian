#!/usr/bin/env python3
"""
tshark-specification :: extract_stream.py
Reassemble and extract a single TCP or UDP stream from a pcap file
(Wireshark "Follow Stream" equivalent).

Uses: tshark -q -z follow,<proto>,<mode>,<index> -r <pcap>

Usage:
    python3 extract_stream.py --pcap /tmp/cap.pcap --stream 0 --proto tcp --mode ascii --outdir /tmp/streams
    python3 extract_stream.py --pcap /tmp/cap.pcap --stream 2 --proto tcp --mode hex --outdir /tmp/streams

Exit codes:
    0  success
    1  invalid pcap / bad args
    2  tshark error (e.g. stream index out of range)
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


def get_stream_count(pcap: str, proto: str) -> int:
    """Query total stream count to validate index bounds."""
    r = subprocess.run(
        ["tshark", "-r", pcap, "-q", "-z", f"follow,{proto},ascii,0"],
        capture_output=True, text=True, timeout=300,
    )
    # If stream 0 doesn't exist, tshark returns non-zero / empty
    return 1 if r.returncode == 0 else 0


def extract_stream(pcap: str, index: int, proto: str, mode: str) -> dict:
    cmd = ["tshark", "-r", pcap, "-q", "-z", f"follow,{proto},{mode},{index}"]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.strip() or f"tshark follow failed (rc={r.returncode})")

    text = r.stdout
    # Parse header info: Filter / Node lines
    meta = {"stream_index": index, "protocol": proto, "mode": mode}
    nodes = []
    body_lines = []
    in_body = False
    for line in text.splitlines():
        if line.startswith("Follow:"):
            meta["follow"] = line.strip()
        elif line.startswith("Filter:"):
            meta["filter"] = line.strip()
        elif line.startswith("Node "):
            nodes.append(line.strip())
        elif line.strip() and not line.startswith("="):
            in_body = True
            body_lines.append(line.rstrip("\n"))

    meta["nodes"] = nodes
    # Strip the "N: " prefix used for stream data lines in follow output
    payload_parts = []
    for ln in body_lines:
        m = re.match(r"^\s*\d+:\s?(.*)$", ln)
        if m:
            payload_parts.append(m.group(1))
    meta["content"] = "\n".join(payload_parts) if payload_parts else "\n".join(body_lines)
    return meta


def main():
    parser = argparse.ArgumentParser(description="TShark follow-stream extractor")
    parser.add_argument("--pcap", required=True, help="Path to pcap/pcapng file")
    parser.add_argument("--stream", type=int, required=True, help="Stream index (0-based)")
    parser.add_argument("--proto", choices=["tcp", "udp"], default="tcp", help="Transport protocol")
    parser.add_argument("--mode", choices=["ascii", "hex", "raw"], default="ascii", help="Follow mode")
    parser.add_argument("--outdir", default="/tmp/streams", help="Directory to save extracted content")
    args = parser.parse_args()

    pcap = str(Path(args.pcap).resolve())
    if not validate_pcap(Path(pcap)):
        print(json.dumps({"error": "Invalid or missing pcap file", "path": pcap}, indent=2))
        sys.exit(1)

    try:
        result = extract_stream(pcap, args.stream, args.proto, args.mode)
    except RuntimeError as e:
        print(json.dumps({"error": str(e)}, indent=2))
        sys.exit(2)

    outdir = Path(args.outdir).resolve()
    try:
        outdir.mkdir(parents=True, exist_ok=True)
    except Exception as e:
        print(json.dumps({"error": f"Cannot create output dir: {e}"}, indent=2))
        sys.exit(1)

    out_file = outdir / f"stream_{args.stream}_{args.proto}_{args.mode}.txt"
    out_file.write_text(result.get("content", ""), encoding="utf-8", errors="replace")

    print(json.dumps({
        "status": "ok",
        "stream_index": args.stream,
        "protocol": args.proto,
        "mode": args.mode,
        "nodes": result["nodes"],
        "filter": result.get("filter", ""),
        "content_length": len(result.get("content", "")),
        "saved_to": str(out_file),
        "preview": result.get("content", "")[:800],
    }, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
