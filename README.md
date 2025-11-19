# 远程SSH配置

## 最快方案（5分钟）

### Tailscale + SSH

1. 下载安装 Tailscale: https://tailscale.com/download
2. 登录（用 Google/GitHub 账号）
3. 启用SSH:

**Windows:**
```
设置 → 应用 → OpenSSH Server → 安装
services.msc → OpenSSH SSH Server → 启动
```

**Mac:**
```bash
sudo systemsetup -setremotelogin on
```

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

## 文件

- `ssh-setup-gui.html` - 图形界面教程
- `START_HERE_开始阅读.md` - 简要说明
- `setup-*.sh/ps1` - 自动化脚本

---

## 关键要点

✅ 必须在目标电脑安装SSH服务端
✅ Tailscale不需要配置路由器
✅ 传统SSH需要公网IP + 端口转发
✅ 全部方案免费

