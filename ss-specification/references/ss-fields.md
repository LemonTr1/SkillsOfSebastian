# ss 命令参考手册（网络分析与诊断）

`ss`（socket statistics）是 netstat 的现代替代品，直接读取内核 `/proc/net` 数据，
速度更快、信息更全，是 Linux 网络诊断的首选工具。

## 一、常用选项

| 选项 | 说明 |
|------|------|
| `-t` | 只显示 TCP 套接字 |
| `-u` | 只显示 UDP 套接字 |
| `-l` | 只显示监听（LISTEN）状态套接字 |
| `-a` | 显示所有状态（监听+已建立等） |
| `-n` | 以数字形式显示地址和端口（不做 DNS 反解） |
| `-p` | 显示套接字所属的进程名和 PID（需 root 或同权限用户） |
| `-e` | 显示扩展信息（内存、错误队列等） |
| `-i` | 显示内部 TCP 信息（拥塞窗口、RTT 等） |
| `-s` | 打印套接字统计摘要 |
| `-4` / `-6` | 只显示 IPv4 / IPv6 |
| `-x` | 只显示 UNIX 域套接字 |
| `-H` | 不显示表头行 |
| `-o` | 显示 TCP 定时器信息 |

## 二、输出字段说明（-tunap 模式）

```
State  Recv-Q  Send-Q  Local Address:Port  Peer Address:Port  Process
```

| 字段 | 含义 |
|------|------|
| `State` | 套接字状态：`LISTEN`（监听）、`ESTABLISHED`（已建立）、`SYN-SENT`（SYN已发出）、`TIME-WAIT`（等待关闭）、`CLOSE-WAIT`（对端关闭）、`FIN-WAIT-1/2`（关闭中）等 |
| `Recv-Q` | 接收队列中尚未被应用读取的字节数（TCP）；对 LISTEN 状态的 socket 表示当前已完成握手的连接数 |
| `Send-Q` | 发送队列中尚未被对端确认的字节数 |
| `Local Address:Port` | 本端地址与端口，`*` 表示任意地址，`:::22` 为 IPv6 任意地址监听 |
| `Peer Address:Port` | 对端地址与端口，监听状态下显示 `*:*` |
| `Process` | 所属进程，格式 `users:(("进程名",pid=1234,fd=5))` |

## 三、套接字状态速查

| 状态 | 含义 | 常见场景 |
|------|------|----------|
| LISTEN | 正在监听等待连接 | 服务正常开放端口 |
| ESTABLISHED | 连接已建立 | 正常活动连接 |
| TIME-WAIT | 主动关闭后的等待期 | 大量出现说明短连接频繁，属正常但需关注量级 |
| CLOSE-WAIT | 本端已收到对端关闭请求但应用未 close | 大量堆积 = 应用层 bug（未关闭 socket） |
| SYN-SENT | 已发 SYN 未收到响应 | 目标不可达或防火墙丢弃 |
| SYN-RECV | 收到 SYN 已回 SYN+ACK | 大量存在可能遭 SYN 洪水攻击 |

## 四、实战诊断场景

### 1. 查看某端口是否在监听（服务是否启动）
```bash
ss -lntup | grep :22
```

### 2. 统计当前并发连接数
```bash
ss -tn state established | wc -l
```

### 3. 排查 CLOSE-WAIT 堆积（应用未释放连接）
```bash
ss -tn state close-wait
ss -tn state close-wait | awk 'NR>1{print $6}' | sort | uniq -c | sort -rn
```

### 4. 查看 TCP 连接明细（含 RTT 等 TCP 内部参数）
```bash
ss -tin state established
```

### 5. 端口连通性自检（本机是否有进程监听）
```bash
ss -tulnp | grep -E ':80|:22'
```

### 6. 套接字统计摘要
```bash
ss -s
```

## 五、与 netstat 的对比

| 对比项 | netstat | ss |
|--------|---------|-----|
| 数据来源 | /proc/net 解析，慢 | 内核直接读取，快 |
| 输出速度 | 连接多时明显卡顿 | 千级连接毫秒级 |
| TCP 内部信息 | 不支持 | `-i` 支持 RTT/拥塞窗口 |
| 过滤能力 | 弱 | 支持 `state`、`sport`、`dport` 等过滤 |
| 推荐度 | 已逐渐淘汰 | ✅ 强烈推荐 |

## 六、注意事项
- `-p` 显示进程需要 root 权限或与目标进程同属一个用户，否则进程列为空。
- 在容器/沙箱环境中，某些系统套接字（如 `NETLINK`、`VSOCK`）可能不可见，属正常现象。
- `ss -s` 的摘要信息基于 `/proc/net/sockstat*`，不含 UNIX 域套接字统计。
