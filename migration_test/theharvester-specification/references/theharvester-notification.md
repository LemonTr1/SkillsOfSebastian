# theHarvester 工具详细说明

## 工具简介
theHarvester 是一款经典的 OSINT（开源情报）信息收集工具，在渗透测试早期阶段用于收集目标公司/域名的公开信息：
- **子域名**（Subdomains）
- **邮箱地址**（Emails）
- **主机名**（Hosts）
- **IP 地址**（IPs）

## 安装方法
```bash
# 官方源码安装（推荐，Python >= 3.12）
cd /home/lem0ntr1/theHarvester_src
pip3 install -e .

# 或从 GitHub 克隆
git clone https://github.com/laramies/theHarvester.git
cd theHarvester && pip3 install -e .
```

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
编辑 `~/.sebastian/skills/theharvester-specification/api-keys.yaml`：
```yaml
shodan: YOUR_SHODAN_KEY
virustotal: YOUR_VT_KEY
censys-id: YOUR_CENSYS_ID
censys-secret: YOUR_CENSYS_SECRET
```

## 输出说明
theHarvester 默认在终端输出发现结果，使用 `-f` 参数时会额外生成：
- `xxx_harvester.xml` — XML 格式结果
- `xxx_harvester.json` — JSON 格式结果（脚本优先解析此文件）

## 注意事项
- 本工具仅用于**合法授权的安全测试**和 OSINT 研究
- 部分数据源对查询频率有限制，请合理控制 `-l` 参数
- 沙箱内 `/dev/null` 为只读，脚本已用临时文件替代
