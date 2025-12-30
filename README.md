# 🚀 VPS 一键网络优化脚本

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/platform-Linux-orange.svg" alt="Platform">
  <img src="https://img.shields.io/badge/shell-bash-brightgreen.svg" alt="Shell">
</p>

<p align="center">
  <b>一键优化 VPS 网络性能，提升代理节点速度</b>
</p>

---

## ✨ 功能特性

| 功能 | 说明 |
|------|------|
| 🚀 **BBR 加速** | 开启 Google BBR 拥塞控制算法 + fq 队列调度 |
| ⚡ **TCP 优化** | 优化 13+ 项 TCP 内核参数 |
| 🌐 **DNS 优化** | 配置 Google + Cloudflare DNS，防止被覆盖 |
| 📁 **连接数优化** | 提升最大连接数和文件描述符限制 |
| 🔄 **自动备份** | 优化前自动备份原配置 |
| ✅ **验证结果** | 优化后自动验证配置是否生效 |

---

## 📦 一键安装

```bash
# 使用 curl
curl -O https://raw.githubusercontent.com/Themogutou/vps-optimize/main/vps_optimize.sh && bash vps_optimize.sh
```

```bash
# 使用 wget
wget https://raw.githubusercontent.com/Themogutou/vps-optimize/main/vps_optimize.sh && bash vps_optimize.sh
```

---

## 📊 优化参数详情

### 🔧 BBR 加速
- `net.core.default_qdisc=fq` - Fair Queue 队列调度
- `net.ipv4.tcp_congestion_control=bbr` - BBR 拥塞控制

### ⚡ TCP 参数优化
| 参数 | 优化值 | 作用 |
|------|--------|------|
| `somaxconn` | 65535 | 最大连接队列 |
| `tcp_fastopen` | 3 | TCP 快速打开 |
| `tcp_fin_timeout` | 30 | FIN 超时时间 |
| `tcp_keepalive_time` | 600 | 保活探测时间 |
| `tcp_tw_reuse` | 1 | 复用 TIME_WAIT |
| `tcp_max_syn_backlog` | 65535 | SYN 队列大小 |
| `netdev_max_backlog` | 65535 | 网络设备队列 |
| `rmem_max / wmem_max` | 16MB | TCP 缓冲区 |
| `swappiness` | 10 | 减少 swap 使用 |

### 🌐 DNS 配置
- 主 DNS：`8.8.8.8` (Google)
- 备 DNS：`1.1.1.1` (Cloudflare)
- 自动锁定防止被系统覆盖
- 禁用 systemd-resolved

### 📁 文件描述符
- `nofile` 限制提升至 65535
- 支持高并发连接

---

## 💻 系统要求

- ✅ **操作系统**：Debian / Ubuntu / CentOS / RHEL
- ✅ **内核版本**：4.9+ (支持 BBR)
- ✅ **权限**：需要 root 权限

---

## 🎯 使用场景

- ✅ 代理节点优化 (V2Ray / Xray / Trojan / SS)
- ✅ 网站服务器加速
- ✅ 游戏服务器优化
- ✅ 任何需要高网络性能的 VPS

---

## 📝 使用说明

1. 下载并运行脚本
2. 脚本会自动备份原配置
3. 依次进行各项优化
4. 显示优化结果验证
5. 建议重启服务器使所有配置生效

---

## 🔄 恢复原配置

如需恢复原配置，备份文件位置：
```bash
/etc/sysctl.conf.backup.*
/etc/security/limits.conf.backup.*
```

---

## ⚠️ 注意事项

- 部分配置需要**重启后**才能完全生效
- 脚本可重复运行，不会产生重复配置
- 建议在新 VPS 上首次部署时使用

---

## 📜 开源协议

本项目采用 [MIT License](LICENSE) 开源协议。

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

---

<p align="center">
  <b>⭐ 如果这个项目对你有帮助，请给个 Star！⭐</b>
</p>
