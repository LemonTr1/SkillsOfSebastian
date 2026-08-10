---
name: http_req
description: 执行发送HTTP请求的快捷脚本
---
# http_req.sh脚本使用说明
## 执行时机：
- 向目标url发送简单的http请求，可用于判断网络连通性，执行优先级高于dispatcher("Web")

## 脚本执行：
- bash ~/.sebastian/skills/http_req/scripts/http_req.sh

## 脚本传参说明：
- $1=HTTP方法(default: GET), $2=URL, $3=请求数据(仅POST方法有效)
