# 🏠 家庭电脑SSH远程访问 - 静默安装指南

## 📋 快速开始

### 方案一：最简单的方法（推荐新手）

**只需要在家里电脑上执行一次命令：**

#### macOS/Linux:
```bash
curl -fsSL https://raw.githubusercontent.com/你的用户名/你的仓库/main/setup-ssh-server.sh | sudo bash
```

或者下载后运行：
```bash
chmod +x setup-ssh-server.sh
sudo ./setup-ssh-server.sh
```

#### Windows:
以管理员身份打开 PowerShell，执行：
```powershell
irm https://raw.githubusercontent.com/你的用户名/你的仓库/main/setup-ssh-server.ps1 | iex
```

或者下载后运行：
```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\setup-ssh-server.ps1
```

---

## 🎯 三步完整方案

### 第一步：在家里电脑上运行脚本（5分钟）

1. 将 `setup-ssh-server.sh` (Mac/Linux) 或 `setup-ssh-server.ps1` (Windows) 通过以下任一方式传到家里电脑：
   - U盘拷贝
   - 发邮件给自己
   - 通过微信/QQ文件传输
   - 上传到网盘下载

2. 运行脚本（需要管理员权限）

3. **记下显示的IP地址**（重要！）

### 第二步：配置路由器（10分钟）

这是**唯一需要手动操作**的部分，因为每个路由器界面不同：

1. 浏览器打开路由器管理页面（通常是 `192.168.1.1` 或 `192.168.0.1`）
2. 找到"端口转发"/"虚拟服务器"/"NAT设置"
3. 添加规则：
   - 外部端口：`22` (或自定义如 `2222`)
   - 内部IP：`192.168.x.x` (脚本显示的本地IP)
   - 内部端口：`22`
   - 协议：`TCP`

**路由器配置示例图：**
```
┌──────────────────────────────────┐
│ 端口转发规则                     │
├──────────────────────────────────┤
│ 外部端口: 22                     │
│ 内部IP:   192.168.1.100          │
│ 内部端口: 22                     │
│ 协议:     TCP                    │
│ 启用:     ✓                      │
└──────────────────────────────────┘
```

### 第三步：测试连接（2分钟）

从外面网络测试：
```bash
ssh 你的用户名@你家的公网IP
```

首次连接会要求输入密码，成功后可以添加SSH密钥实现免密登录。

---

## 🚀 更"静默"的替代方案

如果你觉得路由器配置太麻烦，可以使用这些方案，**完全不需要配置路由器**：

### 方案A：Tailscale（最推荐）

**优点：** 零配置、安全、免费、支持所有平台

1. 在家里电脑安装 Tailscale：
   ```bash
   # macOS
   brew install tailscale
   
   # Linux
   curl -fsSL https://tailscale.com/install.sh | sh
   
   # Windows: 下载安装包
   ```

2. 登录你的 Tailscale 账号

3. 在远程电脑也安装 Tailscale 并登录

4. 使用 Tailscale 分配的内网IP连接，例如：
   ```bash
   ssh 用户名@100.x.x.x
   ```

**完整自动化脚本：**
```bash
# 在家里电脑运行一次
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up
echo "SSH已准备就绪，Tailscale IP: $(tailscale ip -4)"
```

### 方案B：frp 内网穿透

**优点：** 通过中转服务器，不需要公网IP

1. 需要一台有公网IP的中转服务器（VPS）
2. 在家里电脑运行 frp 客户端
3. 自动建立连接

### 方案C：ngrok

**优点：** 最简单，一条命令搞定

```bash
# 安装 ngrok
brew install ngrok  # macOS
# 或从 https://ngrok.com 下载

# 注册账号获取 token
ngrok authtoken YOUR_TOKEN

# 启动（会自动后台运行）
ngrok tcp 22
```

会显示类似：`tcp://0.tcp.ngrok.io:12345` 的地址，然后可以：
```bash
ssh 用户名@0.tcp.ngrok.io -p 12345
```

---

## 🔒 安全建议

脚本已经配置了基本安全设置，但建议：

1. **修改默认端口**（避免被扫描）
2. **只用密钥认证，禁用密码**
3. **使用 fail2ban** 防止暴力破解
4. **定期更新系统**

---

## ❓ 常见问题

### Q: 我的路由器没有公网IP怎么办？
A: 使用 Tailscale、ngrok 等方案，不需要公网IP。

### Q: 脚本运行后还是连不上？
A: 检查：
1. 家里电脑防火墙是否开放22端口
2. 路由器端口转发是否正确
3. 公网IP是否正确（可能是运营商的大内网）

### Q: 如何知道家里电脑的公网IP？
A: 脚本会自动显示，或访问 http://ip.sb

### Q: 家里电脑关机了能远程开机吗？
A: 需要额外配置 Wake-on-LAN (WOL)，但这超出了SSH的范围。

### Q: 手机可以SSH连接吗？
A: 可以！使用 Termius (iOS/Android) 等SSH客户端。

---

## 📱 完整工作流示例

**场景：** 你现在在公司，想访问家里的 Mac

1. **昨晚你在家里做的准备（5分钟）：**
   ```bash
   curl -fsSL https://example.com/setup.sh | sudo bash
   # 配置了路由器端口转发
   # 记下了公网IP: 123.45.67.89
   ```

2. **现在在公司连接：**
   ```bash
   ssh yourname@123.45.67.89
   # 输入密码
   # 成功！
   ```

3. **设置免密登录（可选）：**
   ```bash
   # 在公司电脑生成密钥
   ssh-keygen -t ed25519
   
   # 复制公钥到家里电脑
   ssh-copy-id yourname@123.45.67.89
   
   # 以后直接连接，不需要密码
   ssh yourname@123.45.67.89
   ```

---

## 🎁 附赠脚本

### 自动重连脚本

创建 `auto-ssh.sh` 放在你常用的电脑上：
```bash
#!/bin/bash
# 自动重连家里电脑

HOME_IP="123.45.67.89"  # 改成你家的IP
HOME_USER="yourname"     # 改成你的用户名

while true; do
    ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 $HOME_USER@$HOME_IP
    echo "连接断开，5秒后重试..."
    sleep 5
done
```

### 检查SSH服务脚本

放在家里电脑，开机自动运行：
```bash
#!/bin/bash
# 确保SSH服务始终运行

if ! systemctl is-active --quiet sshd; then
    systemctl start sshd
    echo "SSH服务已重启: $(date)" >> /var/log/ssh-monitor.log
fi
```

---

## 💡 总结

**最少操作方案：**
1. 在家里电脑运行一次脚本 ✓
2. 使用 Tailscale（不需要配置路由器）✓

**最安全方案：**
1. 运行脚本 + 配置路由器
2. 使用密钥认证
3. 修改默认端口

**需要帮助？** 在GitHub开issue或查看详细文档。


