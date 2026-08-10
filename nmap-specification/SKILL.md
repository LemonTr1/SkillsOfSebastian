---
name: Nmap Specification
description: Nmap使用指南和可执行脚本
---
# 目录
## Nmap命令详细说明书
- 位置：'~/.sebastian/skills/nmap-specification/references/nmap-notification.md'，使用工具读取

## 可执行脚本
- 由于沙箱环境无法获取root权限，对于需要root权限的SYN模式等，提供以下可执行脚本
### syn_scan_network.sh
- description: 使用Nmap的SYN模式扫描整个网段
- parameters: $1=网段地址(例如: 192.168.1.0/24)
- usage: bash ~/.sebastian/skills/nmap-specification/scripts/syn_scan_network.sh <parameters>

### syn_scan_target.sh 
- description: 使用Nmap的SYN模式扫描目的主机的全端口信息，服务类型和操作系统类型
- parameters: $1=目的主机的IP地址
- usage: bash ~/.sebastian/skills/nmap-specification/scripts/syn_scan_target.sh <parameters>

