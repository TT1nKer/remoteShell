#!/bin/bash
# SSH Server Automated Installation and Configuration Script
# Usage: curl -fsSL https://raw.githubusercontent.com/TT1nKer/remoteShell/main/setup-ssh-server.sh | bash
# Or: bash setup-ssh-server.sh

set -e

echo "=================================="
echo "SSH Server Auto-Install Script"
echo "=================================="
echo ""

# Detect operating system
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
echo "Detected OS: $OS"
echo ""

# Get user info
CURRENT_USER=$(whoami)
echo "Current user: $CURRENT_USER"

# macOS installation
install_macos() {
    echo "📦 Configuring macOS SSH server..."
    
    # Enable remote login
    sudo systemsetup -setremotelogin on
    
    # Ensure sshd service is running
    sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
    
    echo "✅ macOS SSH server enabled"
}

# Linux (Ubuntu/Debian) installation
install_debian() {
    echo "📦 Installing OpenSSH server..."
    
    # Silent installation
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -qq
    sudo apt-get install -y -qq openssh-server
    
    # Start and enable on boot
    sudo systemctl enable ssh --now
    
    echo "✅ OpenSSH server installed and started"
}

# Linux (CentOS/RHEL/Fedora) installation
install_redhat() {
    echo "📦 Installing OpenSSH server..."
    
    sudo yum install -y openssh-server -q
    
    # Start and enable on boot
    sudo systemctl enable sshd --now
    
    echo "✅ OpenSSH server installed and started"
}

# Configure SSH security settings
configure_ssh() {
    echo ""
    echo "🔧 Configuring SSH security settings..."
    
    SSH_CONFIG="/etc/ssh/sshd_config"
    
    # Backup original config
    sudo cp "$SSH_CONFIG" "${SSH_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Create secure configuration (keep password login for initial connection)
    sudo tee "${SSH_CONFIG}.d/custom.conf" > /dev/null <<EOF
# Auto-configured security settings
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
    
    # Restart SSH service
    if [[ "$OS" == "macos" ]]; then
        sudo launchctl unload /System/Library/LaunchDaemons/ssh.plist 2>/dev/null || true
        sudo launchctl load -w /System/Library/LaunchDaemons/ssh.plist
    else
        sudo systemctl restart sshd || sudo systemctl restart ssh
    fi
    
    echo "✅ SSH configuration complete"
}

# Configure firewall
configure_firewall() {
    echo ""
    echo "🔥 Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        sudo ufw allow 22/tcp
        echo "✅ UFW firewall configured"
    elif command -v firewall-cmd &> /dev/null; then
        sudo firewall-cmd --permanent --add-service=ssh
        sudo firewall-cmd --reload
        echo "✅ Firewalld configured"
    else
        echo "⚠️  No firewall detected, skipping configuration"
    fi
}

# Get network information
get_network_info() {
    echo ""
    echo "=================================="
    echo "📡 Network Information"
    echo "=================================="
    
    # Local IP
    if [[ "$OS" == "macos" ]]; then
        LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "not found")
    else
        LOCAL_IP=$(hostname -I | awk '{print $1}')
    fi
    
    echo "Local IP address: $LOCAL_IP"
    
    # Try to get public IP
    PUBLIC_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || echo "unable to fetch")
    echo "Public IP address: $PUBLIC_IP"
    
    echo ""
    echo "SSH connection commands:"
    echo "  Local network: ssh $CURRENT_USER@$LOCAL_IP"
    echo "  Remote connection: ssh $CURRENT_USER@$PUBLIC_IP"
    echo "  (Remote connection requires router port forwarding)"
}

# Create convenient key management script
create_key_helper() {
    echo ""
    echo "📝 Creating key management script..."
    
    cat > ~/add-ssh-key.sh <<'KEYEOF'
#!/bin/bash
# Quick add SSH public key
echo "Paste your SSH public key (contents of id_rsa.pub or id_ed25519.pub):"
read -r pubkey

mkdir -p ~/.ssh
chmod 700 ~/.ssh
touch ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

echo "$pubkey" >> ~/.ssh/authorized_keys
echo "✅ Public key added!"
KEYEOF
    
    chmod +x ~/add-ssh-key.sh
    echo "✅ Created ~/add-ssh-key.sh script"
}

# Main installation workflow
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
            echo "❌ Unsupported operating system: $OS"
            exit 1
            ;;
    esac
    
    create_key_helper
    get_network_info
    
    echo ""
    echo "=================================="
    echo "✅ Installation Complete!"
    echo "=================================="
    echo ""
    echo "Next steps:"
    echo "1. Configure router port forwarding (forward external port 22 to $LOCAL_IP:22)"
    echo "2. Test connection from remote location: ssh $CURRENT_USER@$PUBLIC_IP"
    echo "3. After successful connection, run ~/add-ssh-key.sh to add your public key"
    echo "4. After adding key, you can disable password login for better security"
    echo ""
    echo "Tip: Configuration backup at /etc/ssh/sshd_config.backup.*"
}

# Check for root or sudo privileges
if ! sudo -v; then
    echo "❌ Sudo privileges required"
    exit 1
fi

main

