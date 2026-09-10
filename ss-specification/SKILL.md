---
name: ss-specification
description: Linux ss命令网络套接字分析与诊断工具，支持TCP/UDP连接查询、监听端口、进程关联与套接字统计
---
# 目录
## ss命令技能
- 位置：'~/.sebastian/skills/ss-specification/scripts/ss_socket.sh'

## 可执行脚本
### ss_socket.sh
- description: 查询Linux系统网络套接字状态（TCP/UDP连接、监听端口、套接字统计、进程关联）
- parameters: $1=查询类型(all|tcp|udp|listen|established|summary|pid), $2=过滤端口(可选，如 22 或 22,80)
- usage: bash ~/.sebastian/skills/ss-specification/scripts/ss_socket.sh listen
- 示例:
  - bash ~/.sebastian/skills/ss-specification/scripts/ss_socket.sh all       # 全部TCP/UDP套接字
  - bash ~/.sebastian/skills/ss-specification/scripts/ss_socket.sh tcp 22     # 查看22端口的TCP连接
  - bash ~/.sebastian/skills/ss-specification/scripts/ss_socket.sh summary    # 套接字统计摘要

## 支持范围
- TCP / UDP / RAW / UNIX域套接字查询
- 监听端口（LISTEN）与已建立连接（ESTABLISHED）状态
- 进程 PID 与程序名关联显示（-p）
- 套接字内存、拥塞窗口、定时器等细粒度信息（-e -i）
- 常用选项说明、输出字段含义与实例见 references/ss-fields.md
