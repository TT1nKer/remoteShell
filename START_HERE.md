# 🚀 Remote PC Control - Quick Guide

## Core Requirement: Must Install SSH Server on Target PC

**⚠️ Important:** Having only a key won't work. You must first install the SSH server on your home computer.

---

## Recommended: Tailscale (Easiest)

### Benefits
- No router configuration needed
- No public IP required
- Won't be blocked by antivirus (officially signed)
- Completely free

### 5-Minute Setup

**On your home computer (one-time setup):**

1. Download Tailscale: https://tailscale.com/download
2. Install (click through the wizard)
3. Login with Google/GitHub account
4. Enable SSH service:

**Windows:**
```
Settings → Apps → Optional Features → OpenSSH Server → Install
Win+R → services.msc → OpenSSH SSH Server → Start → Automatic
```

**Mac:**
```bash
sudo systemsetup -setremotelogin on
```

**Linux:**
```bash
sudo apt install openssh-server
sudo systemctl enable ssh --now
```

5. Get IP: `tailscale ip -4`

**Connect from anywhere:**
```bash
ssh username@100.x.x.x
```

---

## Alternative: Manual SSH Setup (Free but requires router config)

**Windows:**
1. Win+I → Apps → Optional Features → OpenSSH Server → Install
2. Win+R → services.msc → OpenSSH SSH Server → Start → Automatic
3. Configure router port forwarding (port 22 → your PC IP)

**Mac/Linux:**
- See commands above

**Connect:**
```bash
ssh username@your_public_ip
```

---

## If Blocked by Antivirus

### Solution 1: Use GUI (Recommended)
Double-click `ssh-setup-gui.html`, follow the interface

### Solution 2: Add to Whitelist
- Windows Defender: Settings → Virus Protection → Exclusions → Add File
- 360: Firewall → Trust Zone
- Kaspersky: Settings → Trust Zone

---

## File Overview

| File | Purpose |
|------|---------|
| `ssh-setup-gui.html` | Interactive GUI tutorial (open this) |
| `setup-ssh-windows-safe.ps1` | Windows auto-install script |
| `setup-ssh-server.sh` | Linux/Mac auto-install script |

Other files are detailed documentation - read when needed.

---

## FAQ

**Q: Can I avoid touching my home PC entirely?**
A: No. You must perform at least one setup operation to install the server.

**Q: What if I don't have a public IP?**
A: Use the Tailscale solution.

**Q: Does it cost money?**
A: No. Everything is free.

**Q: Is it secure?**
A: Tailscale uses end-to-end encryption. Traditional SSH should use strong passwords or keys.

---

**Get Started:** Double-click `ssh-setup-gui.html` for detailed steps

