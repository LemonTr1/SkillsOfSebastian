---
name: ssl-cert-check
description: SSL/TLS证书体检工具，检查证书有效期、颁发者、加密套件、到期预警
---
# 目录
## SSL证书检查工具
- 位置：'~/.sebastian/skills/ssl-cert-check/scripts/ssl_check.sh'

## 可执行脚本
### ssl_check.sh
- description: 连接目标主机检查 SSL/TLS 证书信息（颁发者、有效期、剩余天数、加密套件、SNI支持等）
- parameters: $1=目标主机(域名或IP, 必填), $2=端口(default: 443), $3=超时秒数(default: 10)
- usage: bash ~/.sebastian/skills/ssl-cert-check/scripts/ssl_check.sh example.com 443

### 输出内容
- 证书颁发者（Issuer）
- 证书有效期（签发/过期时间）
- 剩余有效天数（含过期预警）
- 证书指纹（SHA256）
- 支持的 TLS 版本和加密套件
- SAN（Subject Alternative Names）域名列表
