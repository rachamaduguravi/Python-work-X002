# Python-work-X002

Multi-laptop development environment configured for **WSL2 (Ubuntu)** and synchronized via **GitHub**.

- **GitHub Repository**: [https://github.com/rachamaduguravi/Python-work-X002](https://github.com/rachamaduguravi/Python-work-X002)
- **SSH URL**: `git@github.com:rachamaduguravi/Python-work-X002.git`

---

## 🚀 Quick Setup on a New Laptop / WSL2 Instance

### 1. Configure SSH Authentication (One-time per laptop)
Inside WSL2:
```bash
# Generate ed25519 SSH key
ssh-keygen -t ed25519 -C "rachamaduguravi" -f ~/.ssh/id_ed25519 -N ""

# Print public key to add to GitHub (Settings -> SSH and GPG keys)
cat ~/.ssh/id_ed25519.pub

# Test connection
ssh -T git@github.com
```

### 2. Clone to Native WSL2 Filesystem (Fast I/O)
```bash
mkdir -p ~/projects && cd ~/projects
git clone git@github.com:rachamaduguravi/Python-work-X002.git
cd Python-work-X002
```

### 3. Bootstrap Virtual Environment
```bash
chmod +x setup_env.sh
./setup_env.sh
```

### 4. Launch in VS Code
```bash
code .
```

---

## 🔄 Daily Sync Workflow Between Laptops

| Workflow | Command (Laptop 1 - Finish) | Command (Laptop 2 - Resume) |
|---|---|---|
| **Push / Pull Code** | `git add . && git commit -m "feat: updates" && git push` | `git pull --rebase` |
| **New Package** | `pip install <pkg> && pip freeze > requirements.txt` | `git pull && pip install -r requirements.txt` |
