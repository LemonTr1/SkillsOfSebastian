: "
name: header_audit
description: HTTP安全响应头审计，检查OWASP推荐的安全头并评分
parameters: $1=目标URL(必填), $2=跟随重定向(yes|no, default: yes)
"
# /dev/null is read-only inside the sandbox; use a writable tmp file instead
DEVNULL="/tmp/.sebastian_devnull_$$"
: > "$DEVNULL" 2>&1 || DEVNULL="/tmp/.sebastian_devnull"
trap 'rm -f "$DEVNULL"' EXIT

URL="${1:?用法: header_audit.sh <URL> [跟随重定向yes/no]}"
FOLLOW="${2:-yes}"

# 检查 curl
if ! command -v curl > "$DEVNULL"; then
    echo "{\"error\":\"curl 不可用\"}"
    exit 1
fi

# 获取响应头
if [ "$FOLLOW" = "yes" ]; then
    HEADERS=$(curl -s -I --max-time 15 -L "$URL" 2>"$DEVNULL")
else
    HEADERS=$(curl -s -I --max-time 15 "$URL" 2>"$DEVNULL")
fi

if [ -z "$HEADERS" ]; then
    echo "{\"error\":\"无法获取响应头\",\"url\":\"$URL\"}"
    exit 1
fi

# 提取状态码
STATUS=$(echo "$HEADERS" | grep -oE 'HTTP/[0-9.]+ [0-9]+' | tail -1 | grep -oE '[0-9]+$')

# 将响应头写入临时文件供 python 读取（避免引号冲突）
echo "$HEADERS" > /tmp/.hdr_raw_$$
trap 'rm -f /tmp/.hdr_raw_$$' EXIT

# 通过环境变量传递 URL 和临时文件名，python 直接读文件解析头
export AUDIT_URL="$URL"
export AUDIT_STATUS="$STATUS"
export AUDIT_HDR_FILE="/tmp/.hdr_raw_$$"
python3 - "$DEVNULL" << 'PYEOF' 2>"$DEVNULL"
import json, os, re, sys

DEVNULL = sys.argv[1]
hdrs = {}
try:
    with open(os.environ.get('AUDIT_HDR_FILE', '/tmp/.hdr_raw_')) as f:
        for line in f:
            line = line.strip()
            if ':' in line and not line.upper().startswith('HTTP/'):
                k, v = line.split(':', 1)
                hdrs[k.strip().lower()] = v.strip()
except Exception as e:
    print(json.dumps({'error': '响应头解析失败', 'detail': str(e)}, ensure_ascii=False))
    sys.exit(1)

results = []
score = 0
total = 7

def check(name, value, pass_cond, weight=1):
    global score
    present = bool(value)
    secure = present and pass_cond
    if secure:
        score += weight
        status = '✅'
    elif present:
        status = '⚠️'
    else:
        status = '❌'
    return {'header': name, 'status': status, 'present': present, 'secure': secure}

# 1. HSTS
h = hdrs.get('strict-transport-security', '')
m = re.search(r'max-age=(\d+)', h)
results.append(check('Strict-Transport-Security', h, bool(m) and int(m.group(1)) >= 15552000))

# 2. CSP
csp = hdrs.get('content-security-policy', '')
results.append(check('Content-Security-Policy', csp, csp and 'unsafe-inline' not in csp and 'unsafe-eval' not in csp))

# 3. X-Frame-Options
xfo = hdrs.get('x-frame-options', '')
results.append(check('X-Frame-Options', xfo, xfo.upper() in ('DENY', 'SAMEORIGIN')))

# 4. X-Content-Type-Options
xcto = hdrs.get('x-content-type-options', '')
results.append(check('X-Content-Type-Options', xcto, xcto.lower() == 'nosniff'))

# 5. Referrer-Policy
rp = hdrs.get('referrer-policy', '')
results.append(check('Referrer-Policy', rp, rp.lower().startswith(('strict-origin', 'no-referrer', 'same-origin'))))

# 6. Permissions-Policy
pp = hdrs.get('permissions-policy', '')
results.append(check('Permissions-Policy', pp, bool(pp)))

# 7. X-XSS-Protection
xxss = hdrs.get('x-xss-protection', '')
results.append(check('X-XSS-Protection', xxss, '1' in xxss))

server = hdrs.get('server', 'unknown')
powered = hdrs.get('x-powered-by', '')

final_score = int(score / total * 100)
grade = 'A' if final_score >= 90 else 'B' if final_score >= 75 else 'C' if final_score >= 60 else 'D' if final_score >= 40 else 'F'

out = {
    'url': os.environ.get('AUDIT_URL', ''),
    'status_code': int(os.environ.get('AUDIT_STATUS', '0')) or None,
    'server': server,
    'x_powered_by': powered,
    'security_score': final_score,
    'grade': grade,
    'checks': results,
    'missing_headers': [r['header'] for r in results if not r['present']],
    'recommendations': []
}
for r in results:
    if not r['present']:
        out['recommendations'].append(f"缺少 {r['header']}，建议配置以增强安全性")
    elif not r['secure']:
        out['recommendations'].append(f"{r['header']} 配置不够严格，建议按OWASP最佳实践加固")
print(json.dumps(out, ensure_ascii=False, indent=2))
PYEOF

rm -f /tmp/.hdr_raw_$$
