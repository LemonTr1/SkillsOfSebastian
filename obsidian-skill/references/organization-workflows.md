# 库组织工作流（Organization Workflows)

## 第一步：诊断现状

向用户确认（或脚本探测）：
1. vault 根目录下有哪些顶层文件夹？
2. 是否已使用 frontmatter？常用键名是什么？
3. 是否已有模板目录（如 `Templates/`）和日记目录（如 `Daily/`）？

在已有约定之上迭代，不要推倒重来。

## 结构方案对比

### A. 极简扁平（适合 <300 篇）
```
vault/
├── Inbox/          # 临时捕获
├── Notes/          # 全部笔记
├── Daily/          # 日记
└── Attachments/    # 图片附件
```
优点：链接无路径概念，移动笔记不破坏链接。缺点：依赖搜索与 MOC 导航。

### B. PARA（按用途，适合项目制工作）
```
vault/
├── 1 Projects/     # 有截止日期的事
├── 2 Areas/        # 需要长期维护的角色/领域
├── 3 Resources/    # 兴趣与资料
├── 4 Archive/      # 完结/失效
├── Daily/
└── Templates/
```
编号前缀保证排序稳定；项目完结即从 Projects 移入 Archive。

### C. Zettelkasten（按知识生长，适合研究/写作）
```
vault/
├── Fleeting/       # 闪念，未加工
├── Literature/     # 文献笔记（对源材料的转述）
├── Permanent/      # 永久笔记（自己的话、原子化、带链接）
├── MOC/            # 结构笔记
└── Daily/
```
关键规则：永久笔记必须**用自己的话**写、**一条一概念**、**显式链接**到已有笔记。

## 链接与标签分工

- **链接（`[[...]]`）**：表达"笔记之间的关系"，构成图谱与 MOC。
- **标签（`#...`）**：表达"横向属性"，用于查询与过滤（状态、类型、领域）。

推荐标签只保留少数几个维度：
- 类型：`#note` `#daily` `#meeting` `#literature` `#moc`
- 状态（frontmatter `status` 亦可）：`#draft` `#active` `#done`

避免为每篇笔记都打独有的标签——那就成了第二套命名系统。

## 建立 MOC 的步骤

1. 选一个主题，搜索相关标签/关键词，收集候选笔记。
2. 创建 MOC 笔记（用模板 6），按子主题分区。
3. 在相关笔记末尾加一行 `← 返回 [[主题 MOC]]`（可选）。
4. 把 MOC 链接放进主页（Home note）或目录型笔记。

## 清理与维护节奏

- **每次写笔记**：随手加 1–2 个相关链接，比事后补链容易得多。
- **每周**：清空 Inbox；检查 `status: draft` 的笔记。
- **每月**：跑一遍 `scripts/check_links.py` 修失效链接；审视 MOC 是否需要合并/拆分。

## 自动化脚本用法速查

```bash
# 新建标准笔记
python scripts/create_note.py --vault /path/to/vault --dir "Notes" --title "概念笔记" --tags "note,concept"

# 创建今日日记（已存在则只打印路径）
python scripts/daily_note.py --vault /path/to/vault --daily-dir "Daily"

# 检查失效链接与空文件
python scripts/check_links.py --vault /path/to/vault
```
