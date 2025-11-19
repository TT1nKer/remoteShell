# 🚀 远程控制家里电脑 - 快速指南

## 核心问题：必须在家里电脑安装SSH服务端

**⚠️ 重要：** 只有密钥无法远程控制。必须先在家里电脑安装服务端。

---

## 推荐方案：Tailscale（最简单）

### 优势
- 不需要配置路由器
- 不需要公网IP
- 不会被杀毒软件拦截（官方签名）
- 完全免费

### 5分钟完成

**在家里电脑执行一次：**

1. 下载 Tailscale：https://tailscale.com/download
2. 安装（一路下一步）
3. 用 Google/GitHub 账号登录
4. 启用SSH服务：

**Windows（需要 Windows 10 1809+ 或 Windows 11）:**
```
设置 → 应用 → 可选功能 → OpenSSH Server → 安装
Win+R → services.msc → OpenSSH SSH Server → 启动 → 自动
```

**如果找不到 OpenSSH Server，用 PowerShell（以管理员运行）:**
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
```

**Mac（最简单 - 通过图形界面）:**
```
系统设置 → 通用 → 共享 → 开启"远程登录"
```

**Mac（备选 - 通过终端）:**
```bash
sudo systemsetup -setremotelogin on
```
*注意：需要终端有完全磁盘访问权限。如果报错，用上面的图形界面方法。*

**Linux:**
```bash
sudo apt install openssh-server
sudo systemctl enable ssh --now
```

5. 获取IP：`tailscale ip -4`

**从任何地方连接：**
```bash
ssh 用户名@100.x.x.x
```

---

## 备选方案：手动安装SSH（免费但需配置路由器）

**Windows（方法1 - 通过设置）:**
1. Win+I → 应用 → 可选功能 → OpenSSH Server → 安装
2. Win+R → services.msc → OpenSSH SSH Server → 启动 → 自动
3. 配置路由器端口转发（端口22 → 你的电脑IP）

**Windows（方法2 - 如果找不到，用 PowerShell 管理员）:**
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType 'Automatic'
```

**Mac/Linux：**
- 见上面命令

**连接：**
```bash
ssh 用户名@你的公网IP
```

---

## 如果被杀毒软件拦截

### 方案1：用图形界面（推荐）
双击打开 `ssh-setup-gui.html`，跟随界面操作

### 方案2：添加白名单
- Windows Defender: 设置 → 病毒防护 → 排除项 → 添加文件
- 360: 木马防火墙 → 信任区
- 火绒: 设置 → 信任区

---

## 文件说明

| 文件 | 用途 |
|------|------|
| `ssh-setup-gui.html` | 图形界面教程（打开看） |
| `setup-ssh-windows-safe.ps1` | Windows自动安装脚本 |
| `setup-ssh-server.sh` | Linux/Mac自动安装脚本 |

其他文件是详细文档，需要时查看。

---

## 常见问题

**Q: 能完全不碰家里电脑吗？**
A: 不能。必须至少操作一次安装服务端。

**Q: 没有公网IP怎么办？**
A: 用Tailscale方案。

**Q: 要花钱吗？**
A: 不要。全部免费。

**Q: 安全吗？**
A: Tailscale端到端加密。传统SSH用强密码或密钥。

---

**立即开始：**双击 `ssh-setup-gui.html` 查看详细步骤


