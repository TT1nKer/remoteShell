# 远程SSH配置

## 最快方案（5分钟）

### Tailscale + SSH

1. 下载安装 Tailscale: https://tailscale.com/download
2. 登录（用 Google/GitHub 账号）
3. 启用SSH:

**Windows（10 1809+/11）:**
```
设置 → 应用 → 可选功能 → OpenSSH Server → 安装
services.msc → OpenSSH SSH Server → 启动
```

**Windows（PowerShell 备选）:**
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# 如果卡在40%，用 DISM 替代：
dism /Online /Add-Capability /CapabilityName:OpenSSH.Server~~~~0.0.1.0
```

**Mac:**
```bash
# 通过图形界面（推荐）：系统设置 → 共享 → 远程登录 开启
# 或通过终端：
sudo systemsetup -setremotelogin on
```
*注意：终端方法需要完全磁盘访问权限*

**Linux:**
```bash
sudo apt install openssh-server -y
```

4. 获取IP: `tailscale ip -4`
5. 连接: `ssh 用户名@100.x.x.x`

---

## 传统SSH方案

### 自动脚本

**Windows:**
```powershell
# 以管理员运行 PowerShell
.\setup-ssh-windows-safe.ps1
```

**Mac/Linux:**
```bash
sudo bash setup-ssh-server.sh
```

### 手动安装

**Windows:**
设置 → 应用 → OpenSSH Server → 安装 + 启动服务

**Mac:**
`sudo systemsetup -setremotelogin on`

**Linux:**
`sudo apt install openssh-server`

然后配置路由器端口转发（22 → 本机IP）

---

## 文件说明

### 中文文档
- `START_HERE_开始阅读.md` - 快速开始指南 ⭐ **从这里开始！**
- `解决杀毒软件拦截的完整方案.md` - 杀毒软件解决方案
- `QUICK_START.md` - 详细快速指南
- `README_SSH_SETUP.md` - 完整技术文档
- `WINDOWS_SAFE_GUIDE.md` - Windows 安全指南

### 自动化脚本
- `setup-ssh-server.sh` - Linux/Mac 自动安装
- `setup-ssh-windows-safe.ps1` - Windows 安全安装
- `setup-tailscale-ssh.sh` - Tailscale 自动安装

### 一键安装命令

**Linux/Mac:**
```bash
curl -fsSL https://raw.githubusercontent.com/TT1nKer/remoteShell/cn/setup-ssh-server.sh | bash
```

**Windows (以管理员身份运行 PowerShell):**
```powershell
irm https://raw.githubusercontent.com/TT1nKer/remoteShell/cn/setup-ssh-windows-safe.ps1 | iex
```

**Tailscale (Linux/Mac):**
```bash
curl -fsSL https://raw.githubusercontent.com/TT1nKer/remoteShell/cn/setup-tailscale-ssh.sh | bash
```

---

## 关键要点

✅ 必须在目标电脑安装SSH服务端
✅ Tailscale不需要配置路由器
✅ 传统SSH需要公网IP + 端口转发
✅ 全部方案免费

---

## 语言版本

- **中文版 (当前分支):** `cn` 分支
- **English Version:** `main` 分支

切换到英文版：
```bash
git checkout main
```

或访问：https://github.com/TT1nKer/remoteShell/tree/main
