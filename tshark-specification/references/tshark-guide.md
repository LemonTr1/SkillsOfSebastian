# TShark 深度抓包分析指南

TShark 是 Wireshark 的命令行版本（`tshark`）。与 tcpdump 相比，它运行完整的协议解析器（dissectors），可以：
- 深度解析 2000+ 协议（HTTP/DNS/TLS/SMB/QUIC...）
- 统计协议层级（Protocol Hierarchy）
- 统计会话（Conversations）与端点（Endpoints）
- 重组 TCP/UDP 流（Follow Stream）
- 按字段精确提取数据（`-T fields`）
- 导出传输对象（HTTP 文件、SMB 文件等）
- 生成专家诊断信息（Expert Info）

---

## 1. 基本用法

```bash
# 实时抓包（需要 root/CAP_NET_RAW），写 pcap 文件
sudo tshark -i any -w /tmp/cap.pcap

# 实时抓包并打印简要信息
sudo tshark -i eth0 -c 100

# 离线分析 pcap
tshark -r /tmp/cap.pcap

# 只显示摘要行
tshark -r /tmp/cap.pcap -T fields -e frame.number -e ip.src -e ip.dst -e _ws.col.Info
```

## 2. 过滤器

### BPF 抓包过滤器（`-f`，抓包时用）
```bash
sudo tshark -i any -f "host 192.168.1.1" -w /tmp/router.pcap
sudo tshark -i any -f "port 80 or port 443" -w /tmp/web.pcap
sudo tshark -i any -f "tcp portrange 8000-9000" -w /tmp/app.pcap
```

### 显示过滤器（`-Y`，分析时用，Wireshark 语法）
```bash
tshark -r cap.pcap -Y "http"                          # 只看 HTTP
tshark -r cap.pcap -Y "dns.qry.name contains baidu"   # DNS 查询包含 baidu
tshark -r cap.pcap -Y "tcp.flags.syn == 1 and tcp.flags.ack == 0"  # 纯 SYN（探测）
tshark -r cap.pcap -Y "ip.src == 192.168.1.1"         # 路由器发出的包
tshark -r cap.pcap -Y "tcp.analysis.retransmission"   # TCP 重传
tshark -r cap.pcap -Y "tcp.analysis.zero_window"      # 零窗口（接收端拥塞）
```

常用显示过滤字段：
| 字段 | 含义 |
|------|------|
| `ip.src` / `ip.dst` | 源/目的 IP |
| `tcp.port` / `udp.port` | 端口 |
| `http.request.uri` | HTTP 请求路径 |
| `http.response.code` | HTTP 响应码 |
| `dns.qry.name` | DNS 查询域名 |
| `tls.handshake.type == 1` | TLS ClientHello |
| `frame.len` | 帧长度 |

## 3. 字段提取（数据挖掘）

```bash
# 提取 HTTP 请求方法、URI、来源 IP
tshark -r cap.pcap -Y "http.request" -T fields -e ip.src -e http.request.method -e http.request.uri -E header=y

# 提取 DNS 查询与响应
tshark -r cap.pcap -Y "dns.flags.response == 0" -T fields -e dns.qry.name -E header=y

# 提取所有 TCP 会话 5 元组
tshark -r cap.pcap -T fields -e ip.src -e tcp.srcport -e ip.dst -e tcp.dstport -E header=y

# 输出 JSON 便于程序处理
tshark -r cap.pcap -Y "http" -T json -e http.request.uri -e ip.src
```

## 4. 统计模块（`-z`，需配合 `-q`）

```bash
# 协议层级统计
tshark -r cap.pcap -q -z io,phs

# TCP 会话统计
tshark -r cap.pcap -q -z conv,tcp

# IP 端点统计
tshark -r cap.pcap -q -z endpoints,ip

# HTTP 统计
tshark -r cap.pcap -q -z http,tree

# IO 速率统计（每秒）
tshark -r cap.pcap -q -z io,stat,1

# 专家信息（诊断错误/警告）
tshark -r cap.pcap -q -z expert,error

# 按时间间隔统计帧数
tshark -r cap.pcap -q -z io,stat,10,"tcp.analysis.retransmission"
```

## 5. Follow Stream（流重组）

```bash
# 查看 TCP 流 0（ASCII 模式，等价于 Wireshark "Follow TCP Stream"）
tshark -r cap.pcap -q -z follow,tcp,ascii,0

# hex 模式
tshark -r cap.pcap -q -z follow,tcp,hex,0

# UDP 流
tshark -r cap.pcap -q -z follow,udp,ascii,0
```

## 6. 导出对象

```bash
# 导出所有 HTTP 传输对象（图片、JS、HTML 等）
tshark -r cap.pcap -q --export-objects http,/tmp/http_objects

# 导出 SMB 文件
tshark -r cap.pcap -q --export-objects smb,/tmp/smb_objects
```

## 7. TLS 解密

抓包时记录会话密钥，配合 keylog 文件解密 HTTPS：

```bash
# 环境变量方式（抓包前设置）
export SSLKEYLOGFILE=/tmp/tls_keys.log

# 离线解密分析
tshark -r cap.pcap -o tls.keylog_file:/tmp/tls_keys.log -Y "http" -T fields -e http.request.uri
```

## 8. 实战排查思路

| 场景 | 命令 |
|------|------|
| 检查是否有端口扫描 | `tshark -r cap.pcap -Y "tcp.flags.syn==1 and tcp.flags.ack==0" -q -z conv,tcp` |
| 排查网站慢 | `tshark -r cap.pcap -Y "http" -T fields -e http.time` |
| 看有没有重传丢包 | `tshark -r cap.pcap -Y "tcp.analysis.retransmission" -q -z io,stat,1` |
| 找 DNS 污染/异常 | `tshark -r cap.pcap -Y "dns.flags.response==0" -T fields -e dns.qry.name` |
| 看路由器管理端口 | `tshark -r cap.pcap -q -z endpoints,tcp` |
| 抓 HTTPS 明文（有keylog） | `tshark -r cap.pcap -o tls.keylog_file:/tmp/keys.log -Y http -T fields -e http.host -e http.request.uri` |

## 9. 常用 TShark 参数速查

| 参数 | 含义 |
|------|------|
| `-i <iface>` | 抓包接口（`any` 表示所有） |
| `-r <file>` | 读取 pcap |
| `-w <file>` | 写入 pcap |
| `-c <n>` | 抓/读 n 个包后停止 |
| `-f <bpf>` | 抓包 BPF 过滤器 |
| `-Y <filter>` | 显示过滤器 |
| `-T fields -e <field>` | 字段提取 |
| `-E header=y` | 输出带表头 |
| `-q -z <stat>` | 静默 + 统计模块 |
| `-o <pref>:<val>` | 覆盖偏好（如 TLS keylog） |
| `-V` | 详细协议树（类似 Wireshark 完整视图） |
| `-S` | 实时打印解码头 |
| `-s <n>` | 抓包长度（snaplen） |
| `-n` | 禁用名称解析（更快更准） |
