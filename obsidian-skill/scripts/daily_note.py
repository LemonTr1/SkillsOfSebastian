#!/usr/bin/env python3
"""创建/打开 Obsidian 每日日记。

用法:
    python daily_note.py --vault /path/to/vault [--daily-dir Daily] [--template Templates/daily.md]

- 文件名: YYYY-MM-DD.md
- 已存在时不覆盖, 仅打印路径(便于外部打开)
- 模板支持 {{date}} {{yesterday}} {{tomorrow}}
仅依赖标准库。
"""
import argparse
import sys
from datetime import datetime, timedelta
from pathlib import Path

DEFAULT_TEMPLATE = """---
created: {{date}}
tags:
  - daily
---

# {{date}}

## 今日三件事

- [ ]
- [ ]
- [ ]

## 日志

-

## 待跟进

- [ ]

## 关联

- 昨天: [[{{yesterday}}]]
- 明天: [[{{tomorrow}}]]
"""


def main() -> int:
    ap = argparse.ArgumentParser(description="Create or locate today's daily note.")
    ap.add_argument("--vault", required=True)
    ap.add_argument("--daily-dir", default="Daily")
    ap.add_argument("--template", help="模板路径(vault 内相对路径)")
    ap.add_argument("--date", help="指定日期 YYYY-MM-DD, 默认今天")
    args = ap.parse_args()

    vault = Path(args.vault).expanduser().resolve()
    if not vault.is_dir():
        print(f"error: vault 不存在: {vault}", file=sys.stderr)
        return 1

    day = datetime.strptime(args.date, "%Y-%m-%d") if args.date else datetime.now()
    date_str = day.strftime("%Y-%m-%d")
    target = vault / args.daily_dir / f"{date_str}.md"

    if target.exists():
        print(f"exists: {target.relative_to(vault)}")
        return 0

    body = DEFAULT_TEMPLATE
    if args.template:
        tpath = vault / args.template
        if not tpath.is_file():
            print(f"error: 模板不存在: {tpath}", file=sys.stderr)
            return 1
        body = tpath.read_text(encoding="utf-8")

    body = (body.replace("{{date}}", date_str)
                .replace("{{yesterday}}", (day - timedelta(days=1)).strftime("%Y-%m-%d"))
                .replace("{{tomorrow}}", (day + timedelta(days=1)).strftime("%Y-%m-%d")))

    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(body, encoding="utf-8")
    print(f"created: {target.relative_to(vault)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
