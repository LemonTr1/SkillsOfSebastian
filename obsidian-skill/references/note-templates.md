# 笔记模板库（Note Templates）

使用方式：复制对应模板 → 替换 `{{占位符}}` → 删除不需要的区块。
配合 `scripts/create_note.py` 的 `--template` 参数可直接套用。

## 1. 标准笔记（默认模板）

```markdown
---
created: {{date}}
updated: {{date}}
tags:
  - note
status: draft
---

# {{title}}

## 概述

## 要点

- 

## 相关

- [[]]
```

## 2. 日记（Daily Note）

```markdown
---
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

- 昨天：[[{{yesterday}}]]
- 明天：[[{{tomorrow}}]]
```

建议开启 Obsidian「日记」核心插件，设置日期格式 `YYYY-MM-DD` 与模板文件路径，脚本 `daily_note.py` 与之兼容。

## 3. 会议纪要（Meeting）

```markdown
---
created: {{date}}
type: meeting
attendees:
  - 
tags:
  - meeting
status: draft
---

# 会议：{{title}}

- **时间**：{{date}} {{time}}
- **参与人**：

## 议题

1. 

## 结论与行动项

- [ ] （负责人 / 截止时间）

## 参考资料

- 
```

## 4. 文献/阅读笔记（Literature Note）

```markdown
---
created: {{date}}
type: literature
source: 
author: 
year: 
rating: 
tags:
  - literature
status: draft
---

# {{title}}

## 摘录

> 

## 我的理解

## 可以应用到哪里

- [[]]
```

## 5. 项目笔记（Project）

```markdown
---
created: {{date}}
type: project
status: active
deadline: 
tags:
  - project
---

# {{title}}

## 目标

## 现状

## 下一步

- [ ] 

## 相关笔记

- 
```

## 6. MOC（Map of Content，内容地图）

```markdown
---
created: {{date}}
type: moc
tags:
  - moc
---

# {{title}} · 内容地图

## 核心

- [[]]

## 主题分区

### 子主题 A

- [[]]
- [[]]

## 待整理

- [ ] 
```

MOC 维护原则：只放**入口链接**与一句话说明；每个链接归属唯一分区；定期把「待整理」清空。

## 占位符约定

| 占位符 | 含义 |
|---|---|
| `{{date}}` | 当天日期 `YYYY-MM-DD` |
| `{{time}}` | 当前时间 `HH:MM` |
| `{{title}}` | 笔记标题 |
| `{{yesterday}}` / `{{tomorrow}}` | 前/后一天日期（日记用） |
