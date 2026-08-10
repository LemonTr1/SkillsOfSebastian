---
name: dns-query-specification
description: DNS查询工具集，支持正向/反向解析、多记录类型查询、批量域名解析
---
# DNS查询技能

## 说明
- 用于DNS解析诊断：正向解析、反向解析、MX/TXT/NS/CNAME等记录查询、批量域名解析
- 依赖 `dig`（bind-utils/dnsutils），若不存在脚本会自动回退到 `nslookup`/`host`

## 可执行脚本
### dns_query.py
- description: 灵活执行DNS查询（A/AAAA/MX/TXT/NS/CNAME/SOA/PTR等）
- parameters:
  - `--name`: 要查询的域名或IP（必填）
  - `--type`: 记录类型，默认 A
  - `--server`: 指定DNS服务器（默认走系统配置）
  - `--batch`: 批量查询模式，从文件读取域名列表（每行一个）
  - `--timeout`: 超时时间（秒，默认 5）
- usage: `python3 ~/.sebastian/skills/dns-query-specification/scripts/dns_query.py --name example.com --type MX`
- usage: `python3 ~/.sebastian/skills/dns-query-specification/scripts/dns_query.py --name 8.8.8.8 --type PTR`
- usage: `python3 ~/.sebastian/skills/dns-query-specification/scripts/dns_query.py --batch /tmp/domains.txt --type A`

## 详细文档
- 位置：`~/.sebastian/skills/dns-query-specification/references/dns-query-guide.md`，使用工具读取

## 典型场景
- 排查域名解析失败（A记录为空 / SERVFAIL / NXDOMAIN）
- 验证 DNS 服务器是否正常工作（dig @8.8.8.8 与本地DNS对比）
- 批量检查多个域名的解析状态
- 反向解析确认IP对应的域名（如验证路由器、服务器身份）
