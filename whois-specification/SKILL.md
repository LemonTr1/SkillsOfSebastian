---
name: whois-specification
description: Whois域名/IP注册信息查询工具，支持RDAP和WHOIS协议
---
# 目录
## Whois查询工具
- 位置：'~/.sebastian/skills/whois-specification/scripts/whois_query.sh'

## 可执行脚本
### whois_query.sh
- description: 查询域名或IP地址的注册信息（注册商、注册时间、到期时间、名称服务器等）
- parameters: $1=域名或IP地址(必填), $2=输出格式(json|text, default: json)
- usage: bash ~/.sebastian/skills/whois-specification/scripts/whois_query.sh example.com

### 支持范围
- 域名：任意顶级域（通过 RDAP 或 whois 服务器查询）
- IP 地址：支持 IPv4 / IPv6（通过 RDAP 查询）
- 输出：JSON 格式结构化结果，包含注册商、注册/到期日期、名称服务器等关键字段
