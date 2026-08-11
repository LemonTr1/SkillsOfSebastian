---
name: hash-toolkit
description: 哈希计算/哈希类型识别/完整性校验工具
---
# 目录
## 哈希工具集
- 位置：'~/.sebastian/skills/hash-toolkit/scripts/hash_tool.sh'

## 可执行脚本
### hash_tool.sh
- description: 计算文件或字符串的哈希值、识别哈希类型、校验文件完整性
- parameters:
  - $1=操作类型(calc|identify|verify)
  - calc: $2=文件路径或字符串, $3=哈希算法(md5|sha1|sha256|sha512, default: sha256)
  - identify: $2=哈希值(必填)，自动识别可能的哈希类型
  - verify: $2=文件路径, $3=期望哈希值, $4=算法(default: sha256)
- usage: bash ~/.sebastian/skills/hash-toolkit/scripts/hash_tool.sh calc /path/to/file sha256

### 支持算法
- MD5, SHA1, SHA224, SHA256, SHA384, SHA512, SHA3-256, SHA3-512
- 通过内置工具（md5sum/sha1sum/sha256sum等）计算，免root

### 哈希识别逻辑
- 根据哈希长度和字符集自动判断可能的算法
- 支持常见哈希长度：32(MD5), 40(SHA1), 56(SHA224), 64(SHA256), 96(SHA384), 128(SHA512)
