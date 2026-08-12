#!/usr/bin/env bash
# theharvester_enum.sh — OSINT information gathering with theHarvester
# 使用 skill 内置的 vendor/theHarvester 源码，无需在系统级安装
# Usage: bash theharvester_enum.sh <domain> [source] [limit] [dns_resolve]

# /dev/null is read-only inside the sandbox; use a writable tmp file instead
DEVNULL="/tmp/.sebastian_devnull_$$"
: > "$DEVNULL" 2>&1 || DEVNULL="/tmp/.sebastian_devnull"
trap 'rm -f "$DEVNULL"' EXIT

DOMAIN="${1:?用法: theharvester_enum.sh <域名> [数据源] [结果上限] [DNS解析yes/no]}"
SOURCE="${2:-all}"
LIMIT="${3:-200}"
DNS_RESOLVE="${4:-no}"

# 定位 skill 目录（规范化为绝对路径）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
VENDOR_DIR="$SKILL_DIR/vendor/theHarvester"
VENV_DIR="$VENDOR_DIR/.venv"
SETUP_SCRIPT="$SCRIPT_DIR/setup.sh"

# ---- 解析 theHarvester 可执行入口（优先级从高到低）----
# 1. skill 内置 vendor 的 venv
# 2. 系统 PATH 中的 theHarvester
# 3. 其他已知路径
HARVESTER_BIN=""
if [ -x "$VENV_DIR/bin/theHarvester" ]; then
    HARVESTER_BIN="$VENV_DIR/bin/theHarvester"
elif command -v theHarvester > "$DEVNULL" 2>&1; then
    HARVESTER_BIN="$(command -v theHarvester)"
elif [ -x /home/lem0ntr1/桌面/AHU/网络安全实验/答辩/Sebastian/venv/bin/theHarvester ]; then
    HARVESTER_BIN="/home/lem0ntr1/桌面/AHU/网络安全实验/答辩/Sebastian/venv/bin/theHarvester"
fi

# 若内置源码存在但 venv 未建立，自动引导安装
if [ -z "$HARVESTER_BIN" ] && [ -f "$VENDOR_DIR/pyproject.toml" ] && [ -f "$SETUP_SCRIPT" ]; then
    echo "⚠️ 检测到内置源码但未安装依赖，正在自动运行 setup.sh 引导安装..." >&2
    if bash "$SETUP_SCRIPT"; then
        HARVESTER_BIN="$VENV_DIR/bin/theHarvester"
    fi
fi

if [ -z "$HARVESTER_BIN" ]; then
    echo "{\"domain\":\"$DOMAIN\",\"error\":\"theHarvester 不可用且引导安装失败，请手动运行: bash $SETUP_SCRIPT\"}"
    exit 1
fi

echo "🔍 使用 theHarvester: $HARVESTER_BIN" >&2
echo "🔍 正在使用数据源 [$SOURCE] 收集 $DOMAIN 的OSINT信息..." >&2

# 构建命令参数（输出到 /tmp 下的临时文件，文件名 = 基础名，无 _harvester 后缀）
OUTPUT_BASE="/tmp/theharvester_out_$$"
ARGS=(-d "$DOMAIN" -b "$SOURCE" -l "$LIMIT" -f "$OUTPUT_BASE")
if [ "$DNS_RESOLVE" = "yes" ]; then
    ARGS+=(-n)
fi

# 执行 theHarvester
$HARVESTER_BIN "${ARGS[@]}" > "$DEVNULL" 2>&1
RC=$?

# 新版 theHarvester 输出文件为 <base>.json / <base>.xml（无 _harvester 后缀）
JSON_FILE="${OUTPUT_BASE}.json"
XML_FILE="${OUTPUT_BASE}.xml"

if [ $RC -ne 0 ] || [ ! -f "$JSON_FILE" ]; then
    echo "{\"domain\":\"$DOMAIN\",\"error\":\"theHarvester执行失败(exit=$RC)，请检查网络或API Key\"}"
    exit 1
fi

# 使用 python3 解析 JSON 输出并汇总
python3 - "$JSON_FILE" "$DOMAIN" <<'PYEOF'
import json, sys

json_file, domain = sys.argv[1], sys.argv[2]
try:
    with open(json_file) as f:
        data = json.load(f)
except Exception as e:
    print('{"domain":"%s","error":"JSON解析失败: %s"}' % (domain, e))
    sys.exit(0)

hosts = data.get('hosts', [])
emails = data.get('emails', [])
names = data.get('names', [])
ips = data.get('ips', [])

# 去重并排序
def dedup(lst):
    seen, out = set(), []
    for item in lst:
        if item and item not in seen:
            seen.add(item)
            out.append(item)
    return sorted(out)

hosts = dedup(hosts)
emails = dedup(emails)
names = dedup(names)
ips = dedup(ips)

print('{')
print('  "domain": "%s",' % domain)
print('  "hosts_total": %d,' % len(hosts))
print('  "emails_total": %d,' % len(emails))
print('  "names_total": %d,' % len(names))
print('  "ips_total": %d,' % len(ips))
print('  "hosts": %s,' % json.dumps(hosts, ensure_ascii=False))
print('  "emails": %s,' % json.dumps(emails, ensure_ascii=False))
print('  "names": %s,' % json.dumps(names, ensure_ascii=False))
print('  "ips": %s' % json.dumps(ips, ensure_ascii=False))
print('}')
PYEOF

# 清理临时文件
rm -f "$JSON_FILE" "$XML_FILE" 2> "$DEVNULL"
