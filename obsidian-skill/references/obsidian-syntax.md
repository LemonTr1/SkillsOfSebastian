# Obsidian 语法速查（Syntax Reference）

## 内部链接（Wiki Links）

```markdown
[[笔记名称]]                  # 基础链接
[[笔记名称|显示文字]]          # 带别名
[[笔记名称#标题]]              # 链接到指定标题
[[笔记名称#标题|显示文字]]      # 标题 + 别名
[[#本文件内的标题]]            # 同文档内跳转
```

注意：链接按**文件名**（不含 `.md`）解析，与所在目录无关；同名文件会触发 Obsidian 的选择器。

## 嵌入（Embed）

```markdown
![[笔记名称]]          # 嵌入整篇笔记
![[图片.png]]          # 嵌入图片（支持 png/jpg/svg 等）
![[笔记#某个标题]]      # 仅嵌入该标题下内容
![[笔记#^块ID]]        # 嵌入某个块（块ID写法：在块尾加 ^id）
```

## 标签（Tags）

- 行内：`#reading`、`#project/alpha`（`/` 表示层级）
- frontmatter 中推荐使用列表形式：

```yaml
---
tags:
  - reading
  - project/alpha
---
```

- 标签内不能含空格；需要空格用 `-` 或 `_` 连接，如 `#deep-learning`。

## 属性（Properties / YAML Frontmatter）

文件**最顶部**，用 `---` 包围：

```yaml
---
title: 示例笔记
aliases: [别名1, 别名2]
created: 2026-09-09
updated: 2026-09-09
tags:
  - note/example
status: draft        # draft | active | done | archived
cssclasses: [wide]
---
```

常见键名约定：`title`、`aliases`、`created`、`updated`、`tags`、`status`、`type`、`source`、`related`。
Obsidian 支持的值类型：文本、数字、布尔（`true/false`）、日期（`YYYY-MM-DD`）、列表、链接（`[[...]]`）。

## Callout（标注块）

```markdown
> [!note] 标题可省略
> 内容支持 **Markdown** 和 `[[链接]]`。

> [!warning]+ 可折叠（+ 默认展开，- 折叠）
> 折叠内容
```

常用类型：`note`、`abstract/summary`、`info`、`todo`、`tip/hint`、`success/check`、`question/help`、`warning/caution`、`failure`、`danger`、`bug`、`example`、`quote`。

自定义标题：`> [!note] 我的标题`；折叠：`> [!note]+` / `> [!note]-`。

## 其他高频语法

```markdown
- [ ] 待办任务          # 任务列表（可在阅读模式点击勾选）
- [x] 已完成任务

`行内代码`  和  ```代码块（支持 ```python 指定语言）

$$
E = mc^2               # LaTeX（需开启 LaTeX 支持，Obsidian 默认支持）
$$

%% 这是注释，阅读模式不可见 %%
```

## 双向链接与关系图谱

- 正文中的 `[[链接]]` 自动生成反向链接（backlink），无需手动维护。
- 关系图谱按链接聚合；`[[链接|别名]]` 的别名不影响图谱。
- 建议：链接指向**概念/主题**，避免大段 URL 式链接；外部链接用 `[文字](https://...)`。

## 常见坑

1. frontmatter 中 `:` 后必须有空格；含特殊字符的值要加引号。
2. wiki 链接**区分大小写**（取决于操作系统与设置，跨平台建议统一命名）。
3. 文件名中避免 `\/:*?"<>|` 等非法字符；路径分隔用 `/`。
4. 嵌入的块 ID：`某段文字 ^block-id`，ID 全库唯一。
