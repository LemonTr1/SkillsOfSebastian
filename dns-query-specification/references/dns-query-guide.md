# DNS 查询详细指南

## 1. 背景知识
DNS（Domain Name System）将域名解析为 IP 地址。常见记录类型：

| 类型 | 全称 | 用途 |
|------|------|------|
| A | Address | IPv4 地址映射 |
| AAAA | Address | IPv6 地址映射 |
| CNAME | Canonical Name | 域名别名（如 www → 主域名） |
| MX | Mail Exchange | 邮件服务器（带优先级） |
| NS | Name Server | 权威 DNS 服务器 |
| TXT | Text | 文本记录（SPF、DKIM、验证码等） |
| SOA | Start of Authority | 区域权威信息 |
| PTR | Pointer | 反向解析（IP → 域名） |

## 2. 常用命令示例

### dig（首选，信息最全）
```bash
# 正向解析 A 记录
dig example.com A

# 指定 DNS 服务器（绕过本地缓存）
dig @8.8.8.8 example.com A

# 查询 MX 记录
dig example.com MX

# 反向解析（IP 查域名）
dig -x 8.8.8.8

# 只输出答案部分（简洁）
dig +noall +answer example.com A
```

### nslookup（兼容性好）
```bash
nslookup example.com
nslookup -type=MX example.com
nslookup example.com 8.8.8.8   # 指定服务器
```

### host（最简洁）
```bash
host example.com
host -t MX example.com
host 8.8.8.8                    # 反向解析
```

## 3. 常见错误解析
| 输出 | 含义 | 排查方向 |
|------|------|---------|
| `NXDOMAIN` | 域名不存在 | 域名拼写/是否过期 |
| `SERVFAIL` | 服务器故障 | 上游DNS问题，换DNS重试 |
| `NOERROR` + 空答案 | 记录不存在 | 类型是否查错（如A vs MX） |
| `connection timed out` | 不可达 | 网络/DNS端口(53)被封锁 |
| `REFUSED` | 拒绝服务 | DNS服务器限制递归查询 |

## 4. 诊断技巧
1. **对比公共DNS**：`dig @8.8.8.8` 与 `dig @本地网关` 对比，判断是本地缓存问题还是上游问题
2. **TTL 检查**：`dig +noall +answer -t A example.com` 中的 TTL 决定缓存时长
3. **批量域名**：脚本的 `--batch` 模式支持从文件读入多个域名
4. **查路由器DNS**：`dig @192.168.1.1 example.com` 验证路由器内置DNS是否正常
