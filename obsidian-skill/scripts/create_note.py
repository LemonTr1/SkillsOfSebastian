#!/usr/bin/env python3
"""在 Obsidian 库中按模板创建笔记。

用法:
    python create_note.py --vault /path/to/vault --title "我的笔记"         [--dir Notes] [--template path/to/template.md] [--tags a,b,c]

特性:
- 自动生成 frontmatter: created / updated / tags
- 文件名自动清理非法字符
- 已存在同名文件时拒绝覆盖(除非 --force)
- 模板中的 {{title}} {{date}} {{time}} 会被替换
仅依赖标准库。
"""
import argparse
import re
import sys
from datetime import datetime
from pathlib import Path

ILLEGAL = re.compile(r'[\\/:*?"<>|]')


def safe_filename(title: str) -> str:
    name = ILLEGAL.sub("-", title).strip().strip(".")
    return name or "untitled"


def split_frontmatter(text: str):
    """返回 (frontmatter_dict_lines, body)。简单按行解析，够用即可。"""
    if text.startswith("---"):
        end = text.find("\n---", 3)
        if end != -1:
            fm = text[3:end].strip("\n")
            body = text[end + 4:]
            return fm, body
    return "", text


def main() -> int:
    ap = argparse.ArgumentParser(description="Create an Obsidian note from a template.")
    ap.add_argument("--vault", required=True, help="vault 根目录")
    ap.add_argument("--title", required=True, help="笔记标题(即文件名)")
    ap.add_argument("--dir", default="Notes", help="vault 内的相对目录")
    ap.add_argument("--template", help="模板文件路径(vault 内相对或绝对)")
    ap.add_argument("--tags", default="", help="逗号分隔的标签, 写入 frontmatter")
    ap.add_argument("--force", action="store_true", help="允许覆盖已存在文件")
    args = ap.parse_args()

    vault = Path(args.vault).expanduser().resolve()
    if not vault.is_dir():
        print(f"error: vault 不存在: {vault}", file=sys.stderr)
        return 1

    now = datetime.now()
    date_str = now.strftime("%Y-%m-%d")
    time_str = now.strftime("%H:%M")
    fname = safe_filename(args.title) + ".md"
    target = vault / args.dir / fname
    target.parent.mkdir(parents=True, exist_ok=True)

    if target.exists() and not args.force:
        print(f"exists: {target.relative_to(vault)} (使用 --force 覆盖)")
        return 2

    # 模板
    body = "# {{title}}\n"
    if args.template:
        tpath = Path(args.template)
        if not tpath.is_absolute():
            tpath = vault / tpath
        if not tpath.is_file():
            print(f"error: 模板不存在: {tpath}", file=sys.stderr)
            return 1
        body = tpath.read_text(encoding="utf-8")

    body = (body.replace("{{title}}", args.title)
                .replace("{{date}}", date_str)
                .replace("{{time}}", time_str))

    tag_list = [t.strip() for t in args.tags.split(",") if t.strip()]
    if tag_list:
        tags_yaml = "tags:\n" + "\n".join(f"  - {t}" for t in tag_list)
    else:
        fm_raw, _ = split_frontmatter(body)
        tags_yaml = "" if "tags:" in fm_raw else "tags:\n  - note"

    if body.startswith("---"):
        # 模板自带 frontmatter: 只补 created/updated(若缺失)
        out = body
        for key in ("created", "updated"):
            if not re.search(rf"^{key}:", out.split("---")[1], re.M):
                out = out.replace("---\n", f"---\n{key}: {date_str}\n", 1)
    else:
        fm = f"---\ncreated: {date_str}\nupdated: {date_str}\n{tags_yaml}\n---\n\n"
        out = fm + body

    target.write_text(out, encoding="utf-8")
    print(f"created: {target.relative_to(vault)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
