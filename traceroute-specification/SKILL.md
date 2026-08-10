---
name: traceroute-specification
description: 路由追踪工具集，支持ICMP/UDP/TCP模式、指定跳数限制、批量目标追踪
---
# 路由追踪技能

## 说明
- 用于排查网络路径：查看数据包经过哪些路由器、找出路径中的丢包点/延迟点
- 依赖 `traceroute`（Linux）或 `tracert`（Windows）
- 支持 ICMP（默认）、UDP（-U）、TCP（-T）三种模式

## 可执行脚本
### trace_route.sh
- description: 追踪到目标主机的网络路径，支持模式切换和跳数限制
- parameters:
  - `$1`=目标主机IP或域名（必填）
  - `$2`=模式（icmp/udp/tcp，默认 icmp）
  - `$3`=最大跳数（默认 30）
- usage: `bash ~/.sebastian/skills/traceroute-specification/scripts/trace_route.sh 8.8.8.8`
- usage: `bash ~/.sebastian/skills/traceroute-specification/scripts/trace_route.sh 8.8.8.8 tcp 20`
- usage: `bash ~/.sebastian/skills/traceroute-specification/scripts/trace_route.sh example.com udp`

## 详细文档
- 位置：`~/.sebastian/skills/traceroute-specification/references/traceroute-guide.md`，使用工具读取

## 典型场景
- 排查"上网慢"：确认延迟增加发生在哪一跳（运营商出口 vs 目标服务器）
- 确认路由路径：数据包走哪个运营商/区域出口
- 排查丢包：`*` 表示该跳无响应，可能被防火墙屏蔽或路由黑洞
- 对比国内/国际路径：`traceroute` 不同目标（如 baidu.com vs google.com）
