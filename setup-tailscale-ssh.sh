#!/bin/bash
# Easiest Solution: Tailscale + SSH Full Auto Configuration
# No router config needed, no public IP required, complete P2P encrypted connection
# Usage: curl -fsSL https://raw.githubusercontent.com/TT1nKer/remoteShell/main/setup-tailscale-ssh.sh | bash
# Or: bash setup-tailscale-ssh.sh

set -e

echo "=========================================="
echo "🚀 Tailscale + SSH Auto Setup Script"
echo "=========================================="
echo "This script will:"
echo "  1. Install and configure SSH server"
echo "  2. Install Tailscale (zero-config VPN)"
echo "  3. Automatically configure secure connection"
echo ""
echo "Advantages:"
echo "  ✓ No router configuration needed"
echo "  ✓ No public IP required"
echo "  ✓ Point-to-point encryption"
echo "  ✓ Automatic NAT traversal"
echo "=========================================="
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
CURRENT_USER=$(whoami)

echo "Operating System: $OS"
echo "Current User: $CURRENT_USER"
echo ""

# Install SSH server
install_ssh() {
    echo "📦 [1/3] Configuring SSH server..."
    
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
    
    echo "   ✅ SSH server ready"
}

# Install Tailscale
install_tailscale() {
    echo ""
    echo "📦 [2/3] Installing Tailscale..."
    
    if command -v tailscale &> /dev/null; then
        echo "   ✅ Tailscale already installed"
        return
    fi
    
    case "$OS" in
        macos)
            if command -v brew &> /dev/null; then
                brew install tailscale
            else
                echo "   ⚠️  Please install Tailscale manually: https://tailscale.com/download/mac"
                open "https://tailscale.com/download/mac"
                read -p "   Press Enter after installation..."
            fi
            ;;
        ubuntu|debian)
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
        centos|rhel|fedora)
            curl -fsSL https://tailscale.com/install.sh | sh
            ;;
    esac
    
    echo "   ✅ Tailscale installation complete"
}

# Start Tailscale
start_tailscale() {
    echo ""
    echo "🔗 [3/3] Starting Tailscale..."
    echo ""
    echo "⚠️  Important: Browser will open for account authorization"
    echo "   - If you don't have an account, login with Google/GitHub/Microsoft"
    echo "   - Completely free, no credit card required"
    echo ""
    read -p "Press Enter to continue..."
    
    # Start Tailscale and auto-open browser for authorization
    sudo tailscale up
    
    echo ""
    echo "   ✅ Tailscale connected"
}

# Show connection info
show_connection_info() {
    echo ""
    echo "=========================================="
    echo "🎉 Setup Complete!"
    echo "=========================================="
    echo ""
    
    # Get Tailscale IP
    TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || echo "not found")
    
    if [[ "$TAILSCALE_IP" != "not found" ]]; then
        echo "✅ Your Tailscale IP: $TAILSCALE_IP"
        echo ""
        echo "📝 Connect to this computer from anywhere:"
        echo ""
        echo "   1️⃣  Install Tailscale on your other computer/phone"
        echo "       Download: https://tailscale.com/download"
        echo ""
        echo "   2️⃣  Login with the same account"
        echo ""
        echo "   3️⃣  SSH connection command:"
        echo "       ssh $CURRENT_USER@$TAILSCALE_IP"
        echo ""
        echo "=========================================="
        echo "🔐 Security Info"
        echo "=========================================="
        echo "• Tailscale uses WireGuard protocol for end-to-end encryption"
        echo "• Traffic doesn't go through any intermediate servers (peer-to-peer)"
        echo "• Only your devices can see this IP"
        echo "• First connection requires this computer's login password"
        echo ""
        
        # Create convenience script
        cat > ~/tailscale-info.sh <<EOF
#!/bin/bash
echo "Tailscale SSH Connection Information"
echo "====================================="
echo "Tailscale IP: \$(tailscale ip -4)"
echo "Username: $CURRENT_USER"
echo ""
echo "SSH command:"
echo "  ssh $CURRENT_USER@\$(tailscale ip -4)"
echo ""
echo "Tailscale status:"
tailscale status
EOF
        chmod +x ~/tailscale-info.sh
        
        echo "💡 Tips"
        echo "=========================================="
        echo "• Run ~/tailscale-info.sh to view connection info"
        echo "• Run 'tailscale status' to see all devices"
        echo "• Visit https://login.tailscale.com/admin/machines"
        echo "  to manage all your devices via web"
        echo ""
        
    else
        echo "⚠️  Unable to get Tailscale IP"
        echo "   Please check if Tailscale connected successfully"
        echo "   Run: tailscale status"
    fi
}

# Main function
main() {
    # Check permissions
    if ! sudo -v; then
        echo "❌ Sudo privileges required"
        exit 1
    fi
    
    install_ssh
    install_tailscale
    start_tailscale
    show_connection_info
    
    echo "=========================================="
    echo "✨ All done! You can close this window now"
    echo "=========================================="
}

main

