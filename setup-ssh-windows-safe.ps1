# Windows SSH Server - Safe Version
# This version uses Windows native features and won't trigger antivirus
#
# HOW TO RUN:
# Method 1 (Recommended): Open PowerShell as Administrator, then run:
#   irm https://raw.githubusercontent.com/TT1nKer/remoteShell/main/setup-ssh-windows-safe.ps1 | iex
#
# Method 2: If you downloaded this file, right-click it:
#   - Select "Run with PowerShell"
#   - If you don't see this option, hold Shift + Right-click, then select "Run with PowerShell"
#
# Method 3: Open PowerShell as Administrator in the same folder, then run:
#   .\setup-ssh-windows-safe.ps1
#
# Note: .ps1 is the correct PowerShell script extension
#       Windows may open it with Notepad by default - this is normal
#       DON'T double-click it, use one of the methods above instead

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows SSH Safe Setup Wizard" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ Administrator privileges required" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please follow these steps:" -ForegroundColor Yellow
    Write-Host "1. Right-click this script" -ForegroundColor White
    Write-Host "2. Select 'Run as administrator'" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "✅ Administrator access confirmed" -ForegroundColor Green
Write-Host ""

# Step 1: Check if OpenSSH is installed
Write-Host "Step 1/4: Check OpenSSH Server" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray

$sshCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshCapability.State -eq "Installed") {
    Write-Host "  ✅ OpenSSH Server already installed" -ForegroundColor Green
} else {
    Write-Host "  📦 Installing OpenSSH Server..." -ForegroundColor White
    Write-Host "     (This is an official Windows component, completely safe)" -ForegroundColor Gray
    
    try {
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop | Out-Null
        Write-Host "  ✅ Installation successful" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ Installation failed: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "Please install manually:" -ForegroundColor Yellow
        Write-Host "  Settings → Apps → Optional features → Add a feature → OpenSSH Server" -ForegroundColor White
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host ""

# Step 2: Start service
Write-Host "Step 2/4: Start SSH Service" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray

try {
    $sshdService = Get-Service -Name sshd -ErrorAction Stop
    
    if ($sshdService.Status -ne "Running") {
        Write-Host "  🚀 Starting service..." -ForegroundColor White
        Start-Service sshd -ErrorAction Stop
        Write-Host "  ✅ Service started" -ForegroundColor Green
    } else {
        Write-Host "  ✅ Service already running" -ForegroundColor Green
    }
    
    # Set automatic startup
    if ($sshdService.StartType -ne "Automatic") {
        Write-Host "  ⚙️  Setting automatic startup..." -ForegroundColor White
        Set-Service -Name sshd -StartupType 'Automatic' -ErrorAction Stop
        Write-Host "  ✅ Automatic startup configured" -ForegroundColor Green
    } else {
        Write-Host "  ✅ Automatic startup already configured" -ForegroundColor Green
    }
    
} catch {
    Write-Host "  ❌ Start failed: $_" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""

# Step 3: Configure firewall
Write-Host "Step 3/4: Configure Firewall" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray

$firewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue

if ($null -eq $firewallRule) {
    Write-Host "  🔥 Adding firewall rule..." -ForegroundColor White
    try {
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
            -DisplayName 'OpenSSH Server (sshd)' `
            -Enabled True `
            -Direction Inbound `
            -Protocol TCP `
            -Action Allow `
            -LocalPort 22 `
            -ErrorAction Stop | Out-Null
        Write-Host "  ✅ Firewall rule added" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  Firewall configuration failed: $_" -ForegroundColor Yellow
        Write-Host "     (Manual firewall configuration may be needed)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ✅ Firewall rule already exists" -ForegroundColor Green
}

Write-Host ""

# Step 4: Get network information
Write-Host "Step 4/4: Get Connection Info" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray

$currentUser = $env:USERNAME
$computerName = $env:COMPUTERNAME

# Get local IP
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | 
    Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*"} | 
    Select-Object -First 1).IPAddress

Write-Host "  Local IP: $localIP" -ForegroundColor White
Write-Host "  Computer name: $computerName" -ForegroundColor White
Write-Host "  Current user: $currentUser" -ForegroundColor White

# Try to get public IP (timeout to avoid hanging)
Write-Host ""
Write-Host "  Fetching public IP..." -ForegroundColor Gray
try {
    $publicIP = (Invoke-WebRequest -Uri "http://ifconfig.me/ip" -UseBasicParsing -TimeoutSec 3).Content.Trim()
    Write-Host "  Public IP: $publicIP" -ForegroundColor White
} catch {
    Write-Host "  Public IP: Unable to fetch (normal)" -ForegroundColor Gray
    $publicIP = "<need to check>"
}

Write-Host ""
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ Setup Complete! SSH Server Ready" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📝 Connection Information" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "Local network connection:" -ForegroundColor White
Write-Host "  ssh $currentUser@$localIP" -ForegroundColor Cyan
Write-Host ""

if ($publicIP -ne "<need to check>") {
    Write-Host "Remote connection (requires router config):" -ForegroundColor White
    Write-Host "  ssh $currentUser@$publicIP" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "Tips:" -ForegroundColor Yellow
Write-Host "  • First connection requires Windows login password" -ForegroundColor Gray
Write-Host "  • For external access, configure router port forwarding" -ForegroundColor Gray
Write-Host "  • Recommend using SSH key authentication instead of password" -ForegroundColor Gray
Write-Host ""

# Save info to desktop
$infoFile = "$env:USERPROFILE\Desktop\SSH-Connection-Info.txt"
$infoContent = @"
Windows SSH Server Connection Information
========================================
Setup time: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

Connection info:
  Local IP: $localIP
  Public IP: $publicIP
  Username: $currentUser
  Computer name: $computerName

Local connection:
  ssh $currentUser@$localIP

Remote connection (requires router port forwarding):
  ssh $currentUser@$publicIP

Next steps:
  1. Test connection within same network
  2. Configure router port forwarding (forward port 22 to $localIP)
  3. Setup SSH key authentication (optional but recommended)

Check service status:
  Get-Service sshd

Restart SSH service:
  Restart-Service sshd

Stop SSH service:
  Stop-Service sshd
"@

try {
    $infoContent | Out-File -FilePath $infoFile -Encoding UTF8
    Write-Host "✅ Connection info saved to desktop: SSH-Connection-Info.txt" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Unable to save to desktop, but service is running normally" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Read-Host "Press Enter to exit"

