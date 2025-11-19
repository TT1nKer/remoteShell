# Remote SSH Setup

## Fastest Solution (5 minutes)

### Tailscale + SSH

1. Download Tailscale: https://tailscale.com/download
2. Login (use Google/GitHub account)
3. Enable SSH:

**Windows (10 1809+/11):**
```
Settings → Apps → Optional Features → OpenSSH Server → Install
services.msc → OpenSSH SSH Server → Start
```

**Windows (PowerShell if not found):**
```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
```

**Mac:**
```bash
# Via GUI (Recommended): System Settings → Sharing → Remote Login ON
# Or via Terminal:
sudo systemsetup -setremotelogin on
```
*Note: Terminal method requires Full Disk Access permission*

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

### Documentation
- `START_HERE.md` - Quick start guide ⭐ **Start here!**
- `ANTIVIRUS_SOLUTION.md` - How to handle antivirus blocking

### Scripts
- `setup-ssh-server.sh` - Mac/Linux automated setup
- `setup-ssh-windows-safe.ps1` - Windows safe setup  
- `setup-tailscale-ssh.sh` - Tailscale automated setup

### One-Line Install Commands

**Linux/Mac:**
```bash
curl -fsSL https://raw.githubusercontent.com/TT1nKer/remoteShell/main/setup-ssh-server.sh | bash
```

**Windows (PowerShell as Admin):**
```powershell
irm https://raw.githubusercontent.com/TT1nKer/remoteShell/main/setup-ssh-windows-safe.ps1 | iex
```

**Tailscale (Linux/Mac):**
```bash
curl -fsSL https://raw.githubusercontent.com/TT1nKer/remoteShell/main/setup-tailscale-ssh.sh | bash
```

---

## Key Points

✅ Must install SSH server on target computer
✅ Tailscale doesn't require router configuration
✅ Traditional SSH needs public IP + port forwarding
✅ All solutions are free

---

## Language Versions

- **English (Current):** `main` branch
- **中文版本 (Chinese):** `cn` branch

Switch to Chinese version:
```bash
git checkout cn
```

Or visit: https://github.com/TT1nKer/remoteShell/tree/cn

