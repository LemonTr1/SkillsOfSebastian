: "
name: ssl_check
description: SSL/TLS证书体检，检查有效期、颁发者、指纹、SAN、到期预警
parameters: $1=目标主机(必填), $2=端口(default: 443), $3=超时秒数(default: 10)
"
# /dev/null is read-only inside the sandbox; use a writable tmp file instead
DEVNULL="/tmp/.sebastian_devnull_$$"
: > "$DEVNULL" 2>&1 || DEVNULL="/tmp/.sebastian_devnull"
trap 'rm -f "$DEVNULL"' EXIT

HOST="${1:?用法: ssl_check.sh <主机> [端口] [超时]}"
PORT="${2:-443}"
TIMEOUT="${3:-10}"

# 检查 openssl 是否可用
if ! command -v openssl > "$DEVNULL"; then
    echo "{\"error\":\"openssl 不可用\",\"host\":\"$HOST\"}"
    exit 1
fi

CERT_FILE="/tmp/.ssl_cert_$$"
trap 'rm -f "$CERT_FILE" "$DEVNULL"' EXIT

# 获取证书（支持SNI）
echo | timeout "$TIMEOUT" openssl s_client -connect "${HOST}:${PORT}" \
    -servername "$HOST" -showcerts 2>"$DEVNULL" | openssl x509 -outform PEM > "$CERT_FILE" 2>"$DEVNULL"

if [ ! -s "$CERT_FILE" ]; then
    echo "{\"error\":\"无法获取证书\",\"host\":\"$HOST\",\"port\":$PORT}"
    exit 1
fi

# 解析证书信息
openssl x509 -in "$CERT_FILE" -noout -subject -issuer -dates -serial -fingerprint -sha256 2>"$DEVNULL" > /tmp/.ssl_meta_$$
META=$(cat /tmp/.ssl_meta_$$)
rm -f /tmp/.ssl_meta_$$

# 提取字段
SUBJECT=$(echo "$META" | sed -n 's/^subject=//p')
ISSUER=$(echo "$META" | sed -n 's/^issuer=//p')
NOT_BEFORE=$(echo "$META" | sed -n 's/^notBefore=//p')
NOT_AFTER=$(echo "$META" | sed -n 's/^notAfter=//p')
SERIAL=$(echo "$META" | sed -n 's/^serial=//p')
SHA256=$(echo "$META" | grep -i 'fingerprint' | sed 's/^.*fingerprint[=:]\s*//I')

# SAN 列表
SAN=$(openssl x509 -in "$CERT_FILE" -noout -ext subjectAltName 2>"$DEVNULL" | grep -oP 'DNS:\K[^,]+' | tr '\n' ',' | sed 's/,$//')
ALT_IPS=$(openssl x509 -in "$CERT_FILE" -noout -ext subjectAltName 2>"$DEVNULL" | grep -oP 'IP Address:\K[^,]+' | tr '\n' ',' | sed 's/,$//')

# 计算剩余天数
DAYS_LEFT=0
if [ -n "$NOT_AFTER" ]; then
    EXPIRY_EPOCH=$(date -d "$NOT_AFTER" +%s 2>"$DEVNULL")
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))
fi

# 到期状态
STATUS="valid"
if [ "$DAYS_LEFT" -lt 0 ]; then
    STATUS="expired"
elif [ "$DAYS_LEFT" -lt 30 ]; then
    STATUS="expiring_soon"
fi

# 尝试获取TLS版本和加密套件（兼容多行和单行输出格式）
S_CLIENT_OUT=$(echo | timeout "$TIMEOUT" openssl s_client -connect "${HOST}:${PORT}" -servername "$HOST" 2>"$DEVNULL")
TLS_VER=$(echo "$S_CLIENT_OUT" | grep -i 'Protocol' | head -1 | awk '{print $NF}')
CIPHER=$(echo "$S_CLIENT_OUT" | grep -i 'Cipher is' | head -1 | sed 's/.*Cipher is //')
[ -z "$TLS_VER" ] && TLS_VER=$(echo "$S_CLIENT_OUT" | grep -oP 'TLSv\d(\.\d)?' | head -1)
[ -z "$CIPHER" ] && CIPHER=$(echo "$S_CLIENT_OUT" | grep -oP 'Cipher is \K.*' | head -1)

# 输出 JSON
python3 -c "
import json,os
out={
    'host': '$HOST',
    'port': $PORT,
    'subject': '${SUBJECT:-N/A}',
    'issuer': '${ISSUER:-N/A}',
    'serial': '${SERIAL:-N/A}',
    'not_before': '${NOT_BEFORE:-N/A}',
    'not_after': '${NOT_AFTER:-N/A}',
    'days_left': $DAYS_LEFT,
    'status': '$STATUS',
    'sha256_fingerprint': '${SHA256:-N/A}',
    'san_dns': '${SAN:-}' .split(',') if '${SAN:-}' else [],
    'san_ips': '${ALT_IPS:-}' .split(',') if '${ALT_IPS:-}' else [],
    'tls_version': '${TLS_VER:-unknown}',
    'cipher': '${CIPHER:-unknown}'
}
print(json.dumps(out,ensure_ascii=False,indent=2))
" 2>"$DEVNULL"

# 附加安全提示
echo "--- 安全提示 ---" >&2
if [ "$DAYS_LEFT" -lt 0 ]; then
    echo "⚠️ 证书已过期 ${DAYS_LEFT#-} 天！" >&2
elif [ "$DAYS_LEFT" -lt 30 ]; then
    echo "⚠️ 证书将在 $DAYS_LEFT 天后过期，请及时续期！" >&2
else
    echo "✅ 证书有效，剩余 $DAYS_LEFT 天" >&2
fi
