---
name: net-diagnose-specification
description: 网络综合诊断脚本，一键检查网卡/网关/DNS/连通性/路由表并输出诊断报告
---
# 网络综合诊断技能

## 说明
- 一键执行全套网络自检：网卡状态、IP配置、网关连通、DNS解析、外部连通性、路由表、MTU
- 输出结构化的诊断报告，帮助快速定位网络故障点
- 依赖 `ip`、`ping`、`curl` 等标准网络工具

## 可执行脚本
### net_diagnose.sh
- description: 执行全套网络诊断，输出结构化报告
- parameters:
  - `$1`=外部测试目标（默认 8.8.8.8，可用域名如 baidu.com）
  - `$2`=超时时间（秒，默认 5）
- usage: `bash ~/.sebastian/skills/net-diagnose-specification/scripts/net_diagnose.sh`
- usage: `bash ~/.sebastian/skills/net-diagnose-specification/scripts/net_diagnose.sh baidu.com 3`

## 详细文档
- 位置：`~/.sebastian/skills/net-diagnose-specification/references/net-diagnose-guide.md`，使用工具读取

## 诊断项说明
| 检查项 | 命令 | 判断标准 |
|--------|------|---------|
| 网卡状态 | `ip -br addr` | 有 IP 且 UP |
| 默认网关 | `ip route` | 存在 default 路由 |
| 网关连通 | `ping -c2 网关` | 有回复 |
| DNS 解析 | `getent hosts 目标` | 能解析出 IP |
| 外部连通 | `ping -c2 目标` | 有回复 |
| 外部 HTTP | `curl -I 目标` | HTTP 响应 |
| 路由表 | `ip route` | 正常 |
| MTU | `ip link` | 合理值 |

## 典型场景
- "上不了网"快速定位：网卡问题 / 网关问题 / DNS问题 / 外网问题
- 网络刚配置完的全面验证
- 网络间歇性故障时的基线对比
