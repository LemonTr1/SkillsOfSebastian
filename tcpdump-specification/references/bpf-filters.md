# BPF Filter Quick Reference

## Host / Network

```
host 192.168.1.1          # traffic to/from this IP
src host 10.0.0.1         # traffic originating from this IP
dst host 10.0.0.1         # traffic destined to this IP
net 192.168.0.0/24        # entire subnet
```

## Port

```
port 80                   # TCP or UDP port 80
portrange 1000-2000       # any port in range
tcp port 443              # TCP 443 only
udp port 53               # UDP 53 only
src port 22               # originating from port 22
dst port 443              # destined to port 443
```

## Protocol

```
tcp
udp
icmp
arp
ip6
```

## Logic

```
host 1.2.3.4 and port 80
port 80 or port 443
not port 22
host 1.2.3.4 and (port 80 or port 443)
```

## TCP Flags (Advanced)

```
tcp[tcpflags] & tcp-syn != 0       # SYN packets only
tcp[tcpflags] & tcp-rst != 0       # RST packets
tcp[tcpflags] & tcp-fin != 0       # FIN packets
```

## Common Recipes

| Goal | Filter |
|------|--------|
| HTTP only | `tcp port 80` |
| HTTPS only | `tcp port 443` |
| DNS queries | `udp port 53` |
| Ping | `icmp` |
| SSH brute-force watch | `tcp port 22` |
| Exclude SSH noise | `not port 22` |
| Specific host + port | `host 8.8.8.8 and port 53` |
| DHCP | `port 67 or port 68` |
| SYN scan detection | `tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack == 0` |

## Notes

- Quotes are required when the filter contains spaces and is passed as a single shell argument.
- `tcpdump` resolves names by default; use `-nn` to disable (faster, numeric output).
- BPF filters run in kernel space — only matching packets are copied to userspace, so complex filters are efficient.
