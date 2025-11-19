#!/bin/bash
# 最简单的方案：Tailscale + SSH 全自动配置
# 无需配置路由器，无需公网IP，完全P2P加密连接
# 使用方法: bash setup-tailscale-ssh.sh

set -e

echo "=========================================="
echo "🚀 Tailscale + SSH 自动配置脚本"
echo "=========================================="
echo "此脚本将："
echo "  1. 安装并配置 SSH 服务器"
echo "  2. 安装 Tailscale (零配置VPN)"
echo "  3. 自动配置安全连接"
echo ""
echo "优势："
echo "  ✓ 无需配置路由器"
echo "  ✓ 无需公网IP"
echo "  ✓ 点对点加密"
echo "  ✓ 自动穿透NAT"
echo "=========================================="
echo ""

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)
CURRENT_USER=$(whoami)

echo "操作系统: $OS"
echo "当前用户: $CURRENT_USER"
echo ""

# 安装SSH服务器
install_ssh() {
    echo "📦 [1/3] 配置 SSH 服务器..."
    
    case "$OS" in
        macos)
            sudo systemsetup -setremotelogin on
            ;;
        ubuntu|debian)
            export DEBIAN_FRONTEND=noninteractive
            sudo apt-get update -qq
            sudo apt-get install -y -qq openssh-server
            sudo systemctl enable ssh --now
            ;;
        centos|rhel|fedora)
            sudo yum install -y openssh-server -q
            sudo systemctl enable sshd --now
            ;;
    esac
    
    echo "   ✅ SSH 服务器已就绪"
}

# 安装 Tailscale
install_tailscale() {
    echo ""
    echo "📦 [2/3] 安装 Tailscale..."
    
    if command -v tailscale &> /dev/null; then
        echo "   ✅ Tailscale 已安装"
        return
    fi
    
    case "$OS" in
        macos)
            if command -v brew &> /dev/null; then
                brew install tailscale
            else
                echo "   ⚠️  请手动安装 Tailscale: https://tailscale.com/download/mac"
                open "https://tailscale.com/download/mac"
                read -p "   安装完成后按回车继续..."
            fi
            ;;
        ubuntu|debian)
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
        centos|rhel|fedora)
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
    esac
    
    echo "   ✅ Tailscale 安装完成"
}

# 启动 Tailscale
start_tailscale() {
    echo ""
    echo "🔗 [3/3] 启动 Tailscale..."
    echo ""
    echo "⚠️  重要：即将打开浏览器进行账号授权"
    echo "   - 如果没有账号，请用 Google/GitHub/Microsoft 账号登录"
    echo "   - 完全免费，无需信用卡"
    echo ""
    read -p "按回车继续..."
    
    # 启动 Tailscale 并自动打开浏览器授权
    sudo tailscale up
    
    echo ""
    echo "   ✅ Tailscale 已连接"
}

# 获取连接信息
show_connection_info() {
    echo ""
    echo "=========================================="
    echo "🎉 配置完成！"
    echo "=========================================="
    echo ""
    
    # 获取 Tailscale IP
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "未找到")
    
    if [[ "$TAILSCALE_IP" != "未找到" ]]; then
        echo "✅ 你的 Tailscale IP: $TAILSCALE_IP"
        echo ""
        echo "📝 从任何地方连接此电脑："
        echo ""
        echo "   1️⃣  在你的另一台电脑/手机上安装 Tailscale"
        echo "       下载地址: https://tailscale.com/download"
        echo ""
        echo "   2️⃣  使用相同账号登录 Tailscale"
        echo ""
        echo "   3️⃣  SSH 连接命令："
        echo "       ssh $CURRENT_USER@$TAILSCALE_IP"
        echo ""
        echo "=========================================="
        echo "🔐 安全提示"
        echo "=========================================="
        echo "• Tailscale 使用 WireGuard 协议端到端加密"
        echo "• 流量不经过任何中间服务器（点对点）"
        echo "• 只有你的设备能看到这个IP"
        echo "• 首次连接需要输入此电脑的登录密码"
        echo ""
        
        # 创建便捷脚本
        cat > ~/tailscale-info.sh <<EOF
#!/bin/bash
echo "Tailscale SSH 连接信息"
echo "======================"
echo "Tailscale IP: \$(tailscale ip -4)"
echo "用户名: $CURRENT_USER"
echo ""
echo "SSH 命令:"
echo "  ssh $CURRENT_USER@\$(tailscale ip -4)"
echo ""
echo "Tailscale 状态:"
tailscale status
EOF
        chmod +x ~/tailscale-info.sh
        
        echo "💡 小贴士"
        echo "=========================================="
        echo "• 运行 ~/tailscale-info.sh 查看连接信息"
        echo "• 运行 'tailscale status' 查看所有设备"
        echo "• 访问 https://login.tailscale.com/admin/machines"
        echo "  可以在网页管理你的所有设备"
        echo ""
        
    else
        echo "⚠️  无法获取 Tailscale IP"
        echo "   请检查 Tailscale 是否已成功连接"
        echo "   运行: tailscale status"
    fi
}

# 主函数
main() {
    # 检查权限
    if ! sudo -v; then
        echo "❌ 需要 sudo 权限"
        exit 1
    fi
    
    install_ssh
    install_tailscale
    start_tailscale
    show_connection_info
    
    echo "=========================================="
    echo "✨ 全部完成！可以关闭此窗口了"
    echo "=========================================="
}

main


