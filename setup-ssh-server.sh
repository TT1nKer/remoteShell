#!/bin/bash
# SSH服务器自动化安装和配置脚本
# 使用方法: curl -fsSL https://your-url/setup-ssh-server.sh | bash
# 或者: bash setup-ssh-server.sh

set -e

echo "=================================="
echo "SSH服务器自动化安装脚本"
echo "=================================="
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
echo "检测到操作系统: $OS"
echo ""

# 获取用户信息
CURRENT_USER=$(whoami)
echo "当前用户: $CURRENT_USER"

# macOS 安装
install_macos() {
    echo "📦 配置 macOS SSH 服务器..."
    
    # 启用远程登录
    sudo systemsetup -setremotelogin on
    
    # 确保sshd服务运行
    sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
    
    echo "✅ macOS SSH 服务器已启用"
}

# Linux (Ubuntu/Debian) 安装
install_debian() {
    echo "📦 安装 OpenSSH 服务器..."
    
    # 静默安装
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -qq
    sudo apt-get install -y -qq openssh-server
    
    # 启动并设置开机自启
    sudo systemctl enable ssh --now
    
    echo "✅ OpenSSH 服务器已安装并启动"
}

# Linux (CentOS/RHEL/Fedora) 安装
install_redhat() {
    echo "📦 安装 OpenSSH 服务器..."
    
    sudo yum install -y openssh-server -q
    
    # 启动并设置开机自启
    sudo systemctl enable sshd --now
    
    echo "✅ OpenSSH 服务器已安装并启动"
}

# 配置SSH安全设置
configure_ssh() {
    echo ""
    echo "🔧 配置 SSH 安全设置..."
    
    SSH_CONFIG="/etc/ssh/sshd_config"
    
    # 备份原配置
    sudo cp "$SSH_CONFIG" "${SSH_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # 创建安全配置（保持密码登录以便首次连接）
    sudo tee "${SSH_CONFIG}.d/custom.conf" > /dev/null <<EOF
# 自动配置的安全设置
Port 22
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication yes
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
EOF
    
    # 重启SSH服务
    if [[ "$OS" == "macos" ]]; then
        sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
        sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
    else
        sudo systemctl restart sshd || sudo systemctl restart ssh
    fi
    
    echo "✅ SSH 配置完成"
}

# 配置防火墙
configure_firewall() {
    echo ""
    echo "🔥 配置防火墙..."
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow 22/tcp
        echo "✅ UFW 防火墙已配置"
    elif command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-service=ssh
        sudo firewall-cmd --reload
        echo "✅ Firewalld 防火墙已配置"
    else
        echo "⚠️  未检测到防火墙，跳过配置"
    fi
}

# 获取网络信息
get_network_info() {
    echo ""
    echo "=================================="
    echo "📡 网络信息"
    echo "=================================="
    
    # 本地IP
    if [[ "$OS" == "macos" ]]; then
        LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "未找到")
    else
        LOCAL_IP=$(hostname -I | awk '{print $1}')
    fi
    
    echo "本地IP地址: $LOCAL_IP"
    
    # 尝试获取公网IP
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "无法获取")
    echo "公网IP地址: $PUBLIC_IP"
    
    echo ""
    echo "SSH 连接命令:"
    echo "  本地网络: ssh $CURRENT_USER@$LOCAL_IP"
    echo "  远程连接: ssh $CURRENT_USER@$PUBLIC_IP"
    echo "  (远程连接需要配置路由器端口转发)"
}

# 创建便捷的公钥添加脚本
create_key_helper() {
    echo ""
    echo "📝 创建密钥管理脚本..."
    
    cat > ~/add-ssh-key.sh <<'KEYEOF'
#!/bin/bash
# 快速添加SSH公钥
echo "请粘贴你的SSH公钥 (id_rsa.pub 或 id_ed25519.pub 的内容):"
read -r pubkey

mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "$pubkey" >> ~/.ssh/authorized_keys
echo "✅ 公钥已添加！"
KEYEOF
    
    chmod +x ~/add-ssh-key.sh
    echo "✅ 已创建 ~/add-ssh-key.sh 脚本"
}

# 主安装流程
main() {
    case "$OS" in
        macos)
            install_macos
            ;;
        ubuntu|debian)
            install_debian
            configure_ssh
            configure_firewall
            ;;
        centos|rhel|fedora)
            install_redhat
            configure_ssh
            configure_firewall
            ;;
        *)
            echo "❌ 不支持的操作系统: $OS"
            exit 1
            ;;
    esac
    
    create_key_helper
    get_network_info
    
    echo ""
    echo "=================================="
    echo "✅ 安装完成！"
    echo "=================================="
    echo ""
    echo "下一步操作:"
    echo "1. 配置路由器端口转发 (将外部22端口转发到 $LOCAL_IP:22)"
    echo "2. 从远程位置测试连接: ssh $CURRENT_USER@$PUBLIC_IP"
    echo "3. 连接成功后，运行 ~/add-ssh-key.sh 添加你的公钥"
    echo "4. 添加公钥后，可以禁用密码登录提高安全性"
    echo ""
    echo "提示: 配置文件备份在 /etc/ssh/sshd_config.backup.*"
}

# 检查是否为root或有sudo权限
if ! sudo -v; then
    echo "❌ 需要 sudo 权限才能安装"
    exit 1
fi

main


