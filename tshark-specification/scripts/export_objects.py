#!/usr/bin/env python3
"""
tshark-specification :: export_objects.py
Export transferred objects (HTTP files, SMB files, etc.) from a pcap file.

Uses: tshark -q -r <pcap> --export-objects <proto>,<outdir>

Usage:
    python3 export_objects.py --pcap /tmp/cap.pcap --proto http --outdir /tmp/http_objects
    python3 export_objects.py --pcap /tmp/cap.pcap --proto smb --outdir /tmp/smb_objects

Exit codes:
    0  success (objects exported or none found)
    1  invalid pcap / bad args
    2  tshark error
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

PCAP_MAGIC = b"\xa1\xb2\xc3\xd4"
PCAP_MAGIC_LE = b"\xd4\xc3\xb2\xa1"
PCAPNG_MAGIC = b"\x0a\x0d\x0d\x0a"

SUPPORTED = ("http", "smb", "tftp", "dicom", "imf", "smb2")


def validate_pcap(p: Path) -> bool:
    if not p.exists():
        return False
    try:
        with open(p, "rb") as f:
            hdr = f.read(4)
    except OSError:
        return False
    return hdr in (PCAP_MAGIC, PCAP_MAGIC_LE, PCAPNG_MAGIC)


def main():
    parser = argparse.ArgumentParser(description="TShark object exporter")
    parser.add_argument("--pcap", required=True, help="Path to pcap/pcapng file")
    parser.add_argument("--proto", required=True, choices=SUPPORTED,
                        help=f"Protocol to export objects from ({', '.join(SUPPORTED)})")
    parser.add_argument("--outdir", required=True, help="Directory to save exported objects")
    args = parser.parse_args()

    pcap = str(Path(args.pcap).resolve())
    if not validate_pcap(Path(pcap)):
        print(json.dumps({"error": "Invalid or missing pcap file", "path": pcap}, indent=2))
        sys.exit(1)

    outdir = Path(args.outdir).resolve()
    try:
        outdir.mkdir(parents=True, exist_ok=True)
    except Exception as e:
        print(json.dumps({"error": f"Cannot create output dir: {e}"}, indent=2))
        sys.exit(1)

    cmd = ["tshark", "-q", "-r", pcap,
           "--export-objects", f"{args.proto},{outdir}"]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=600)

    files = sorted(p.name for p in outdir.iterdir() if p.is_file()) if outdir.exists() else []

    report = {
        "status": "ok" if r.returncode == 0 else "warning",
        "protocol": args.proto,
        "export_dir": str(outdir),
        "object_count": len(files),
        "objects": files[:100],
        "tshark_stderr": r.stderr.strip()[:500] if r.stderr else "",
    }
    if r.returncode != 0:
        report["error"] = r.stderr.strip()[:1000]
        print(json.dumps(report, indent=2, ensure_ascii=False))
        sys.exit(2)

    print(json.dumps(report, indent=2, ensure_ascii=False))


if __name__ == "__main__":
    main()
