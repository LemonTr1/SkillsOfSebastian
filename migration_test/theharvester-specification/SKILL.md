---
name: theharvester-specification
description: theHarvester OSINT信息收集工具，基于50+开源情报源枚举子域名、邮箱、主机和IP，内置自包含源码与环境引导脚本
---
# 目录
## theHarvester OSINT信息收集工具
- 位置：'~/.sebastian/skills/theharvester-specification/references/theharvester-notification.md'，使用工具读取

## 可执行脚本
### theharvester_enum.sh
- description: 使用theHarvester对目标域名/公司进行OSINT信息收集，枚举子域名、邮箱、主机名和IP
- parameters: $1=目标域名(必填), $2=数据源(all|baidu|crtsh|...), $3=结果数量上限(default: 200), $4=是否DNS解析(yes|no, default: no)
- usage: bash ~/.sebastian/skills/theharvester-specification/scripts/theharvester_enum.sh example.com

### setup.sh（自包含环境引导脚本）
- description: 在任意主机上为 skill 内置的 theHarvester 源码创建虚拟环境并安装依赖，无需系统级安装
- usage: bash ~/.sebastian/skills/theharvester-specification/scripts/setup.sh
- 前置要求: Python >= 3.12 与 pip
- 功能: 自动创建 vendor/theHarvester/.venv、安装全部依赖、验证入口可用
- 幂等性: 环境已存在时直接复用，秒级完成

## 目录结构（自包含设计）
```
theharvester-specification/
├── SKILL.md                     # 技能说明
├── scripts/
│   ├── theharvester_enum.sh     # 枚举脚本（优先使用内置vendor环境）
│   └── setup.sh                 # 环境引导脚本（自动建venv/装依赖）
├── vendor/
│   └── theHarvester/            # ★ theHarvester 完整源码（3.9M，可编辑安装）
│       ├── theHarvester/        #   核心Python代码
│       ├── pyproject.toml       #   依赖清单
│       └── .venv/               #   虚拟环境（setup.sh自动创建，可整体迁移）
└── references/
    └── theharvester-notification.md
```
- 整个 skill 目录可整体拷贝到其他主机直接使用
- 新主机首次使用时，theharvester_enum.sh 会自动检测内置源码并调用 setup.sh 引导安装

## 数据源说明
- theHarvester 支持 50+ 开源情报源（crtsh、hackertarget、otx、rapiddns、virustotal、shodan 等）
- 部分数据源需要 API Key（如 shodan、censys、virustotal），无 Key 时自动跳过
- 默认使用 all 数据源，无需 Key 即可使用的源：crtsh、hackertarget、otx、rapiddns、threatcrowd 等

## 输出
- 发现的子域名列表（去重）
- 发现的邮箱地址列表
- 解析到的主机名与IP映射（可选）
- 统计信息：各类型结果总数

## 依赖安装（已自包含，无需手动安装）
- skill 内置完整源码：vendor/theHarvester（Python>=3.12）
- 一键引导：bash scripts/setup.sh（自动创建 venv + 安装全部依赖 + 验证）
- 官方仓库：https://github.com/laramies/theHarvester
