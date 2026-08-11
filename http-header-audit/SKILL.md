---
name: http-header-audit
description: HTTP安全响应头审计工具，基于OWASP安全头最佳实践
---
# 目录
## HTTP安全头审计工具
- 位置：'~/.sebastian/skills/http-header-audit/scripts/header_audit.sh'

## 可执行脚本
### header_audit.sh
- description: 检查目标网站的HTTP安全响应头是否符合OWASP最佳实践，输出每个头的状态和评分
- parameters: $1=目标URL(必填), $2=跟随重定向(yes|no, default: yes)
- usage: bash ~/.sebastian/skills/http-header-audit/scripts/header_audit.sh https://example.com

### 检查项（OWASP推荐）
| 安全头 | 推荐值 |
|--------|--------|
| Strict-Transport-Security | 启用且max-age>=15552000 |
| Content-Security-Policy | 存在且非'unsafe-inline'宽松 |
| X-Frame-Options | DENY 或 SAMEORIGIN |
| X-Content-Type-Options | nosniff |
| Referrer-Policy | strict-origin* |
| Permissions-Policy | 存在 |
| X-XSS-Protection | 存在（旧浏览器） |

### 输出
- 每个安全头的状态（✅/⚠️/❌）
- 综合安全评分（满分100）
- 缺失头列表和改进建议
