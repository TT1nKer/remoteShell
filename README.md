# Remote SSH Setup

## Fastest Solution (5 minutes)

### Tailscale + SSH

1. Download Tailscale: https://tailscale.com/download
2. Login (use Google/GitHub account)
3. Enable SSH:

**Windows:**
```
Settings → Apps → Optional Features → OpenSSH Server → Install
services.msc → OpenSSH SSH Server → Start
```

**Mac:**
```bash
sudo systemsetup -setremotelogin on
```

**Linux:**
```bash
sudo apt install openssh-server -y
```

4. Get IP: `tailscale ip -4`
5. Connect: `ssh username@100.x.x.x`

---

## Traditional SSH Solution

### Automated Scripts

**Windows:**
```powershell
# Run PowerShell as Administrator
.\setup-ssh-windows-safe.ps1
```

**Mac/Linux:**
```bash
sudo bash setup-ssh-server.sh
```

### Manual Installation

**Windows:**
Settings → Apps → OpenSSH Server → Install + Start Service

**Mac:**
`sudo systemsetup -setremotelogin on`

**Linux:**
`sudo apt install openssh-server`

Then configure router port forwarding (22 → your PC IP)

---

## Files

### English Documentation
- `START_HERE.md` - Quick start guide
- `ANTIVIRUS_SOLUTION.md` - How to handle antivirus blocking

### Scripts (English versions with -en suffix)
- `setup-ssh-server-en.sh` - Mac/Linux automated setup
- `setup-ssh-windows-safe-en.ps1` - Windows safe setup  
- `setup-tailscale-ssh-en.sh` - Tailscale automated setup

### Chinese Documentation (中文文档)
- `START_HERE_开始阅读.md` - 中文快速指南
- `解决杀毒软件拦截的完整方案.md` - 杀毒软件解决方案
- Original Chinese scripts: `setup-ssh-server.sh`, `setup-ssh-server.ps1`, etc.

---

## Key Points

✅ Must install SSH server on target computer
✅ Tailscale doesn't require router configuration
✅ Traditional SSH needs public IP + port forwarding
✅ All solutions are free

