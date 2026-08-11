---
name: subdomain-enum
description: 子域名枚举工具，基于证书透明度(CT)日志crt.sh和DNS枚举
---
# 目录
## 子域名枚举工具
- 位置：'~/.sebastian/skills/subdomain-enum/scripts/subdomain_enum.sh'

## 可执行脚本
### subdomain_enum.sh
- description: 通过证书透明度日志(crt.sh)和DNS枚举发现目标域名的子域名
- parameters: $1=目标域名(必填), $2=去重后最大条数(default: 200), $3=是否做DNS存活验证(yes|no, default: no)
- usage: bash ~/.sebastian/skills/subdomain-enum/scripts/subdomain_enum.sh example.com

### 数据来源
- crt.sh 证书透明度日志（CT Log，覆盖大部分HTTPS站点子域名）
- 可选：DNS 存活验证（通过 dig/host 检查解析记录）

### 输出
- 发现的子域名列表（去重）
- 每个子域名的DNS解析IP（可选）
- 统计信息：总数、去重数、存活数
