: "
name: port_check
description: 测试目标主机的端口连通性
parameters: $1=主机地址(default: localhost), $2=端口号(default: 80), $3=超时时间(秒, default: 5)
"
HOST="${1:-localhost}"
PORT="${2:-80}"
TIMEOUT="${3:-5}"

# /dev/null is read-only inside the sandbox; use a writable tmp file instead
DEVNULL="/tmp/.sebastian_devnull_$$"
: > "$DEVNULL" 2>&1 || DEVNULL="/tmp/.sebastian_devnull"
trap 'rm -f "$DEVNULL"' EXIT

if timeout "$TIMEOUT" bash -c "echo >/dev/tcp/$HOST/$PORT" 2>"$DEVNULL"; then
    echo "{\"host\":\"$HOST\",\"port\":$PORT,\"open\":true}"
else
    echo "{\"host\":\"$HOST\",\"port\":$PORT,\"open\":false}"
fi
