# Windows SSH服务器自动化安装脚本
# 使用方法: 以管理员身份运行 PowerShell，然后执行:
# irm https://raw.githubusercontent.com/TT1nKer/remoteShell/main/setup-ssh-server.ps1 | iex
# 或者: .\setup-ssh-server.ps1

#Requires -RunAsAdministrator

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Windows SSH服务器自动化安装脚本" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# 安装 OpenSSH Server
Write-Host "📦 安装 OpenSSH 服务器..." -ForegroundColor Yellow

# 检查是否已安装
$sshInstalled = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshInstalled.State -eq "Installed") {
    Write-Host "✅ OpenSSH Server 已安装" -ForegroundColor Green
} else {
    Write-Host "正在安装 OpenSSH Server..." -ForegroundColor Yellow
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
    Write-Host "✅ OpenSSH Server 安装完成" -ForegroundColor Green
}

# 启动并设置自动启动
Write-Host ""
Write-Host "🚀 启动 SSH 服务..." -ForegroundColor Yellow

Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'

# 启动 ssh-agent
Start-Service ssh-agent
Set-Service -Name ssh-agent -StartupType 'Automatic'

Write-Host "✅ SSH 服务已启动" -ForegroundColor Green

# 配置防火墙
Write-Host ""
Write-Host "🔥 配置防火墙..." -ForegroundColor Yellow

$firewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if ($null -eq $firewallRule) {
    New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22
    Write-Host "✅ 防火墙规则已创建" -ForegroundColor Green
} else {
    Write-Host "✅ 防火墙规则已存在" -ForegroundColor Green
}

# 配置 SSH
Write-Host ""
Write-Host "🔧 配置 SSH..." -ForegroundColor Yellow

$sshdConfigPath = "$env:ProgramData\ssh\sshd_config"

# 备份配置文件
$backupPath = "$sshdConfigPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item -Path $sshdConfigPath -Destination $backupPath

# 修改配置（允许密码登录和公钥认证）
$config = Get-Content $sshdConfigPath
$config = $config -replace '#PubkeyAuthentication yes', 'PubkeyAuthentication yes'
$config = $config -replace '#PasswordAuthentication yes', 'PasswordAuthentication yes'
$config = $config -replace 'Match Group administrators', '#Match Group administrators'
$config = $config -replace '       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys', '#       AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys'

$config | Set-Content $sshdConfigPath

Write-Host "✅ SSH 配置完成" -ForegroundColor Green

# 重启服务以应用配置
Restart-Service sshd

# 获取网络信息
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "📡 网络信息" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*"} | Select-Object -First 1).IPAddress
$currentUser = $env:USERNAME

Write-Host "本地IP地址: $localIP" -ForegroundColor White
Write-Host "当前用户: $currentUser" -ForegroundColor White

try {
    $publicIP = (Invoke-WebRequest -Uri "http://ifconfig.me/ip" -UseBasicParsing -TimeoutSec 5).Content.Trim()
    Write-Host "公网IP地址: $publicIP" -ForegroundColor White
} catch {
    Write-Host "公网IP地址: 无法获取" -ForegroundColor Yellow
    $publicIP = "YOUR_PUBLIC_IP"
}

Write-Host ""
Write-Host "SSH 连接命令:" -ForegroundColor Cyan
Write-Host "  本地网络: ssh $currentUser@$localIP" -ForegroundColor White
Write-Host "  远程连接: ssh $currentUser@$publicIP" -ForegroundColor White
Write-Host "  (远程连接需要配置路由器端口转发)" -ForegroundColor Yellow

# 创建添加公钥的脚本
Write-Host ""
Write-Host "📝 创建密钥管理脚本..." -ForegroundColor Yellow

$keyHelperScript = @'
# 快速添加SSH公钥
Write-Host "请粘贴你的SSH公钥 (id_rsa.pub 或 id_ed25519.pub 的内容):"
$pubkey = Read-Host

$sshDir = "$env:USERPROFILE\.ssh"
$authorizedKeysPath = "$sshDir\authorized_keys"

# 创建 .ssh 目录
if (-not (Test-Path $sshDir)) {
    New-Item -ItemType Directory -Path $sshDir | Out-Null
}

# 添加公钥
Add-Content -Path $authorizedKeysPath -Value $pubkey

# 设置权限
icacls $sshDir /inheritance:r
icacls $sshDir /grant:r "$env:USERNAME:(OI)(CI)F"
icacls $authorizedKeysPath /inheritance:r
icacls $authorizedKeysPath /grant:r "$env:USERNAME:F"

Write-Host "✅ 公钥已添加！" -ForegroundColor Green
'@

$keyHelperScript | Out-File -FilePath "$env:USERPROFILE\Desktop\add-ssh-key.ps1" -Encoding UTF8
Write-Host "✅ 已创建桌面快捷方式: add-ssh-key.ps1" -ForegroundColor Green

# 完成
Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "✅ 安装完成！" -ForegroundColor Green
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步操作:" -ForegroundColor Yellow
Write-Host "1. 配置路由器端口转发 (将外部22端口转发到 $localIP`:22)" -ForegroundColor White
Write-Host "2. 从远程位置测试连接: ssh $currentUser@$publicIP" -ForegroundColor White
Write-Host "3. 连接成功后，运行桌面上的 add-ssh-key.ps1 添加你的公钥" -ForegroundColor White
Write-Host "4. 添加公钥后，可以禁用密码登录提高安全性" -ForegroundColor White
Write-Host ""
Write-Host "提示: 配置文件备份在 $backupPath" -ForegroundColor Gray


