#!/usr/bin/env bash
# =============================================================================
# ss_socket.sh — Linux ss 命令（网络套接字分析）封装脚本
# 位置: ~/.sebastian/skills/ss-specification/scripts/ss_socket.sh
# -----------------------------------------------------------------------------
# 用法:
#   bash ss_socket.sh [query_type] [port_filter]
# 参数:
#   query_type : all|tcp|udp|listen|established|summary|pid
#   port_filter: 可选，端口号或逗号分隔端口列表，如 22 或 "22,80,443"
# 示例:
#   bash ss_socket.sh listen          # 查看所有监听端口
#   bash ss_socket.sh tcp 22          # 查看22端口的TCP连接
#   bash ss_socket.sh summary         # 查看套接字统计摘要
#   bash ss_socket.sh pid             # 查看TCP/UDP套接字及关联进程
# =============================================================================

set -u

QUERY_TYPE="${1:-all}"
PORT_FILTER="${2:-}"

usage() {
  echo "用法: bash $0 [query_type] [port_filter]"
  echo "query_type: all|tcp|udp|listen|established|summary|pid"
  echo "port_filter: 可选，端口号或逗号分隔列表"
  echo "示例: bash $0 listen, bash $0 tcp 22, bash $0 summary"
}

case "$QUERY_TYPE" in
  all)
    SS_ARGS=(-tunap)
    DESC="所有 TCP/UDP 套接字（含进程）"
    ;;
  tcp)
    SS_ARGS=(-tunap)
    DESC="TCP 套接字（含进程）"
    ;;
  udp)
    SS_ARGS=(-uap)
    DESC="UDP 套接字（含进程）"
    ;;
  listen)
    SS_ARGS=(-lntup)
    DESC="监听中的 TCP/UDP 端口"
    ;;
  established)
    SS_ARGS=(-tn state established)
    DESC="已建立的 TCP 连接"
    ;;
  summary)
    SS_ARGS=(-s)
    DESC="套接字统计摘要"
    ;;
  pid)
    SS_ARGS=(-tunap)
    DESC="TCP/UDP 套接字及关联进程(PID)"
    ;;
  help|-h|--help)
    usage
    exit 0
    ;;
  *)
    echo "未知查询类型: $QUERY_TYPE" >&2
    usage
    exit 1
    ;;
esac

echo "==== ss $QUERY_TYPE : $DESC ===="
if [ -n "$PORT_FILTER" ]; then
  # 保留表头行 + 包含指定端口的行（端口前为冒号分隔符）
  ss "${SS_ARGS[@]}" 2>&1 | grep -E "^State|^Netid|:${PORT_FILTER}[[:space:]]"
else
  ss "${SS_ARGS[@]}" 2>&1
fi
