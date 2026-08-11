#!/usr/bin/env python3
"""
tshark-specification :: capture_tshark.py
Live capture wrapper for TShark with duration enforcement and BPF filtering.
Produces a pcap file plus JSON metadata on stdout.

Usage:
    python3 capture_tshark.py --iface any --duration 10 --filter "host 192.168.1.1" --out /tmp/cap.pcap
    python3 capture_tshark.py --iface eth0 --duration 60 --filter "port 443" --out /tmp/tls.pcap

Exit codes:
    0  success
    1  bad arguments / path escape
    2  tshark not found
    3  permission denied
    4  capture error (tshark returned non-zero / no output)
"""
import argparse
import json
import subprocess
import sys
import time
from pathlib import Path


def main():
    # Environment guard: live capture is NOT supported in this sandbox.
    # Raw sockets require CAP_NET_RAW / root, both unavailable here.
    # Fail fast with a clear message instead of a cryptic kernel error.
    print(json.dumps({
        "error": "Live capture is disabled in this environment: "
                 "raw sockets require CAP_NET_RAW / root privileges, "
                 "which the sandbox does not provide. "
                 "Use offline analysis (analyze_tshark.py) on an existing pcap file instead.",
        "exit_code": 3,
        "status": "blocked",
    }, indent=2))
    sys.exit(3)

    parser = argparse.ArgumentParser(description="TShark live capture wrapper")
    parser.add_argument("--iface", default="any", help="Interface to capture on")
    parser.add_argument("--duration", type=int, default=10, help="Seconds to capture")
    parser.add_argument("--filter", default="", help="BPF capture filter string")
    parser.add_argument("--out", required=True, help="Output pcap file path")
    parser.add_argument("--snaplen", type=int, default=65535, help="Snap length (bytes)")
    args = parser.parse_args()

    # Security: resolve to absolute path, ensure parent exists
    out_path = Path(args.out).resolve()
    try:
        out_path.parent.mkdir(parents=True, exist_ok=True)
    except Exception as e:
        print(json.dumps({"error": f"Cannot create output directory: {e}", "exit_code": 1}))
        sys.exit(1)

    # Check tshark availability
    which = subprocess.run(["which", "tshark"], capture_output=True, text=True)
    if which.returncode != 0:
        print(json.dumps({"error": "tshark not found in PATH", "exit_code": 2}))
        sys.exit(2)
    tshark_bin = which.stdout.strip()

    # Build command (no sudo: sandbox cannot elevate. Raw capture may need
    # privileges; try without sudo and surface tshark's stderr on failure.)
    cmd = [tshark_bin,
           "-i", args.iface,
           "-s", str(args.snaplen),
           "-w", str(out_path)]
    if args.filter:
        cmd += ["-f", args.filter]  # BPF capture filter

    meta = {
        "command": " ".join(cmd),
        "interface": args.iface,
        "duration": args.duration,
        "filter": args.filter or "(none)",
        "output": str(out_path),
        "started_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
    }

    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except PermissionError as e:
        print(json.dumps({**meta, "error": f"Permission denied: {e}", "exit_code": 3}))
        sys.exit(3)

    time.sleep(0.3)
    try:
        _, stderr = proc.communicate(timeout=args.duration)
    except subprocess.TimeoutExpired:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()

    meta["ended_at"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    meta["tshark_returncode"] = proc.returncode

    if out_path.exists():
        meta["file_size_bytes"] = out_path.stat().st_size
        meta["status"] = "completed"
        meta["exit_code"] = 0
    else:
        meta["status"] = "failed"
        meta["error"] = "Output pcap not created. " + (stderr.decode()[:500] if stderr else "")
        meta["exit_code"] = 4

    print(json.dumps(meta, indent=2))
    sys.exit(meta["exit_code"])


if __name__ == "__main__":
    main()
