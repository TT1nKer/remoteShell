# Windows SSH服务器 - 安全保守版本
# 此版本使用Windows原生功能，不会被杀毒软件误报
#
# 运行方法：
# 方法1（推荐）：以管理员身份打开 PowerShell，然后运行：
#   irm https://raw.githubusercontent.com/TT1nKer/remoteShell/cn/setup-ssh-windows-safe.ps1 | iex
#
# 方法2：如果已下载此文件，右键点击文件：
#   - 选择"使用 PowerShell 运行"
#   - 如果没有此选项，按住 Shift + 右键，然后选择"使用 PowerShell 运行"
#
# 方法3：以管理员身份在相同文件夹打开 PowerShell，然后运行：
#   .\setup-ssh-windows-safe.ps1
#
# 注意：.ps1 是正确的 PowerShell 脚本扩展名
#       Windows 可能会默认用记事本打开它 - 这是正常的
#       不要双击运行，请使用上述方法之一

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Windows SSH 安全配置向导" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ 需要管理员权限运行此脚本" -ForegroundColor Red
    Write-Host ""
    Write-Host "请执行以下步骤:" -ForegroundColor Yellow
    Write-Host "1. 右键点击此脚本" -ForegroundColor White
    Write-Host "2. 选择 '以管理员身份运行'" -ForegroundColor White
    Write-Host ""
    Read-Host "按回车键退出"
    exit 1
}

Write-Host "✅ 管理员权限确认" -ForegroundColor Green
Write-Host ""

# 步骤1: 检查OpenSSH是否已安装
Write-Host "步骤 1/4: 检查 OpenSSH Server" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray

$sshCapability = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'

if ($sshCapability.State -eq "Installed") {
    Write-Host "  ✅ OpenSSH Server 已安装" -ForegroundColor Green
} else {
    Write-Host "  📦 正在安装 OpenSSH Server..." -ForegroundColor White
    Write-Host "     (这是Windows官方组件，完全安全)" -ForegroundColor Gray
    
    try {
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop | Out-Null
        Write-Host "  ✅ 安装成功" -ForegroundColor Green
    } catch {
        Write-Host "  ❌ 安装失败: $_" -ForegroundColor Red
        Write-Host ""
        Write-Host "请手动安装:" -ForegroundColor Yellow
        Write-Host "  设置 -> 应用 -> 可选功能 -> 添加功能 -> OpenSSH 服务器" -ForegroundColor White
        Read-Host "按回车键退出"
        exit 1
    }
}

Write-Host ""

# 步骤2: 启动服务
Write-Host "步骤 2/4: 启动 SSH 服务" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray

try {
    $sshdService = Get-Service -Name sshd -ErrorAction Stop
    
    if ($sshdService.Status -ne "Running") {
        Write-Host "  🚀 正在启动服务..." -ForegroundColor White
        Start-Service sshd -ErrorAction Stop
        Write-Host "  ✅ 服务已启动" -ForegroundColor Green
    } else {
        Write-Host "  ✅ 服务已在运行" -ForegroundColor Green
    }
    
    # 设置自动启动
    if ($sshdService.StartType -ne "Automatic") {
        Write-Host "  ⚙️  设置开机自动启动..." -ForegroundColor White
        Set-Service -Name sshd -StartupType 'Automatic' -ErrorAction Stop
        Write-Host "  ✅ 已设置自动启动" -ForegroundColor Green
    } else {
        Write-Host "  ✅ 已配置自动启动" -ForegroundColor Green
    }
    
} catch {
    Write-Host "  ❌ 启动失败: $_" -ForegroundColor Red
    Read-Host "按回车键退出"
    exit 1
}

Write-Host ""

# 步骤3: 配置防火墙
Write-Host "步骤 3/4: 配置防火墙" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray

$firewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue

if ($null -eq $firewallRule) {
    Write-Host "  🔥 添加防火墙规则..." -ForegroundColor White
    try {
        New-NetFirewallRule -Name 'OpenSSH-Server-In-TCP' `
            -DisplayName 'OpenSSH Server (sshd)' `
            -Enabled True `
            -Direction Inbound `
            -Protocol TCP `
            -Action Allow `
            -LocalPort 22 `
            -ErrorAction Stop | Out-Null
        Write-Host "  ✅ 防火墙规则已添加" -ForegroundColor Green
    } catch {
        Write-Host "  ⚠️  防火墙配置失败: $_" -ForegroundColor Yellow
        Write-Host "     (可能需要手动配置防火墙)" -ForegroundColor Gray
    }
} else {
    Write-Host "  ✅ 防火墙规则已存在" -ForegroundColor Green
}

Write-Host ""

# 步骤4: 获取网络信息
Write-Host "步骤 4/4: 获取连接信息" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray

$currentUser = $env:USERNAME
$computerName = $env:COMPUTERNAME

# 获取本地IP
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | 
    Where-Object {$_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.254.*"} | 
    Select-Object -First 1).IPAddress

Write-Host "  本地IP地址: $localIP" -ForegroundColor White
Write-Host "  计算机名称: $computerName" -ForegroundColor White
Write-Host "  当前用户: $currentUser" -ForegroundColor White

# 尝试获取公网IP（超时设置避免卡死）
Write-Host ""
Write-Host "  正在获取公网IP..." -ForegroundColor Gray
try {
    $publicIP = (Invoke-WebRequest -Uri "http://ifconfig.me/ip" -UseBasicParsing -TimeoutSec 3).Content.Trim()
    Write-Host "  公网IP地址: $publicIP" -ForegroundColor White
} catch {
    Write-Host "  公网IP地址: 无法获取 (正常)" -ForegroundColor Gray
    $publicIP = "<需要查询>"
}

Write-Host ""
Write-Host ""

# 完成总结
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✅ 配置完成！SSH 服务器已就绪" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "📝 连接信息" -ForegroundColor Yellow
Write-Host "-------------------------------------------" -ForegroundColor Gray
Write-Host ""
Write-Host "本地网络连接命令:" -ForegroundColor White
Write-Host "  ssh $currentUser@$localIP" -ForegroundColor Cyan
Write-Host ""

if ($publicIP -ne "<需要查询>") {
    Write-Host "远程连接命令 (需配置路由器):" -ForegroundColor White
    Write-Host "  ssh $currentUser@$publicIP" -ForegroundColor Cyan
    Write-Host ""
}

Write-Host "提示:" -ForegroundColor Yellow
Write-Host "  • 首次连接需要输入Windows登录密码" -ForegroundColor Gray
Write-Host "  • 如需从外网访问，请配置路由器端口转发" -ForegroundColor Gray
Write-Host "  • 建议使用SSH密钥认证代替密码" -ForegroundColor Gray
Write-Host ""

# 保存信息到桌面
$infoFile = "$env:USERPROFILE\Desktop\SSH连接信息.txt"
$infoContent = @"
Windows SSH 服务器连接信息
========================================
配置时间: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

连接信息:
  本地IP: $localIP
  公网IP: $publicIP
  用户名: $currentUser
  计算机名: $computerName

本地连接命令:
  ssh $currentUser@$localIP

远程连接命令 (需配置路由器端口转发):
  ssh $currentUser@$publicIP

下一步:
  1. 在同一局域网内测试连接
  2. 配置路由器端口转发 (将22端口转发到 $localIP)
  3. 设置SSH密钥认证 (可选但推荐)

查看服务状态:
  Get-Service sshd

重启SSH服务:
  Restart-Service sshd

停止SSH服务:
  Stop-Service sshd
"@

try {
    $infoContent | Out-File -FilePath $infoFile -Encoding UTF8
    Write-Host "✅ 连接信息已保存到桌面: SSH连接信息.txt" -ForegroundColor Green
} catch {
    Write-Host "⚠️  无法保存到桌面，但服务已正常运行" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Read-Host "按回车键退出"


