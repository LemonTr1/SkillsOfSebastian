: "
name: whois_query
description: 查询域名或IP地址的注册信息（RDAP优先，whois命令兜底）
parameters: $1=域名或IP地址(必填), $2=输出格式(json|text, default: json)
"
# /dev/null is read-only inside the sandbox; use a writable tmp file instead
DEVNULL="/tmp/.sebastian_devnull_$$"
: > "$DEVNULL" 2>&1 || DEVNULL="/tmp/.sebastian_devnull"
trap 'rm -f "$DEVNULL"' EXIT

TARGET="${1:?用法: whois_query.sh <域名或IP> [json|text]}"
FORMAT="${2:-json}"

# 判断是 IP 还是域名
if echo "$TARGET" | grep -qE '^[0-9]+(\.[0-9]+){3}$|^[0-9a-fA-F:]+$'; then
    IS_IP=1
else
    IS_IP=0
fi

# RDAP 查询（多端点轮换，提高可用性）
rdap_url=""
if [ "$IS_IP" = "1" ]; then
    rdap_url="https://rdap.org/ip/$TARGET"
else
    # 提取TLD
    TLD=$(echo "$TARGET" | grep -oP '\.[a-z0-9-]+$' | sed 's/^\.//')
    case "$TLD" in
        com|net) rdap_url="https://rdap.verisign.com/$TLD/v1/domain/$TARGET" ;;
        org)     rdap_url="https://rdap.org/domain/$TARGET" ;;
        info)    rdap_url="https://rdap.afilias.net/rdap/domain/$TARGET" ;;
        io)      rdap_url="https://rdap.identitydigital.services/rdap/domain/$TARGET" ;;
        *)       rdap_url="https://rdap.org/domain/$TARGET" ;;
    esac
fi

RESP=$(curl -s --max-time 15 -H "Accept: application/json" "$rdap_url" 2>"$DEVNULL")

# 如果默认端点失败，尝试 rdap.org 兜底
if [ -z "$RESP" ] && [ "$rdap_url" != "https://rdap.org/domain/$TARGET" ]; then
    RESP=$(curl -s --max-time 15 -H "Accept: application/json" "https://rdap.org/domain/$TARGET" 2>"$DEVNULL")
fi

if [ "$FORMAT" = "json" ]; then
    # 尝试用 python 解析 RDAP JSON
    PARSED=$(echo "$RESP" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
except Exception as e:
    print('__NOT_JSON__')
    sys.exit(0)
out={'query': '$TARGET', 'source': 'rdap'}
# 注册商/机构
for e in d.get('entities',[]):
    roles=e.get('roles',[])
    if any(r in ('registrar','administrative','technical') for r in roles):
        vc=e.get('vcardArray',['',''])
        if len(vc)>1:
            for item in vc[1]:
                if item[0]=='fn':
                    out['registrar']=item[3]; break
        if 'registrar' in out: break
# 事件（创建/过期/更新）
for ev in d.get('events',[]):
    a=ev.get('eventAction'); dt=ev.get('eventDate')
    if a=='registration': out['created']=dt
    elif a=='expiration': out['expires']=dt
    elif a=='last changed': out['updated']=dt
# 名称服务器
ns=[n.get('ldhName') for n in d.get('nameservers',[])]
if ns: out['nameservers']=ns
# 状态 / 句柄 / IP信息
if d.get('status'): out['status']=d.get('status')
if d.get('handle'): out['handle']=d.get('handle')
if d.get('ipVersion'): out['ip_version']=d.get('ipVersion')
if d.get('name'): out['network_name']=d.get('name')
if d.get('startAddress'): out['start_ip']=d.get('startAddress')
if d.get('endAddress'): out['end_ip']=d.get('endAddress')
if d.get('cidr0_cidrs'):
    out['cidr']=[c.get('v4prefix') or c.get('v6prefix','')+'/'+str(c.get('length','')) for c in d.get('cidr0_cidrs',[])]
# 国家
for e in d.get('entities',[]):
    for a in e.get('vcardArray',['',''])[1] if len(e.get('vcardArray',['','']))>1 else []:
        if a[0]=='adr' and a[1].get('country-name'):
            out['country']=a[1]['country-name']; break
print(json.dumps(out,ensure_ascii=False,indent=2))
" 2>"$DEVNULL")
    if [ "$PARSED" = "__NOT_JSON__" ]; then
        # RDAP 无结果，回退到 whois 命令
        if command -v whois > "$DEVNULL"; then
            whois "$TARGET" 2>"$DEVNULL" | python3 -c "
import sys,json
out={'query': '$TARGET', 'source': 'whois'}
for line in sys.stdin:
    line=line.rstrip()
    if not line.strip() or line.startswith('%'):
        continue
    if ':' in line:
        k,v=line.split(':',1)
        k=k.strip(); v=v.strip()
        if not v: continue
        k2=k.lower().replace(' ','_')
        if 'registrar' in k2 and 'registrar' not in out: out['registrar']=v
        elif 'creation' in k2: out['created']=v
        elif 'expiry' in k2 or 'expiration' in k2: out['expires']=v
        elif 'name_server' in k2: out.setdefault('nameservers',[]).append(v)
        elif 'status' in k2 and 'status' not in out: out['status']=v
        elif 'registrant_organization' in k2: out['org']=v
        elif 'dnssec' in k2: out['dnssec']=v
print(json.dumps(out,ensure_ascii=False,indent=2))
" 2>"$DEVNULL"
        else
            echo "{\"query\":\"$TARGET\",\"error\":\"RDAP无结果且whois命令不可用\"}"
        fi
    else
        echo "$PARSED"
    fi
else
    # text 格式
    if [ -n "$RESP" ] && echo "$RESP" | head -c 1 | grep -q '{'; then
        echo "$RESP" | python3 -m json.tool 2>"$DEVNULL" || echo "$RESP"
    elif command -v whois > "$DEVNULL"; then
        whois "$TARGET" 2>"$DEVNULL" | head -80
    else
        echo "无可用查询方式"
    fi
fi
