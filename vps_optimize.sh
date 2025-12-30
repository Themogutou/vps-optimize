#!/bin/bash

# ===================================
# 🚀 VPS 一键网络优化脚本
# ===================================
# 功能：BBR加速、TCP优化、连接数优化、DNS优化
# 作者：Antigravity AI
# 日期：2025-12-30
# 使用：bash vps_optimize.sh
# ===================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 检查是否 root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}❌ 请使用 root 用户运行此脚本！${NC}"
        echo "使用: sudo bash vps_optimize.sh"
        exit 1
    fi
}

# 打印横幅
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║         🚀 VPS 一键网络优化脚本 v1.0 🚀                  ║"
    echo "║                                                           ║"
    echo "║   功能：BBR加速 | TCP优化 | 连接数 | DNS优化            ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${YELLOW}开始时间: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo ""
}

# 备份原配置
backup_config() {
    echo -e "${BLUE}📦 备份原配置...${NC}"
    cp /etc/sysctl.conf /etc/sysctl.conf.backup.$(date +%Y%m%d%H%M%S) 2>/dev/null
    cp /etc/security/limits.conf /etc/security/limits.conf.backup.$(date +%Y%m%d%H%M%S) 2>/dev/null
    echo -e "${GREEN}✅ 备份完成${NC}"
    echo ""
}

# 优化 DNS（完善版）
optimize_dns() {
    echo -e "${BLUE}🌐 [1/5] 优化 DNS...${NC}"
    
    # 如果 resolv.conf 是符号链接，先删除
    if [ -L /etc/resolv.conf ]; then
        echo -e "${YELLOW}  检测到符号链接，正在处理...${NC}"
        chattr -i /etc/resolv.conf 2>/dev/null || true
        rm -f /etc/resolv.conf
        touch /etc/resolv.conf
    fi
    
    # 解锁文件（如果之前锁过）
    chattr -i /etc/resolv.conf 2>/dev/null || true
    
    # 写入 DNS
    cat > /etc/resolv.conf << EOF
nameserver 8.8.8.8
nameserver 1.1.1.1
nameserver 8.8.4.4
EOF
    
    # 锁定文件防止被覆盖
    chattr +i /etc/resolv.conf 2>/dev/null || true
    
    # 禁用 systemd-resolved（如果存在）
    if systemctl is-enabled systemd-resolved &>/dev/null; then
        echo -e "${YELLOW}  正在禁用 systemd-resolved...${NC}"
        systemctl disable --now systemd-resolved 2>/dev/null || true
    fi
    
    # 写入 rc.local 确保重启后生效
    if [ ! -f /etc/rc.local ]; then
        echo -e "#!/bin/bash\nexit 0" > /etc/rc.local
        chmod +x /etc/rc.local
    fi
    
    # 避免重复添加
    if ! grep -q "resolv.conf" /etc/rc.local 2>/dev/null; then
        sed -i '1a\chattr -i /etc/resolv.conf 2>/dev/null; echo -e "nameserver 8.8.8.8\\nnameserver 1.1.1.1" > /etc/resolv.conf; chattr +i /etc/resolv.conf 2>/dev/null' /etc/rc.local 2>/dev/null || true
    fi
    
    echo -e "${GREEN}✅ DNS 已设置并锁定 (8.8.8.8 + 1.1.1.1)${NC}"
    echo ""
}


# 开启 BBR
enable_bbr() {
    echo -e "${BLUE}⚡ [2/5] 开启 BBR 加速...${NC}"
    
    # 检查内核版本
    kernel_version=$(uname -r | cut -d. -f1)
    kernel_minor=$(uname -r | cut -d. -f2)
    
    if [ "$kernel_version" -lt 4 ] || ([ "$kernel_version" -eq 4 ] && [ "$kernel_minor" -lt 9 ]); then
        echo -e "${YELLOW}⚠️ 内核版本过低 (需要 4.9+)，BBR 可能不支持${NC}"
    fi
    
    # 检查 BBR 模块是否存在
    if ! modprobe tcp_bbr 2>/dev/null; then
        echo -e "${YELLOW}⚠️ BBR 模块可能不可用${NC}"
    fi
    
    # 检查是否已开启
    current_cc=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    if [ "$current_cc" = "bbr" ]; then
        echo -e "${GREEN}✅ BBR 已经开启${NC}"
    else
        # 检查是否已配置（避免重复添加）
        if ! grep -q "tcp_congestion_control=bbr" /etc/sysctl.conf 2>/dev/null; then
            echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
            echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
        fi
        echo -e "${GREEN}✅ BBR 配置已添加${NC}"
    fi
    echo ""
}

# 优化 TCP 参数
optimize_tcp() {
    echo -e "${BLUE}🔧 [3/5] 优化 TCP 参数...${NC}"
    
    # 检查是否已配置（避免重复添加）
    if grep -q "VPS 网络优化配置" /etc/sysctl.conf 2>/dev/null; then
        echo -e "${GREEN}✅ TCP 参数已配置过，跳过${NC}"
        echo ""
        return
    fi
    
    # 创建优化配置
    cat >> /etc/sysctl.conf << 'EOF'

# ===== VPS 网络优化配置 =====

# 最大连接队列 (重要！)
net.core.somaxconn=65535

# TCP 快速打开
net.ipv4.tcp_fastopen=3

# 减少 FIN 超时时间
net.ipv4.tcp_fin_timeout=30

# 减少 keepalive 时间
net.ipv4.tcp_keepalive_time=600
net.ipv4.tcp_keepalive_intvl=30
net.ipv4.tcp_keepalive_probes=3

# TIME_WAIT 优化
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_max_tw_buckets=5000

# SYN 队列优化
net.ipv4.tcp_max_syn_backlog=65535
net.ipv4.tcp_syncookies=1

# 网络设备队列
net.core.netdev_max_backlog=65535

# TCP 缓冲区优化
net.core.rmem_max=16777216
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 87380 16777216
net.ipv4.tcp_wmem=4096 65536 16777216

# 减少 swap 使用
vm.swappiness=10

# 本地端口范围
net.ipv4.ip_local_port_range=1024 65535

# ===== 优化配置结束 =====
EOF
    
    echo -e "${GREEN}✅ TCP 参数已优化${NC}"
    echo ""
}

# 优化文件描述符限制
optimize_limits() {
    echo -e "${BLUE}📁 [4/5] 优化文件描述符限制...${NC}"
    
    # 检查是否已配置
    if grep -q "nofile 65535" /etc/security/limits.conf; then
        echo -e "${GREEN}✅ 文件描述符限制已配置${NC}"
    else
        cat >> /etc/security/limits.conf << 'EOF'

# VPS 优化 - 文件描述符限制
* soft nofile 65535
* hard nofile 65535
root soft nofile 65535
root hard nofile 65535
* soft nproc 65535
* hard nproc 65535
EOF
        echo -e "${GREEN}✅ 文件描述符限制已优化${NC}"
    fi
    
    # 确保 PAM 加载 limits
    if ! grep -q "pam_limits.so" /etc/pam.d/common-session 2>/dev/null; then
        echo "session required pam_limits.so" >> /etc/pam.d/common-session 2>/dev/null
    fi
    
    # 当前 session 立即生效
    ulimit -n 65535 2>/dev/null
    
    echo ""
}


# 应用所有配置
apply_config() {
    echo -e "${BLUE}🔄 [5/5] 应用配置...${NC}"
    
    # 去除重复行
    awk '!seen[$0]++' /etc/sysctl.conf > /tmp/sysctl_clean.conf
    mv /tmp/sysctl_clean.conf /etc/sysctl.conf
    
    # 应用 sysctl 配置
    sysctl -p 2>/dev/null
    
    echo -e "${GREEN}✅ 配置已应用${NC}"
    echo ""
}

# 验证优化结果
verify_optimization() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}📊 优化结果验证${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    
    # BBR
    bbr=$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)
    if [ "$bbr" = "bbr" ]; then
        echo -e "  ✅ BBR 加速:        ${GREEN}已开启${NC}"
    else
        echo -e "  ⚠️ BBR 加速:        ${YELLOW}$bbr (需重启生效)${NC}"
    fi
    
    # 队列调度
    qdisc=$(sysctl -n net.core.default_qdisc 2>/dev/null)
    if [ "$qdisc" = "fq" ]; then
        echo -e "  ✅ 队列调度:        ${GREEN}fq (推荐)${NC}"
    else
        echo -e "  ⚠️ 队列调度:        ${YELLOW}$qdisc${NC}"
    fi
    
    # TCP Fast Open
    tfo=$(cat /proc/sys/net/ipv4/tcp_fastopen 2>/dev/null)
    if [ "$tfo" -ge 3 ]; then
        echo -e "  ✅ TCP Fast Open:   ${GREEN}已开启${NC}"
    else
        echo -e "  ⚠️ TCP Fast Open:   ${YELLOW}$tfo${NC}"
    fi
    
    # somaxconn
    somaxconn=$(cat /proc/sys/net/core/somaxconn 2>/dev/null)
    if [ "$somaxconn" -ge 65535 ]; then
        echo -e "  ✅ somaxconn:       ${GREEN}$somaxconn${NC}"
    else
        echo -e "  ⚠️ somaxconn:       ${YELLOW}$somaxconn (需重启生效)${NC}"
    fi
    
    # fin_timeout
    fin=$(cat /proc/sys/net/ipv4/tcp_fin_timeout 2>/dev/null)
    echo -e "  ✅ fin_timeout:     ${GREEN}${fin}s${NC}"
    
    # keepalive
    keepalive=$(cat /proc/sys/net/ipv4/tcp_keepalive_time 2>/dev/null)
    echo -e "  ✅ keepalive_time:  ${GREEN}${keepalive}s${NC}"
    
    # swappiness
    swap=$(cat /proc/sys/vm/swappiness 2>/dev/null)
    echo -e "  ✅ swappiness:      ${GREEN}$swap${NC}"
    
    # ulimit
    ulimit_n=$(ulimit -n 2>/dev/null)
    echo -e "  ✅ ulimit nofile:   ${GREEN}$ulimit_n${NC}"
    
    # DNS
    echo ""
    echo -e "  ${CYAN}DNS 服务器:${NC}"
    grep nameserver /etc/resolv.conf 2>/dev/null | awk '{print "    " $2}'
    
    echo ""
}

# 显示使用建议
show_tips() {
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}💡 使用建议${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  1. ${GREEN}建议重启服务器${NC}让所有配置完全生效"
    echo -e "     命令: ${CYAN}reboot${NC}"
    echo ""
    echo -e "  2. 重启后可运行以下命令验证:"
    echo -e "     ${CYAN}sysctl net.ipv4.tcp_congestion_control${NC}"
    echo -e "     ${CYAN}ulimit -n${NC}"
    echo ""
    echo -e "  3. 如需恢复原配置，备份文件在:"
    echo -e "     ${CYAN}/etc/sysctl.conf.backup.*${NC}"
    echo ""
}

# 主函数
main() {
    check_root
    print_banner
    backup_config
    optimize_dns
    enable_bbr
    optimize_tcp
    optimize_limits

    apply_config
    verify_optimization
    show_tips
    
    echo -e "${GREEN}🎉 优化完成！${NC}"
    echo ""
    
    # 询问是否重启
    read -p "是否现在重启服务器? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}正在重启...${NC}"
        reboot
    else
        echo -e "${YELLOW}请稍后手动重启以使所有配置生效。${NC}"
    fi
}

# 运行
main
