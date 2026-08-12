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
- 幂等性: 环境已存在时直接复用，仅需数秒（仍需短时 pip 检查）

## 目录结构（自包含设计）
```
theharvester-specification/
├── SKILL.md                     # 技能说明
├── scripts/
│   ├── theharvester_enum.sh     # 枚举脚本（优先使用内置vendor环境）
│   ├── setup.sh                 # 环境引导脚本（自动建venv/装依赖，幂等）
│   └── pack.sh                  # 打包迁移脚本（生成便携 tar.gz，排除venv）
├── vendor/
│   └── theHarvester/            # ★ theHarvester 完整源码（3.9M，可编辑安装）
│       ├── theHarvester/        #   核心Python代码
│       ├── pyproject.toml       #   依赖清单
│       └── .venv/               #   虚拟环境（setup.sh自动创建，可整体迁移）
└── references/
    └── theharvester-notification.md
```

## 全新安装（新主机 / 首次使用）
Skill 已完全自包含，无需系统级安装，只需三步：

```bash
# ① 获取 skill（任选其一）
#    方式A：整目录拷贝（含 venv，约 264M）——仅当目标主机用户/路径布局与源主机完全相同时方可"拷完即用"；否则请改用方式B
scp -r user@host:~/.sebastian/skills/theharvester-specification ~/.sebastian/skills/
#    方式B：便携包迁移（约 1.1M，需执行 setup.sh 重建 venv）
bash ~/.sebastian/skills/theharvester-specification/scripts/pack.sh   # 在源主机生成包
tar -xzf theharvester-specification_*.tar.gz -C ~/.sebastian/skills/  # 在目标主机解压

# ② 一键引导（自动创建 venv + 安装全部依赖 + 验证入口）
bash ~/.sebastian/skills/theharvester-specification/scripts/setup.sh

# ③ 使用
bash ~/.sebastian/skills/theharvester-specification/scripts/theharvester_enum.sh example.com
```

- **前置要求**：Python >= 3.12 与 pip（setup.sh 会自动检测并提示）
- **幂等性**：setup.sh 检测到 venv 已存在时直接复用，仅需数秒（仍需短时 pip 检查）
- **自动回退**：theharvester_enum.sh 依次寻找「内置 venv → 系统 PATH → `$THEHARVESTER_BIN` 环境变量指定路径」，找不到时自动调用 setup.sh 引导
- **API Key**：theHarvester 从 `~/.theHarvester/api-keys.yaml` 读取 Key（首次运行自动生成默认模板，编辑填入即可），详见 references 文档

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
