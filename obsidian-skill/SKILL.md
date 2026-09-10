---
name: obsidian-vault
description: 帮助用户在 Obsidian 库（vault）中创建、组织和管理 Markdown 笔记。适用于：新建笔记/日记、应用模板、编写 YAML frontmatter、维护 wiki 链接与标签、搭建 MOC（内容地图）、整理库结构等任务。当用户提到 Obsidian、笔记库、双链笔记、日记、Zettelkasten、PARA 等关键词时使用。
---

# Obsidian Vault Skill

帮助用户高效使用 Obsidian 管理 Markdown 笔记库。核心原则：**先诊断库结构，再动手；渐进式披露，按需加载参考文档。**

## 何时使用

- 在 Obsidian 库中新建或整理笔记（含日记 daily note）
- 设计或应用笔记模板（会议、文献、项目、人物等）
- 处理 frontmatter（YAML 属性）、标签、wiki 链接 `[[]]`、嵌入 `![[]]`
- 搭建 MOC（Map of Content）或整理库的整体结构
- 批量检查链接、frontmatter 合法性

## 工作流程

1. **定位库根目录**：优先使用用户提供的 vault 路径；未提供时询问。所有脚本默认接收 `--vault` 参数。
2. **了解现有约定**：先列出目录结构（建议深度 ≤2），查看已有笔记的 frontmatter 键名与模板，保持一致而不是另起炉灶。
3. **选择正确参考文档**（见下表），不要一次全部加载。
4. **需要脚本时**：优先调用 `scripts/` 下的现成脚本；简单任务可直接生成 Markdown 文本。

## 参考文档索引（渐进式加载）

| 任务 | 加载 |
|---|---|
| 写/改笔记正文、链接、嵌入、标注（callout）、 frontmatter 语法 | `references/obsidian-syntax.md` |
| 套用或设计模板（日记、会议、文献、项目、MOC 等） | `references/note-templates.md` |
| 整理库结构、分类体系（PARA / Zettelkasten / MOC）、命名与链接策略 | `references/organization-workflows.md` |

## 脚本索引

| 脚本 | 用途 |
|---|---|
| `scripts/create_note.py` | 按模板在指定目录创建笔记，自动填充 frontmatter（创建时间、tags、aliases） |
| `scripts/daily_note.py` | 创建/打开当日日记，支持自定义日记目录与模板 |
| `scripts/check_links.py` | 扫描库中失效的 wiki 链接与空文件，输出报告 |

所有脚本仅依赖 Python 标准库，用法见各脚本 `--help`。

## 核心约定（速查）

- 链接：`[[笔记名]]`，带别名 `[[笔记名|显示文字]]`，嵌入 `![[文件名]]`，跳转到标题 `[[笔记#标题]]`。
- 标签：行内 `#tag`，或 frontmatter 中的 `tags: [a, b]`；子标签用 `/` 分层，如 `#project/alpha`。
- 属性（Properties）：文件顶部 YAML frontmatter，键名用英文小写+下划线，如 `created`、`tags`、`status`。
- 日记文件名默认 `YYYY-MM-DD.md`；任何自动化脚本不得覆盖已存在的笔记，除非用户明确要求。

## 输出规范

- 生成的笔记必须是合法 Markdown，frontmatter 用 `---` 包裹，缩进用空格。
- 创建文件后向用户报告：相对路径、使用的模板、创建/更新了哪些链接。
- 不确定用户库的组织习惯时，先问再改。
