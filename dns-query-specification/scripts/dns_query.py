#!/usr/bin/env python3
"""
dns-query-skill :: dns_query.py
Flexible DNS query tool. Supports forward/reverse lookups, multiple record
types, custom servers and batch domain resolution.

Usage:
    python3 dns_query.py --name example.com --type A
    python3 dns_query.py --name 8.8.8.8 --type PTR
    python3 dns_query.py --name example.com --type MX --server 8.8.8.8
    python3 dns_query.py --batch /tmp/domains.txt --type A --server 8.8.8.8

Exit codes:
    0  success
    1  bad arguments / path escape
    2  no dig/nslookup/host tool found
    3  query failed (timeout / NXDOMAIN / SERVFAIL)
"""
import argparse
import json
import shutil
import subprocess
import sys
from pathlib import Path


def find_tool() -> str | None:
    """Return the best available DNS lookup tool."""
    for tool in ("dig", "nslookup", "host"):
        if shutil.which(tool):
            return tool
    return None


def _run(cmd: list, timeout: int) -> dict:
    """Run subprocess with graceful timeout handling."""
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout + 5)
        return {
            "returncode": result.returncode,
            "stdout": result.stdout.strip(),
            "stderr": result.stderr.strip(),
            "timed_out": False,
        }
    except subprocess.TimeoutExpired:
        return {
            "returncode": 124,
            "stdout": "",
            "stderr": f"Command timed out after {timeout + 5}s",
            "timed_out": True,
        }


def query_dig(name: str, qtype: str, server: str | None, timeout: int) -> dict:
    cmd = ["dig", "+noall", "+answer", "+comments", "+time=" + str(timeout), "+tries=1"]
    if server:
        cmd += ["@" + server]
    # PTR queries must use -x (reverse zone) form, otherwise servers may time out
    if qtype.upper() == "PTR":
        cmd += ["-x", name]
    else:
        cmd += [name, qtype]
    result = _run(cmd, timeout)
    return {
        "tool": "dig",
        "name": name,
        "type": qtype,
        "server": server or "default",
        **result,
    }


def query_nslookup(name: str, qtype: str, server: str | None, timeout: int) -> dict:
    cmd = ["nslookup", "-timeout=" + str(timeout), "-type=" + qtype]
    if server:
        cmd += [name, server]
    else:
        cmd += [name]
    result = _run(cmd, timeout)
    return {
        "tool": "nslookup",
        "name": name,
        "type": qtype,
        "server": server or "default",
        **result,
    }


def query_host(name: str, qtype: str, server: str | None, timeout: int) -> dict:
    cmd = ["host", "-W", str(timeout)]
    if server:
        cmd += [name, server]
    else:
        cmd += ["-t", qtype, name]
    result = _run(cmd, timeout)
    return {
        "tool": "host",
        "name": name,
        "type": qtype,
        "server": server or "default",
        **result,
    }


def main():
    parser = argparse.ArgumentParser(description="DNS query tool")
    parser.add_argument("--name", help="Domain name or IP to query")
    parser.add_argument("--type", default="A", help="Record type (A/AAAA/MX/TXT/NS/CNAME/SOA/PTR)")
    parser.add_argument("--server", default=None, help="DNS server to query")
    parser.add_argument("--batch", default=None, help="File with domain list (one per line)")
    parser.add_argument("--timeout", type=int, default=5, help="Timeout in seconds")
    args = parser.parse_args()

    tool = find_tool()
    if not tool:
        print(json.dumps({"error": "No DNS tool found (dig/nslookup/host)", "exit_code": 2}))
        sys.exit(2)

    if args.batch:
        batch_path = Path(args.batch).resolve()
        if not batch_path.exists():
            print(json.dumps({"error": f"Batch file not found: {batch_path}", "exit_code": 1}))
            sys.exit(1)
        names = [ln.strip() for ln in batch_path.read_text().splitlines() if ln.strip()]
        if not names:
            print(json.dumps({"error": "Batch file is empty", "exit_code": 1}))
            sys.exit(1)
        results = []
        for nm in names:
            if tool == "dig":
                results.append(query_dig(nm, args.type, args.server, args.timeout))
            elif tool == "nslookup":
                results.append(query_nslookup(nm, args.type, args.server, args.timeout))
            else:
                results.append(query_host(nm, args.type, args.server, args.timeout))
        print(json.dumps({"tool": tool, "batch": str(batch_path), "count": len(results), "results": results}, indent=2))
        sys.exit(0)

    if not args.name:
        print(json.dumps({"error": "Missing --name (or use --batch)", "usage": "dns_query.py --name <domain|ip> [--type A] [--server DNS] [--timeout 5]", "exit_code": 1}))
        sys.exit(1)

    if tool == "dig":
        res = query_dig(args.name, args.type, args.server, args.timeout)
    elif tool == "nslookup":
        res = query_nslookup(args.name, args.type, args.server, args.timeout)
    else:
        res = query_host(args.name, args.type, args.server, args.timeout)

    # Heuristic failure detection
    stdout = res["stdout"].lower()
    failed = res["returncode"] != 0 or res.get("timed_out", False)
    if "nxdomain" in stdout or "servfail" in stdout or "no answer" in stdout:
        failed = True
    res["failed"] = failed
    res["exit_code"] = 3 if failed else 0

    print(json.dumps(res, indent=2))
    sys.exit(res["exit_code"])


if __name__ == "__main__":
    main()
