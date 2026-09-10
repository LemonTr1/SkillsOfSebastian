#!/usr/bin/env python3
"""扫描 Obsidian 库, 报告失效的 wiki 链接、空文件与孤立笔记。

用法:
    python check_links.py --vault /path/to/vault [--dir .] [--json]

检查项:
1. 失效链接: [[目标]] 在库中不存在同名 .md
2. 空文件:  内容(去 frontmatter 后)基本为空
3. 孤立笔记: 没有任何入链/出链(可选, 信息性)
仅依赖标准库。
"""
import argparse
import json
import re
import sys
from pathlib import Path

WIKILINK = re.compile(r"(?<!\!)\[\[([^\[\]|#]+)(?:#[^\[\]]*)?(?:\|[^\[\]]*)?\]\]")


def strip_frontmatter(text: str) -> str:
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            return text[end + 4:]
    return text


def main() -> int:
    ap = argparse.ArgumentParser(description="Report broken links & empty notes in a vault.")
    ap.add_argument("--vault", required=True)
    ap.add_argument("--dir", default=".", help="扫描的子目录(vault 内相对)")
    ap.add_argument("--json", action="store_true", help="以 JSON 输出")
    args = ap.parse_args()

    root = Path(args.vault).expanduser().resolve()
    scan = (root / args.dir).resolve()
    if not scan.is_dir():
        print(f"error: 目录不存在: {scan}", file=sys.stderr)
        return 1

    notes = {p.stem: p for p in scan.rglob("*.md") if p.is_file()}
    broken, empty, links_out = [], [], {}

    for stem, p in notes.items():
        text = p.read_text(encoding="utf-8", errors="replace")
        links = [m.group(1).strip() for m in WIKILINK.finditer(text)]
        links_out[stem] = links
        for target in links:
            if target not in notes:
                broken.append({"note": str(p.relative_to(root)), "target": target})
        if not strip_frontmatter(text).strip():
            empty.append(str(p.relative_to(root)))

    linked = {t for ls in links_out.values() for t in ls if t in notes}
    orphans = sorted(s for s in notes if s not in linked and not links_out[s])

    report = {
        "vault": str(root),
        "notes_scanned": len(notes),
        "broken_links": broken,
        "empty_notes": empty,
        "orphan_notes": orphans,
    }

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"扫描 {report['notes_scanned']} 篇笔记")
        print(f"\n失效链接 ({len(broken)}):")
        for b in broken:
            print(f"  - {b['note']}  ->  [[{b['target']}]]")
        print(f"\n空笔记 ({len(empty)}):")
        for e in empty:
            print(f"  - {e}")
        print(f"\n孤立笔记 ({len(orphans)}, 信息性):")
        for o in orphans:
            print(f"  - {o}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
