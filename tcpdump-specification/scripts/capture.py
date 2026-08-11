#!/usr/bin/env python3
"""
tcpdump-skill :: capture.py
Background-safe packet capture wrapper.
Handles interface selection, BPF validation, duration enforcement,
and clean termination. Outputs capture metadata to stdout (JSON).

Usage:
    python3 capture.py --iface any --duration 10 --filter "port 80" --out /tmp/cap.pcap
    python3 capture.py --iface eth0 --duration 60 --filter "host 8.8.8.8" --out /tmp/dns.pcap

Exit codes:
    0  success
    1  bad arguments / path escape
    2  tcpdump not found
    3  permission denied
    4  capture error (tcpdump returned non-zero)
"""
import argparse
import json
import os
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
                 "Use offline analysis (analyze.py) on an existing pcap file instead.",
        "exit_code": 3,
        "status": "blocked",
    }, indent=2))
    sys.exit(3)

    parser = argparse.ArgumentParser(description="tcpdump capture wrapper")
    parser.add_argument("--iface", default="any", help="Interface to capture on")
    parser.add_argument("--duration", type=int, default=10, help="Seconds to capture")
    parser.add_argument("--filter", default="", help="BPF filter string")
    parser.add_argument("--out", required=True, help="Output pcap file path")
    parser.add_argument("--snaplen", type=int, default=65535, help="Snap length (bytes)")
    args = parser.parse_args()

    # Security: ensure output path is absolute and parent exists
    out_path = Path(args.out).resolve()
    try:
        out_path.parent.mkdir(parents=True, exist_ok=True)
    except Exception as e:
        print(json.dumps({"error": f"Cannot create output directory: {e}", "exit_code": 1}))
        sys.exit(1)

    # Check tcpdump availability
    tcpdump = subprocess.run(["which", "tcpdump"], capture_output=True, text=True)
    if tcpdump.returncode != 0:
        print(json.dumps({"error": "tcpdump not found in PATH", "exit_code": 2}))
        sys.exit(2)

    tcpdump_bin = tcpdump.stdout.strip()

    # Build command (no sudo: sandbox cannot elevate. Raw capture may need
    # privileges; try without sudo and surface tcpdump's stderr on failure.)
    cmd = [
        tcpdump_bin,
        "-i", args.iface,
        "-nn",                    # numeric everything
        "-s", str(args.snaplen),  # full packets
        "-U",                     # packet-level flush
        "-w", str(out_path),      # pcap output
    ]
    if args.filter:
        cmd.append(args.filter)

    meta = {
        "command": " ".join(cmd),
        "interface": args.iface,
        "duration": args.duration,
        "filter": args.filter or "(none)",
        "output": str(out_path),
        "started_at": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
    }

    # Start tcpdump
    try:
        proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    except PermissionError as e:
        print(json.dumps({**meta, "error": f"Permission denied: {e}", "exit_code": 3}))
        sys.exit(3)

    # Wait for warm-up then enforce duration
    time.sleep(0.3)
    try:
        stdout, stderr = proc.communicate(timeout=args.duration)
    except subprocess.TimeoutExpired:
        proc.terminate()
        try:
            proc.wait(timeout=5)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait()

    meta["ended_at"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    meta["tcpdump_returncode"] = proc.returncode

    # Check output file
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
