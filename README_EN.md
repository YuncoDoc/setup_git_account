# 🐱 macOS Git Multi-Account & Directory Automation Manager

<p align="center">
  <a href="./README.md">简体中文</a> | <b>English</b>
</p>

<p align="center">
  <img src="./assets/banner.jpg" alt="Git Multi Account Manager Banner" width="800" style="border-radius: 12px; box-shadow: 0 4px 20px rgba(0,0,0,0.1);" />
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS-black?style=flat-square&logo=apple" alt="macOS" />
  <img src="https://img.shields.io/badge/Shell-Bash%20%7C%20Zsh-blue?style=flat-square&logo=gnu-bash" alt="Shell" />
  <img src="https://img.shields.io/badge/Git-includeIf-orange?style=flat-square&logo=git" alt="Git" />
  <img src="https://img.shields.io/badge/Language-Bilingual-brightgreen?style=flat-square" alt="Bilingual" />
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License" />
</p>

> **Set It Once, Automate Forever**: Seamlessly manage multiple GitHub accounts (Work, Personal, Open Source, Clients) on your Mac. Simply navigate into the target folder, and Git will automatically apply the matching author name, email, and SSH key. Clone and push **without modifying any official repository URLs**!

---

## 💥 4 Pain Points in Traditional Multi-Account Git Management

If you manage more than one GitHub account on a single machine, you've likely encountered these common headaches:

1. **Identity Leaks & Cross-Contamination**:
   - Accidentally committing to an open-source project with your corporate email, or leaving your personal email inside proprietary company codebase history—creating compliance risks and privacy leaks.
2. **Frustrating SSH Host Aliases**:
   - Traditional tutorials instruct you to set up fake hostnames in `~/.ssh/config` (like `Host github-work`). Consequently, you can never directly use the one-click `git clone git@github.com:...` URL copied from GitHub. Instead, you must manually rewrite it to `git@github-work:...` every single time. Forgetting to do so results in permission errors.
3. **`Too many authentication failures` Rejection**:
   - By default, the macOS SSH Agent attempts to offer every key in its keyring sequentially. Once you accumulate 3 or more keys, GitHub triggers its brute-force protection mechanism and drops your connection.
4. **Official Tools' Multi-Account Limitations**:
   - The official **GitHub Desktop** client does not support being logged into multiple accounts simultaneously. Switching accounts requires signing out and authenticating with 2FA all over again. Commercial Git GUIs also fail to integrate cleanly with your CLI and IDE workflows (VS Code, Cursor, terminal).

---

## 🥊 Why Choose This Script? Comprehensive Comparison

Built upon Git's native **`includeIf` (conditional directory inclusion) + `core.sshCommand` (isolated identity enforcement)**, this solution offers substantial advantages over conventional methods:

| Feature / Metric | Traditional SSH Host Aliases | Official GitHub Desktop | Manual Per-Repo Config | 🌟 This Script Solution |
| :--- | :---: | :---: | :---: | :---: |
| **Official Repo URLs**<br>*(No `git@github.com` rewrite)* | ❌ Must rewrite to alias | ❌ Logged-in account only | ✔ Works with official URLs | **✔ 100% Native URLs, Zero Rewrites** |
| **Universal IDE & CLI Support**<br>*(VS Code / Cursor / Terminal)* | ⚠️ Depends on alias handling | ❌ Confined to Desktop GUI | ✔ Universal | **✔ Works across all IDEs, terminals & GUIs** |
| **Level of Automation** | ❌ Manual rewrite every clone | ❌ Constant log in / log out | ❌ Must configure every new repo | **✔ 100% Automated upon folder entry** |
| **Maintenance Overhead** | 🔴 Complex, multi-file edits | 🟡 Limited functionality | 🔴 High (repetitive manual labor) | **🟢 Zero: 30s interactive wizard setup** |
| **Account Scalability** | 🟡 Error-prone manual additions | ❌ No multi-account support | 🔴 Repetitive toil | **🟢 Effortless: Duplicate-safe wizard** |

---

## ✨ Key Advantages & Features

- 🐾 **True Zero-Friction Switching**: `cd ~/Projects/work/` automatically uses your work identity; `cd ~/Projects/personal/` automatically uses your personal profile.
- 🔍 **Pre-Flight Health Inspection**: Automatically detects and displays all existing account profiles, folder bindings, and SSH key states upon launch.
- 🛡️ **Duplicate & Overwrite Protection**: Intelligently warns if an account tag, key, or path already exists and asks for confirmation before updating.
- 📋 **Automated Clipboard Integration**: Uses `pbcopy` to place your public key onto the clipboard immediately and offers to launch your browser directly to GitHub's key settings.
- 🤝 **Live Connection Handshake**: Automatically runs an SSH handshake with GitHub to verify the key and reports your authenticated username (`Hi @username!`).
- 💡 **Built-In Troubleshooting Guide**: Interactive diagnostics identify whether errors stem from network timeouts, missing keys, or misconfigured emails.

---

## 🎨 3-Step Workflow

<p align="center">
  <img src="./assets/workflow_guide_en.jpg" alt="3-Step Developer Workflow (English)" width="760" style="border-radius: 12px; box-shadow: 0 4px 16px rgba(0,0,0,0.08);" />
</p>

Setup takes less than 1 minute:

| Step | Action | Description |
|:---:|:---|:---|
| **Step 1** | **Run Terminal Wizard** | Run `./setup_git_account.sh` and enter your tag, name, email, and folder |
| **Step 2** | **Add Key to GitHub** | Browser opens to GitHub's key settings; paste with `Cmd + V` and save |
| **Step 3** | **Work Seamlessly** | Every repository inside that folder automatically assumes that identity |

---

## 🚀 Quick Start Guide

### 1. Grant Execution Permission & Run
Open your terminal in the directory containing the script:

```bash
# Grant execution permission (only needed once)
chmod +x *.sh

# Run the English configuration wizard directly
./setup_git_account_en.sh
# Or run the master router: ./setup_git_account.sh --en
```

### 2. Interactive Wizard Walkthrough
The script inspects any existing accounts and guides you through 4 simple prompts:

```text
======================================================================
     macOS 多 GitHub 账号与项目目录自动化配置工具 (Enhanced)          
======================================================================

🔍 正在检查当前系统已绑定的 Git 多账号与目录...
ℹ️  当前系统暂未检测到任何通过 includeIf 绑定的 Git 多账号。

👉 按 【回车键】 继续配置新账号/更新现有账号 (或输入 q 退出): 

【步骤 1/4】设定账号本地代号 (TAG)
👉 请输入账号代号: work

【步骤 2/4】设定 Git 提交作者名 (user.name)
👉 请输入 Git 作者名: Alex Zhang

【步骤 3/4】设定 Git 提交邮箱 (user.email)
👉 请输入 Git 提交邮箱: alex@company.com

【步骤 4/4】指定该账号绑定的项目文件夹
👉 请输入项目文件夹路径 [默认: ~/Projects/work]: 
```

### 3. Key Paste & Live Handshake Test
Once the key is generated, the script copies the public key to your clipboard and asks:
```text
是否现在直接在默认浏览器中打开该 GitHub 添加密钥页面？(Y/n, 默认 Y): Y
```
1. In your browser, enter a Title (e.g., `MacMini-Work`), paste the key with `Cmd + V`, and click **Add SSH key**.
2. Return to the terminal and press Enter. The script tests the connection:
```text
🎉 连通测试成功！GitHub 已正确识别你的身份！
   识别出的 GitHub 账号为: @AlexZhangDev
   该账号与目录 [~/Projects/work] 已经完美绑定生效！
```

---

## 💻 Developer Cheatsheet

### 1. How to start a new project?
Navigate into the configured folder and clone using the **standard, unmodified GitHub SSH address**:
```bash
cd ~/Projects/work
git clone git@github.com:your-company/your-project.git
```

### 2. How to verify which identity is currently active?
Inside any Git repository on your machine:
```bash
# Verify active author name
git config user.name

# Verify active author email
git config user.email

# Verify active SSH key command
git config core.sshCommand
```

### 3. How to add another account later?
Simply run the script again:
```bash
./setup_git_account.sh
```
Provide the new tag (e.g., `client_b`) and folder path (`~/Projects/client_b`). The script appends the new account safely **without impacting existing configurations**.

### 4. 💡 Pro-Tip: Make it a Global System Command
To run this utility from any directory on your Mac, copy it to your system PATH:
```bash
sudo cp setup_git_account.sh /usr/local/bin/git-account
```
Now, you can simply type `git-account` anywhere in your terminal!

---

## 🛠️ Troubleshooting & FAQ

<details>
<summary><b>Q1: Why aren't my commits showing up on my GitHub contribution graph (Green Wall)?</b></summary>

- **Cause**: GitHub attributes contributions strictly based on the commit's `email`. If the commit email is not registered under that GitHub account, contributions will not appear.
- **Solution**:
  1. Log into your GitHub account in a browser;
  2. Navigate to **Settings** -> **Emails**;
  3. Add the email address configured for this account and verify it.
</details>

<details>
<summary><b>Q2: Why is an existing repository still using my old author name after being moved?</b></summary>

- **Cause**: If that repository previously had `git config user.email "..."` set locally, the repository's `.git/config` overrides the parent directory's `includeIf`.
- **Solution**:
  Inside that specific repository, run:
  ```bash
  git config --local --unset user.name
  git config --local --unset user.email
  ```
</details>

<details>
<summary><b>Q3: Why am I prompted for a password or Personal Access Token when pushing?</b></summary>

- **Cause**: The repository was cloned using an `https://github.com/...` URL instead of SSH.
- **Solution**:
  Convert the remote URL to SSH:
  ```bash
  git remote set-url origin git@github.com:username/repository.git
  ```
</details>

<details>
<summary><b>Q4: What if the handshake test shows `Permission denied (publickey)`?</b></summary>

- **Checklist**:
  1. Confirm that you clicked **Add SSH key** in GitHub;
  2. Check whether your browser is logged into the intended GitHub account (it's easy to paste keys into the wrong account);
  3. Re-copy the public key: `pbcopy < ~/.ssh/id_ed25519_yourtag.pub` and re-add it.
</details>

---

## 📂 Architecture & Directory Tree

All configuration files remain completely decoupled and structured:

```text
~ (User Home)
├── .gitconfig                 # Global master: Dynamically includes child configs by directory
│     ├── [includeIf "gitdir:~/Projects/personal/"] -> ~/.gitconfig-personal
│     └── [includeIf "gitdir:~/Projects/work/"]     -> ~/.gitconfig-work
│
├── .gitconfig-personal        # Personal config: user.name / email / personal SSH key
├── .gitconfig-work            # Work config: user.name / email / work SSH key
│
├── .ssh/
│     ├── id_ed25519_personal  # Isolated personal private key (chmod 600)
│     ├── id_ed25519_personal.pub
│     ├── id_ed25519_work      # Isolated work private key (chmod 600)
│     └── id_ed25519_work.pub
│
└── Projects/                  # Local workspace root
      ├── personal/            # 📁 Enter here -> Automatically activates ~/.gitconfig-personal
      │     └── my-blog
      └── work/                # 📁 Enter here -> Automatically activates ~/.gitconfig-work
            └── company-api
```

---

## 📄 License

This project is licensed under the [MIT License](LICENSE). Feel free to use, modify, and distribute!
