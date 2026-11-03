# 🐱 macOS 多 GitHub 账号与项目目录自动化管理助手

<p align="center">
  <b>简体中文</b> | <a href="./README_EN.md">English</a>
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

> **一劳永逸、彻底自动化**：在 Mac 本地轻松管理多个 GitHub 账号（公司工作、个人开源、外包客户等）。只要进入对应文件夹，Git 会自动无感切换专属用户名、邮箱与 SSH 私钥，克隆与推送**无需修改任何 GitHub 仓库 URL**！

---

## 💥 传统多账号管理的 4 大痛点

如果你在一台电脑上同时拥有工作、个人、开源或不同客户的 GitHub 账号，你很可能受过以下折磨：

1. **身份串线与隐私事故**：
   - 不小心用公司企业邮箱向个人开源仓库提交了代码，或者把个人邮箱留在了公司商业项目的 commit 历史里，造成隐私泄露和合规风险。
2. **反人类的 Host 别名改写**：
   - 传统网上教程总让你在 `~/.ssh/config` 配置伪域名（如 `Host github-work`）。导致你在 GitHub 网页上一键复制的 `git clone git@github.com:...` 永远无法直接使用，必须每次手动改写成 `git@github-work:...`。一旦忘记改写，就会用错密钥导致权限报错，极其违背开发直觉。
3. **SSH 认证被拒 (`Too many authentication failures`)**：
   - macOS 自带的 SSH Agent 在连接 GitHub 时，默认会遍历并逐个尝试本地所有的私钥，密钥一旦多于 3 个，就会直接触发 GitHub 防暴力探测机制而被拒绝连接。
4. **官方工具“多账号残疾”**：
   - 官方 **GitHub Desktop** 客户端根本不支持同时登录多个账号，每次切换必须退出登录重新扫码，体验极其痛苦；而商业 Git GUI 学习成本高且无法无缝覆盖终端与 VS Code / Cursor。

---

## 🥊 为什么选择本脚本？方案全方位对比

本脚本基于 Git 官方原生的 **`includeIf`（条件目录加载）+ `core.sshCommand`（指定私钥隔离）** 机制构建，对比传统方案具有压倒性优势：

| 对比维度 | 传统 SSH Host 别名方案 | 官方 GitHub Desktop | 每个仓库手动配置 | 🌟 本脚本方案 |
| :--- | :---: | :---: | :---: | :---: |
| **官方仓库 URL 直连**<br>*(无需改写 git@github.com)* | ❌ 必须手动改写为别名 | ❌ 仅支持登录态账号 | ✔ 原版地址可用 | **✔ 100% 官方原版直连，零改动** |
| **全编辑器与终端通用**<br>*(VS Code / Cursor / 终端)* | ⚠️ 取决于别名配置 | ❌ 仅限其图形客户端内 | ✔ 通用 | **✔ 全局所有 IDE、终端、GUI 完全通用** |
| **自动化程度** | ❌ 每次克隆都要人肉修改 | ❌ 频繁登出与登入 | ❌ 每个新项目都要配一遍 | **✔ 彻底自动化：进入文件夹即刻生效** |
| **配置与维护成本** | 🔴 繁琐易错（需手写多文件） | 🟡 较低但功能受限 | 🔴 极高（每次新项目都需配） | **🟢 极低：运行向导 30 秒全自动完成** |
| **账号扩容体验** | 🟡 手动追加易破坏现有格式 | ❌ 不支持同时多账号 | 🔴 重复机械劳动 | **🟢 极佳：随时执行追加，防重防覆盖** |

---

## ✨ 核心优势与特性

- 🐾 **真正无感切换**：进入 `~/Projects/work/` 自动是工作身份；进入 `~/Projects/personal/` 自动是个人身份。
- 🔍 **启动状态自检**：每次运行脚本，首先自动扫描并以结构化卡片列出所有已绑定的账号、目录、私钥存在状态与提交昵称。
- 🛡️ **安全防呆防覆盖**：若代号、密钥、目录或配置已存在，友好询问是否覆盖，绝不误删重要私钥。
- 📋 **自动剪贴板集成**：密钥生成后自动通过 `pbcopy` 拷贝公钥内容，并可一键调起浏览器直达 GitHub 密钥添加页。
- 🤝 **在线握手测试**：配置完成后现场向 GitHub 发起连接认证，自动抓取并确认你登录的 GitHub 用户名（`Hi @username!`）。
- 💡 **内置排错诊断**：网络超时、公钥未添加、绿墙不亮等常见问题自带智能诊断与一键解决命令。

---

## 🎨 3 步极简使用流程

<p align="center">
  <img src="./assets/workflow_guide_zh.jpg" alt="3-Step Developer Workflow (Chinese)" width="760" style="border-radius: 12px; box-shadow: 0 4px 16px rgba(0,0,0,0.08);" />
</p>

整个配置只需三步，耗时不到 1 分钟：

| 步骤 | 操作 | 详细说明 |
|:---:|:---|:---|
| **步骤一** | **运行终端向导** | 终端输入 `./setup_git_account.sh`，按引导输入代号、作者名、邮箱和目录 |
| **步骤二** | **添加 GitHub 密钥** | 脚本自动复制公钥并调起网页，按 `Cmd + V` 粘贴公钥并保存 |
| **步骤三** | **目录无感分流** | 对应文件夹下的所有项目自动关联该账号，正常 `git clone` 和 `git commit` |

---

## 🚀 快速上手与操作向导

### 1. 赋予执行权限并运行
在包含该脚本的文件夹内打开终端：

```bash
# 赋予执行权限（仅需执行一次）
chmod +x *.sh

# 运行中文配置向导（可直接运行中文版，或运行主脚本选择语言）
./setup_git_account_zh.sh
# 或者运行主脚本：./setup_git_account.sh
```

### 2. 交互配置演示
启动后，脚本会先检查现有账号，随后引导你进行配置：

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

### 3. 公钥添加与握手自测
配置生成后，脚本会自动复制公钥到剪贴板，并询问：
```text
是否现在直接在默认浏览器中打开该 GitHub 添加密钥页面？(Y/n, 默认 Y): Y
```
1. 浏览器打开后，在 **Title** 栏填入标记（如 `MacMini-Work`），在 **Key** 栏按 `Cmd + V` 粘贴公钥并保存。
2. 回到终端按回车，脚本现场向 GitHub 发起安全握手测试：
```text
🎉 连通测试成功！GitHub 已正确识别你的身份！
   识别出的 GitHub 账号为: @AlexZhangDev
   该账号与目录 [~/Projects/work] 已经完美绑定生效！
```

---

## 💻 日常开发速查手册 (Cheatsheet)

### 1. 如何开始一个新项目？
进入该账号绑定的项目文件夹，**直接使用 GitHub 官方原本的 SSH 地址**：
```bash
cd ~/Projects/work
git clone git@github.com:your-company/your-project.git
```

### 2. 如何验证当前仓库的身份？
在任何 Git 仓库中打开终端：
```bash
# 验证提交昵称
git config user.name

# 验证提交邮箱
git config user.email

# 验证生效的专属私钥
git config core.sshCommand
```

### 3. 以后想再添加第 3、4、5 个账号？
只需再次运行向导脚本：
```bash
./setup_git_account.sh
```
输入新的代号（例如 `client_b`）与对应文件夹（例如 `~/Projects/client_b`），脚本会自动追加，**绝不影响现有任何账号**。

### 4. 💡 进阶建议：将脚本升级为系统全局命令
如果你希望在电脑任意目录的终端中都能随时调用该工具，可以执行：
```bash
sudo cp setup_git_account.sh /usr/local/bin/git-account
```
此后在任意终端输入 `git-account` 即可启动管理！

---

## 🛠️ 常见问题排查与解决 (FAQ)

<details>
<summary><b>Q1: 为什么提交了代码，GitHub 个人主页没有点亮“绿色小方格（绿墙）”？</b></summary>

- **原因**：GitHub 判定贡献是根据提交记录中的 `email` 来匹配账号的。如果本地提交的邮箱没有登记在该 GitHub 账号中，就不会计入贡献。
- **解决办法**：
  1. 登录该账号的 GitHub 网页端；
  2. 进入 **Settings** -> **Emails**；
  3. 将你配置在此账号的邮箱地址添加到列表中并验证即可。
</details>

<details>
<summary><b>Q2: 为什么已有旧项目移动到该文件夹后，作者名没有自动变过来？</b></summary>

- **原因**：如果旧项目在过去单独运行过 `git config user.email "..."`，仓库内部 `.git/config` 的局部优先级高于父级目录规则。
- **解决办法**：
  在项目根目录下运行清除命令，使父级配置重新生效：
  ```bash
  git config --local --unset user.name
  git config --local --unset user.email
  ```
</details>

<details>
<summary><b>Q3: 为什么 push 代码时突然弹出提示要求输入密码或 Personal Access Token？</b></summary>

- **原因**：当前仓库使用的是 `https://github.com/...` 地址，HTTPS 协议不会走 SSH 密钥通道。
- **解决办法**：
  运行命令一键切换为 SSH 地址：
  ```bash
  git remote set-url origin git@github.com:用户名/仓库名.git
  ```
</details>

<details>
<summary><b>Q4: 连通测试提示 `Permission denied (publickey)` 怎么办？</b></summary>

- **自查清单**：
  1. 检查是否在 GitHub 点击了保存按钮；
  2. 检查浏览器中当前登录的 GitHub 账号是否为对应账号（容易误粘贴到另一个账号上）；
  3. 重新提取公钥粘贴：`pbcopy < ~/.ssh/id_ed25519_你的代号.pub`。
</details>

---

## 📂 底层架构与目录树原理

本工具生成的配置在本地完全遵循解耦设计，各层级一目了然：

```text
~ (用户主目录)
├── .gitconfig                 # 全局总管：根据当前所在文件夹，动态 include 对应子配置
│     ├── [includeIf "gitdir:~/Projects/personal/"] -> ~/.gitconfig-personal
│     └── [includeIf "gitdir:~/Projects/work/"]     -> ~/.gitconfig-work
│
├── .gitconfig-personal        # 个人配置：user.name / user.email / 绑定 personal 密钥
├── .gitconfig-work            # 工作配置：user.name / user.email / 绑定 work 密钥
│
├── .ssh/
│     ├── id_ed25519_personal  # 个人账号独立私钥 (安全权限 600)
│     ├── id_ed25519_personal.pub
│     ├── id_ed25519_work      # 工作账号独立私钥 (安全权限 600)
│     └── id_ed25519_work.pub
│
└── Projects/                  # 你的本地开发根目录
      ├── personal/            # 📁 进入此目录 -> 自动加载 ~/.gitconfig-personal
      │     └── my-blog
      └── work/                # 📁 进入此目录 -> 自动加载 ~/.gitconfig-work
            └── company-api
```

---

## 📄 开源许可证

本项目遵循 [MIT License](LICENSE) 开源。欢迎自由使用、修改与分享！
