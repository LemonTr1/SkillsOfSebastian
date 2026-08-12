# theHarvester 工具详细说明

## 工具简介
theHarvester 是一款经典的 OSINT（开源情报）信息收集工具，在渗透测试早期阶段用于收集目标公司/域名的公开信息：
- **子域名**（Subdomains）
- **邮箱地址**（Emails）
- **主机名**（Hosts）
- **IP 地址**（IPs）

## 安装方法（自包含，推荐）
本 skill 已内置 theHarvester 完整源码（`vendor/theHarvester/`），无需从 GitHub 重新下载，也无需系统级安装：

```bash
# ① 环境引导（自动创建 venv + 安装全部依赖 + 验证入口，幂等可重复执行）
bash ~/.sebastian/skills/theharvester-specification/scripts/setup.sh

# ② 直接使用（脚本自动调用内置 venv，无需手动激活）
bash ~/.sebastian/skills/theharvester-specification/scripts/theharvester_enum.sh example.com
```

### 全新主机迁移安装
```bash
# 在源主机生成便携包（排除 venv，约 1.1M）
bash ~/.sebastian/skills/theharvester-specification/scripts/pack.sh

# 拷贝到目标主机并解压到 skills 目录
scp theharvester-specification_*.tar.gz user@target:~
ssh user@target "tar -xzf theharvester-specification_*.tar.gz -C ~/.sebastian/skills/"

# 在目标主机执行引导安装（前置要求：Python >= 3.12 与 pip）
bash ~/.sebastian/skills/theharvester-specification/scripts/setup.sh
```

> 备选（不推荐，仅当需要最新源码时）：从 GitHub 克隆后 `pip3 install -e .`
> ```bash
> git clone https://github.com/laramies/theHarvester.git
> cd theHarvester && pip3 install -e .
> ```

## 基本用法
```bash
# 基础枚举（all 数据源，默认500条）
theHarvester -d example.com

# 指定数据源
theHarvester -d example.com -b crtsh

# 限制结果数量 + DNS解析 + 保存结果
theHarvester -d example.com -l 200 -n -f output
```

## 常用参数
| 参数 | 说明 |
|------|------|
| `-d, --domain` | 目标域名（必填） |
| `-b, --source` | 数据源（all 或单个源，如 crtsh/hackertarget/otx/rapiddns/virustotal/shodan） |
| `-l, --limit` | 结果数量上限，默认 500 |
| `-n, --dns-lookup` | 对发现的子域名做 DNS 解析 |
| `-r, --dns-resolve` | 使用 resolver 列表做 DNS 解析 |
| `-c, --dns-brute` | DNS 暴力破解子域名 |
| `-f, --filename` | 保存结果到 XML/JSON 文件 |
| `-t, --take-over` | 检查子域名接管风险 |
| `-s, --shodan` | 使用 Shodan 查询（需 API Key） |
| `-q, --quiet` | 静默模式，隐藏缺失 API Key 警告 |

## 常用数据源
- **无需 API Key**：crtsh、hackertarget、otx、rapiddns、threatcrowd、commoncrawl、waybackarchive 等
- **需要 API Key**：shodan、censys、virustotal、fofa、hunter、securitytrails、intelx 等
- 无 Key 时 theHarvester 会自动跳过该源，不影响其他源工作

## API Key 配置
theHarvester 从 **`~/.theHarvester/api-keys.yaml`** 读取 API Key（不存在时首次运行会自动从源码 data 目录复制默认模板）。

```bash
# 配置文件位置
~/.theHarvester/api-keys.yaml
```

编辑该文件，在对应的服务条目下填入 Key（注意顶层 `apikeys:` 键和缩进必须保留）：
```yaml
apikeys:
  shodan:
    key: YOUR_SHODAN_KEY
  virustotal:
    key: YOUR_VT_KEY
  censys:
    id: YOUR_CENSYS_ID
    secret: YOUR_CENSYS_SECRET
  securityTrails:
    key: YOUR_SECURITYTRAILS_KEY
  hunter:
    key: YOUR_HUNTER_KEY
```
- 配置自动生效，无需重启
- 留空的条目会自动跳过，不影响无需 Key 的源（crtsh/hackertarget/otx/rapiddns 等）

## 输出说明
theHarvester 默认在终端输出发现结果，使用 `-f` 参数时会额外生成（文件名为 `-f` 指定的基础名 + 扩展名，**无 `_harvester` 后缀**）：
- `<基础名>.xml` — XML 格式结果
- `<基础名>.json` — JSON 格式结果（脚本优先解析此文件）

> 例如 `theHarvester -d example.com -f output` 会生成 `output.xml` 与 `output.json`。
> 注意：旧版 theHarvester 曾使用 `xxx_harvester.xml/json` 命名，当前 4.x 版本已不再追加该后缀。

## 注意事项
- 本工具仅用于**合法授权的安全测试**和 OSINT 研究
- 部分数据源对查询频率有限制，请合理控制 `-l` 参数
- 沙箱内 `/dev/null` 为只读，脚本已用临时文件替代
