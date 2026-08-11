: "
name: subdomain_enum
description: 子域名枚举，基于crt.sh证书透明度日志，可选DNS存活验证
parameters: $1=目标域名(必填), $2=最大条数(default: 200), $3=DNS验证(yes|no, default: no)
"
# /dev/null is read-only inside the sandbox; use a writable tmp file instead
DEVNULL="/tmp/.sebastian_devnull_$$"
: > "$DEVNULL" 2>&1 || DEVNULL="/tmp/.sebastian_devnull"
trap 'rm -f "$DEVNULL"' EXIT

DOMAIN="${1:?用法: subdomain_enum.sh <域名> [最大条数] [DNS验证yes/no]}"
MAX="${2:-200}"
DNS_CHECK="${3:-no}"

# 检查 curl
if ! command -v curl > "$DEVNULL"; then
    echo "{\"error\":\"curl 不可用\"}"
    exit 1
fi

echo "🔍 正在查询 crt.sh 证书透明度日志..." >&2

# 查询 crt.sh（JSON格式）
RESP=$(curl -s --max-time 30 "https://crt.sh/?q=%25.$DOMAIN&output=json" 2>"$DEVNULL")

if [ -z "$RESP" ] || [ "$RESP" = "[]" ]; then
    echo "{\"domain\":\"$DOMAIN\",\"subdomains\":[],\"total\":0,\"error\":\"crt.sh无结果或查询失败\"}"
    exit 0
fi

# 解析子域名（去重）
SUBDOMAINS=$(echo "$RESP" | python3 -c "
import json,sys
try:
    data=json.load(sys.stdin)
except Exception:
    print('__PARSE_ERROR__')
    sys.exit(0)
subs=set()
for entry in data:
    name=entry.get('name_value','')
    for n in name.split('\n'):
        n=n.strip().lower().lstrip('*.')
        if n.endswith('.$DOMAIN') and not n.endswith('.'):
            subs.add(n)
for s in sorted(subs):
    print(s)
" 2>"$DEVNULL")

if [ "$SUBDOMAINS" = "__PARSE_ERROR__" ]; then
    echo "{\"domain\":\"$DOMAIN\",\"error\":\"crt.sh响应解析失败\"}"
    exit 1
fi

TOTAL=$(echo "$SUBDOMAINS" | grep -c . 2>"$DEVNULL" || echo 0)
SUBDOMAINS=$(echo "$SUBDOMAINS" | head -n "$MAX")

echo "📋 共发现 $TOTAL 个子域名（显示前 $MAX 个）" >&2

# 输出结果
echo "{"
echo "  \"domain\": \"$DOMAIN\","
echo "  \"total_found\": $TOTAL,"
echo "  \"subdomains\": ["

FIRST=1
while IFS= read -r sub; do
    [ -z "$sub" ] && continue
    if [ $FIRST -eq 1 ]; then FIRST=0; else echo ","; fi
    if [ "$DNS_CHECK" = "yes" ]; then
        # DNS 存活验证
        if command -v dig > "$DEVNULL"; then
            IP=$(dig +short "$sub" A 2>"$DEVNULL" | head -1)
        elif command -v host > "$DEVNULL"; then
            IP=$(host "$sub" 2>"$DEVNULL" | grep -oP 'address \K.*' | head -1)
        else
            IP=""
        fi
        if [ -n "$IP" ]; then
            printf '    {"name":"%s","ip":"%s","alive":true}' "$sub" "$IP"
        else
            printf '    {"name":"%s","ip":null,"alive":false}' "$sub"
        fi
    else
        printf '    {"name":"%s"}' "$sub"
    fi
done <<< "$SUBDOMAINS"

echo ""
echo "  ]"
echo "}"
