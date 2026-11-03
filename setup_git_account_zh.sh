#!/usr/bin/env bash
# ==============================================================================
# 脚本名称: setup_git_account.sh
# 适用平台: macOS (Apple Silicon & Intel)
# 功能: 交互式管理/追加多 GitHub 账号，自动配置 SSH 密钥、目录绑定及自动化排错检测
# ==============================================================================

# 捕获 Ctrl+C 中断信号友好退出
trap 'echo -e "\n\n\033[0;33m[!] 用户取消操作，配置已终止，未完成的步骤不会生效。\033[0m\n"; exit 1' INT

# 颜色与排版定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# 辅助打印函数
print_title() {
    echo -e "\n${BOLD}${CYAN}======================================================================${NC}"
    echo -e "${BOLD}${CYAN}     macOS 多 GitHub 账号与项目目录自动化配置工具 (Enhanced)          ${NC}"
    echo -e "${BOLD}${CYAN}======================================================================${NC}\n"
    echo -e "${DIM}提示: 脚本执行过程中随时可按 Ctrl+C 安全退出。${NC}\n"
}

print_step() {
    local num="$1"
    local title="$2"
    echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"
    echo -e "${BOLD}${GREEN}【步骤 $num/4】$title${NC}"
    echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"
}

print_tip() {
    echo -e "${DIM}💡 提示说明: $1${NC}"
}

# 路径展开 (~ 转为绝对路径)
expand_path() {
    local p="$1"
    if [[ "$p" == ~* ]]; then
        echo "${p/#\~/$HOME}"
    else
        echo "$p"
    fi
}

# ------------------------------------------------------------------------------
# 检查并展示已配置的账号列表
# ------------------------------------------------------------------------------
check_and_display_existing_accounts() {
    local gitconfig_global="$HOME/.gitconfig"
    local found_count=0
    local cur_dir=""
    local cur_path=""
    
    echo -e "${BOLD}${CYAN}🔍 正在检查当前系统已绑定的 Git 多账号与目录...${NC}\n"
    
    if [[ -f "$gitconfig_global" ]]; then
        # 逐行扫描 ~/.gitconfig 中的 includeIf 规则
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" =~ \[includeIf[[:space:]]+\"gitdir:([^\"]+)\"\] ]]; then
                cur_dir="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]*path[[:space:]]*=[[:space:]]*(.+) ]]; then
                cur_path="${BASH_REMATCH[1]}"
                cur_path=$(expand_path "$cur_path")
                
                if [[ -n "$cur_dir" && -n "$cur_path" ]]; then
                    found_count=$((found_count + 1))
                    
                    # 提取代号 (从文件名 .gitconfig-<TAG> 提取，若不符合则显示自定义)
                    local tag_name="custom"
                    if [[ "$cur_path" =~ \.gitconfig-(.+) ]]; then
                        tag_name="${BASH_REMATCH[1]}"
                    fi
                    
                    # 读取子配置文件里的作者信息与密钥
                    local u_name="未设定"
                    local u_email="未设定"
                    local ssh_key="未检测到"
                    local key_status=""
                    local dir_status=""
                    
                    if [[ -f "$cur_path" ]]; then
                        u_name=$(git config --file "$cur_path" user.name 2>/dev/null || echo "未设定")
                        u_email=$(git config --file "$cur_path" user.email 2>/dev/null || echo "未设定")
                        local ssh_cmd
                        ssh_cmd=$(git config --file "$cur_path" core.sshCommand 2>/dev/null || echo "")
                        if [[ "$ssh_cmd" =~ -i[[:space:]]+([^[:space:]]+) ]]; then
                            ssh_key="${BASH_REMATCH[1]}"
                            local resolved_key
                            resolved_key=$(expand_path "$ssh_key")
                            if [[ -f "$resolved_key" ]]; then
                                key_status=" ${GREEN}(私钥正常 ✔)${NC}"
                            else
                                key_status=" ${RED}(私钥文件丢失 ⚠️)${NC}"
                            fi
                        fi
                    fi
                    
                    local resolved_dir
                    resolved_dir=$(expand_path "$cur_dir")
                    if [[ -d "$resolved_dir" ]]; then
                        dir_status="${GREEN}(目录已就绪 ✔)${NC}"
                    else
                        dir_status="${YELLOW}(目录尚未创建)${NC}"
                    fi
                    
                    echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"
                    echo -e "${BOLD} [${found_count}] 账号代号: ${GREEN}${tag_name}${NC}"
                    echo -e "     • 绑定目录:   ${BOLD}${cur_dir}${NC} ${dir_status}"
                    echo -e "     • 提交作者:   ${u_name} <${u_email}>"
                    echo -e "     • 对应私钥:   ${ssh_key}${key_status}"
                    echo -e "     • 配置文件:   ${cur_path}"
                    
                    cur_dir=""
                    cur_path=""
                fi
            fi
        done < "$gitconfig_global"
    fi
    
    if [[ $found_count -eq 0 ]]; then
        echo -e "${YELLOW}ℹ️  当前系统暂未检测到任何通过 includeIf 绑定的 Git 多账号。${NC}"
        echo -e "${DIM}   (首次运行此脚本将为你创建第一个账号配置)${NC}\n"
    else
        echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}✔ 共检测到 ${found_count} 个已配置的账号规则。${NC}\n"
    fi
}

# ------------------------------------------------------------------------------
# 主流程开始
# ------------------------------------------------------------------------------
print_title
check_and_display_existing_accounts

echo -e "👉 按 ${BOLD}【回车键】${NC} 继续配置新账号/更新现有账号 (或输入 ${BOLD}q${NC} 退出): "
read -r CONTINUE_CHOICE
if [[ "$CONTINUE_CHOICE" =~ ^[Qq]$ ]]; then
    echo -e "\n${CYAN}已退出脚本。${NC}\n"
    exit 0
fi
echo ""

# ------------------------------------------------------------------------------
# 步骤 1: 账号代号 (TAG)
# ------------------------------------------------------------------------------
print_step "1" "设定账号本地代号 (TAG)"
print_tip "该代号仅在你的 Mac 本地作为标识，用来命名 SSH 密钥文件和配置文件。"
print_tip "例如：work (公司工作账号)、personal (个人账号)、client_a (客户/外包账号)。"
echo ""

while true; do
    read -r -p "👉 请输入账号代号 (英文/数字/下划线): " TAG
    TAG=$(echo "$TAG" | tr -d '[:space:]')
    if [[ -z "$TAG" ]]; then
        echo -e "${RED}❌ 错误: 代号不能为空，请重新输入。${NC}"
    elif [[ ! "$TAG" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}❌ 错误: 代号仅支持英文字母、数字、短横线(-)和下划线(_)。${NC}"
    else
        break
    fi
done

SSH_KEY_FILE="$HOME/.ssh/id_ed25519_${TAG}"
GITCONFIG_SUB="$HOME/.gitconfig-${TAG}"
GITCONFIG_GLOBAL="$HOME/.gitconfig"

echo -e "   ${GREEN}✔${NC} 账号代号已设定为: ${BOLD}${TAG}${NC}"
echo -e "   ${DIM}对应私钥路径将为: ${SSH_KEY_FILE}${NC}"
echo -e "   ${DIM}对应配置路径将为: ${GITCONFIG_SUB}${NC}\n"

# ------------------------------------------------------------------------------
# 步骤 2: Git 提交用户名 (user.name)
# ------------------------------------------------------------------------------
print_step "2" "设定 Git 提交作者名 (user.name)"
print_tip "这是你向 GitHub 提交代码（commit）时显示的人名/昵称。"
print_tip "可以与 GitHub 用户名相同，也可以是你的真实英文名（如: Alex Zhang）。"
echo ""

while true; do
    read -r -p "👉 请输入 Git 作者名 (例如: Alex Zhang): " USER_NAME
    # 去除前后多余空格
    USER_NAME=$(echo "$USER_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ -z "$USER_NAME" ]]; then
        echo -e "${RED}❌ 错误: 作者名不能为空。${NC}"
    else
        break
    fi
done
echo -e "   ${GREEN}✔${NC} 作者名设定为: ${BOLD}${USER_NAME}${NC}\n"

# ------------------------------------------------------------------------------
# 步骤 3: Git 提交邮箱 (user.email)
# ------------------------------------------------------------------------------
print_step "3" "设定 Git 提交邮箱 (user.email)"
print_tip "【非常重要】该邮箱必须已经添加到你的目标 GitHub 账号中！"
print_tip "（GitHub 网页 -> Settings -> Emails 查看）。"
print_tip "若邮箱不一致，提交的代码将无法在你的 GitHub 个人主页点亮「绿色贡献方块（绿墙）」。"
echo ""

while true; do
    read -r -p "👉 请输入 Git 提交邮箱 (例如: alex@company.com): " USER_EMAIL
    USER_EMAIL=$(echo "$USER_EMAIL" | tr -d '[:space:]')
    if [[ -z "$USER_EMAIL" ]]; then
        echo -e "${RED}❌ 错误: 邮箱地址不能为空。${NC}"
    elif [[ ! "$USER_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo -e "${YELLOW}⚠️  警告: 邮箱格式看起来可能不标准，但仍可使用。${NC}"
        read -r -p "确认使用该邮箱吗？(y/N): " CONFIRM_EMAIL
        if [[ "$CONFIRM_EMAIL" =~ ^[Yy]$ ]]; then
            break
        fi
    else
        break
    fi
done
echo -e "   ${GREEN}✔${NC} 邮箱设定为: ${BOLD}${USER_EMAIL}${NC}\n"

# ------------------------------------------------------------------------------
# 步骤 4: 关联的项目根目录
# ------------------------------------------------------------------------------
DEFAULT_DIR="~/Projects/${TAG}"
print_step "4" "指定该账号绑定的项目文件夹"
print_tip "只要放入该文件夹内的所有仓库，无需任何额外设置，全部自动使用本账号身份与私钥！"
print_tip "若目录尚不存在，脚本会自动为你创建；若已存在，直接关联绑定，原文件不受任何影响。"
echo ""

read -r -p "👉 请输入项目文件夹路径 [直接回车默认: ${DEFAULT_DIR}]: " INPUT_DIR
if [[ -z "$INPUT_DIR" ]]; then
    DIR_PATH="$DEFAULT_DIR"
else
    DIR_PATH="$INPUT_DIR"
fi

RESOLVED_DIR=$(expand_path "$DIR_PATH")
# 确保以 / 结尾，以满足 gitdir: 匹配该目录下所有子目录的要求
[[ "$DIR_PATH" != */ ]] && DIR_GIT_FORMAT="${DIR_PATH}/" || DIR_GIT_FORMAT="$DIR_PATH"

echo -e "   ${GREEN}✔${NC} 项目目录设定为: ${BOLD}${RESOLVED_DIR}${NC}\n"

# ------------------------------------------------------------------------------
# 确认配置信息
# ------------------------------------------------------------------------------
echo -e "${BOLD}${CYAN}======================================================================${NC}"
echo -e "${BOLD}                       📋 请确认即将应用的配置信息                     ${NC}"
echo -e "${BOLD}${CYAN}======================================================================${NC}"
echo -e "  账号标识:       ${BOLD}${TAG}${NC}"
echo -e "  提交作者名:     ${BOLD}${USER_NAME}${NC}"
echo -e "  提交邮箱:       ${BOLD}${USER_EMAIL}${NC}"
echo -e "  绑定根目录:     ${BOLD}${RESOLVED_DIR}${NC}"
echo -e "  专属 SSH 私钥:  ${BOLD}${SSH_KEY_FILE}${NC}"
echo -e "  专属配置文件:   ${BOLD}${GITCONFIG_SUB}${NC}"
echo -e "${BOLD}${CYAN}======================================================================${NC}"
read -r -p "是否确认以上信息并开始配置？(Y/n, 默认 Y): " CONFIRM_ALL
if [[ "$CONFIRM_ALL" =~ ^[Nn]$ ]]; then
    echo -e "\n${YELLOW}[!] 操作已取消，未进行任何更改。${NC}\n"
    exit 0
fi

# ------------------------------------------------------------------------------
# 开始应用配置
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${PURPLE}==> 正在执行配置...${NC}"

# 1. 检查并创建项目文件夹
if [[ -d "$RESOLVED_DIR" ]]; then
    echo -e "  ${YELLOW}ℹ️  目录已存在: ${RESOLVED_DIR} (直接关联，原文件安全)${NC}"
else
    mkdir -p "$RESOLVED_DIR"
    echo -e "  ${GREEN}✔  已创建目录: ${RESOLVED_DIR}${NC}"
fi

# 2. 检查并生成 SSH 密钥
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

GENERATE_SSH=true
if [[ -f "$SSH_KEY_FILE" ]]; then
    echo -e "\n  ${YELLOW}⚠️  检测到 SSH 密钥已存在:${NC} ${SSH_KEY_FILE}"
    read -r -p "  是否重新生成并覆盖该密钥？(y/N, 默认 N 保留原有): " CONFIRM_SSH
    if [[ "$CONFIRM_SSH" =~ ^[Yy]$ ]]; then
        echo -e "  ${YELLOW}正在覆盖生成新密钥...${NC}"
        rm -f "$SSH_KEY_FILE" "$SSH_KEY_FILE.pub"
    else
        echo -e "  ${CYAN}✔ 保留现有密钥，无需重新生成。${NC}"
        GENERATE_SSH=false
    fi
fi

if [[ "$GENERATE_SSH" == true ]]; then
    ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$SSH_KEY_FILE" -N "" > /dev/null 2>&1
    chmod 600 "$SSH_KEY_FILE"
    chmod 644 "$SSH_KEY_FILE.pub"
    echo -e "  ${GREEN}✔  已生成新 Ed25519 SSH 密钥${NC}"
fi

# 3. 检查并写入专属子配置文件 ~/.gitconfig-<TAG>
WRITE_SUB_CONFIG=true
if [[ -f "$GITCONFIG_SUB" ]]; then
    echo -e "\n  ${YELLOW}⚠️  专属配置文件已存在:${NC} ${GITCONFIG_SUB}"
    read -r -p "  是否覆盖此配置文件？(Y/n, 默认 Y 覆盖更新): " CONFIRM_CFG
    if [[ "$CONFIRM_CFG" =~ ^[Nn]$ ]]; then
        echo -e "  ${CYAN}✔ 跳过写入 ${GITCONFIG_SUB}${NC}"
        WRITE_SUB_CONFIG=false
    fi
fi

if [[ "$WRITE_SUB_CONFIG" == true ]]; then
    cat << EOF > "$GITCONFIG_SUB"
[user]
    name = ${USER_NAME}
    email = ${USER_EMAIL}

[core]
    # 强制该目录所有 git 操作使用独立私钥，避免发错密钥触发认证限制
    sshCommand = ssh -i ${SSH_KEY_FILE} -o IdentitiesOnly=yes
EOF
    echo -e "  ${GREEN}✔  已生成专属配置文件: ${GITCONFIG_SUB}${NC}"
fi

# 4. 检查并挂载到主配置文件 ~/.gitconfig
touch "$GITCONFIG_GLOBAL"
if grep -q "gitdir:${DIR_GIT_FORMAT}" "$GITCONFIG_GLOBAL" 2>/dev/null; then
    echo -e "  ${YELLOW}ℹ️  全局 ~/.gitconfig 中已存在针对 [${DIR_GIT_FORMAT}] 的规则，避免重复写入。${NC}"
else
    cat << EOF >> "$GITCONFIG_GLOBAL"

[includeIf "gitdir:${DIR_GIT_FORMAT}"]
    path = ${GITCONFIG_SUB}
EOF
    echo -e "  ${GREEN}✔  已向全局 ~/.gitconfig 注册 includeIf 目录规则${NC}"
fi

# 5. 复制公钥到剪贴板
if [[ -f "$SSH_KEY_FILE.pub" ]]; then
    pbcopy < "$SSH_KEY_FILE.pub"
    echo -e "  ${GREEN}✔  已自动将 SSH 公钥内容复制到 Mac 剪贴板！${NC}"
fi

# ------------------------------------------------------------------------------
# 引导将公钥添加到 GitHub
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}======================================================================${NC}"
echo -e "${BOLD}${YELLOW}👉 下一步操作：将公钥添加到对应的 GitHub 账号${NC}"
echo -e "${BOLD}${CYAN}======================================================================${NC}"
echo -e "1. 公钥已在你的剪贴板中，随时可以 ${BOLD}Cmd + V${NC} 粘贴。"
echo -e "2. 对应网页地址为: ${UNDERLINE}https://github.com/settings/ssh/new${NC}\n"

read -r -p "是否现在直接在默认浏览器中打开该 GitHub 添加密钥页面？(Y/n, 默认 Y): " OPEN_BROWSER
if [[ ! "$OPEN_BROWSER" =~ ^[Nn]$ ]]; then
    echo -e "${CYAN}正在为你打开浏览器...${NC}"
    open "https://github.com/settings/ssh/new" 2>/dev/null || true
fi

echo -e "\n${BOLD}请在网页上完成以下两步：${NC}"
echo -e "  ① ${BOLD}Title${NC} 栏：填一个好记的名字（例如: ${CYAN}MacMini-${TAG}${NC}）"
echo -e "  ② ${BOLD}Key${NC} 栏：点击输入框，按 ${BOLD}Cmd + V${NC} 粘贴刚刚复制的公钥"
echo -e "  ③ 点击绿色按钮 ${BOLD}Add SSH key${NC} 保存"
echo ""

# ------------------------------------------------------------------------------
# 连通性在线测试
# ------------------------------------------------------------------------------
echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"
read -r -p "在 GitHub 页面保存完毕了吗？按回车开始在线连通性测试 (或输入 s 跳过): " DO_TEST
if [[ ! "$DO_TEST" =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}正在连接 GitHub 验证密钥 (ssh -T git@github.com)...${NC}"
    
    # 尝试连接 GitHub (GitHub 返回状态码通常为 1，需捕获输出判断)
    SSH_TEST_OUTPUT=$(ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 -o IdentitiesOnly=yes -T git@github.com 2>&1 || true)
    
    if echo "$SSH_TEST_OUTPUT" | grep -q "successfully authenticated"; then
        GITHUB_USER=$(echo "$SSH_TEST_OUTPUT" | grep -oE "Hi [^!]+" | sed 's/Hi //')
        echo -e "\n${BOLD}${GREEN}======================================================================${NC}"
        echo -e "${BOLD}${GREEN}       🎉 连通测试成功！GitHub 已正确识别你的身份！                    ${NC}"
        echo -e "${BOLD}${GREEN}======================================================================${NC}"
        echo -e "   识别出的 GitHub 账号为: ${BOLD}${CYAN}@${GITHUB_USER}${NC}"
        echo -e "   该账号与目录 [${RESOLVED_DIR}] 已经完美绑定生效！\n"
    else
        echo -e "\n${BOLD}${RED}======================================================================${NC}"
        echo -e "${BOLD}${RED}       ⚠️ 连通测试未通过，详细返回信息如下：                          ${NC}"
        echo -e "${BOLD}${RED}======================================================================${NC}"
        echo -e "${DIM}${SSH_TEST_OUTPUT}${NC}\n"
        
        echo -e "${BOLD}${YELLOW}【诊断与解决办法】:${NC}"
        if echo "$SSH_TEST_OUTPUT" | grep -qi "Permission denied"; then
            echo -e "  1. 可能是刚才公钥没有在 GitHub 页面成功点击【Add SSH key】保存；"
            echo -e "  2. 或者你浏览器登录的 GitHub 账号与想要绑定的账号不一致；"
            echo -e "  3. 解决方法：重新复制公钥 ${CYAN}pbcopy < ${SSH_KEY_FILE}.pub${NC} 并到对应账号页面保存。"
        elif echo "$SSH_TEST_OUTPUT" | grep -qi "timed out"; then
            echo -e "  1. 连接 GitHub 超时，通常是当前网络环境或代理/VPN 阻止了 22 端口连接；"
            echo -e "  2. 解决方法：检查你的网络连接，或确认是否开启了代理工具。"
        else
            echo -e "  可随时重新运行以下命令手动测试连通性："
            echo -e "  ${CYAN}ssh -i ${SSH_KEY_FILE} -o IdentitiesOnly=yes -T git@github.com${NC}"
        fi
        echo ""
    fi
fi

# ------------------------------------------------------------------------------
# 最终使用教程与速查手册
# ------------------------------------------------------------------------------
echo -e "${BOLD}${CYAN}======================================================================${NC}"
echo -e "${BOLD}                       📖 日常使用教程与速查手册                     ${NC}"
echo -e "${BOLD}${CYAN}======================================================================${NC}"

echo -e "\n${BOLD}1. 如何开始一个新项目？${NC}"
echo -e "   只需进入该目录，按照最普通的官方方法克隆或新建，${BOLD}完全不需要修改任何 URL${NC}："
echo -e "   ${CYAN}cd ${RESOLVED_DIR}${NC}"
echo -e "   ${CYAN}git clone git@github.com:your-account/your-repo.git${NC}"
echo -e "   ${DIM}(注: 一定要用 SSH 地址 git@github.com:...，不要用 https:// 地址)${NC}\n"

echo -e "${BOLD}2. 如何验证当前项目使用的身份？${NC}"
echo -e "   在项目文件夹内打开终端，运行："
echo -e "   ${CYAN}git config user.name${NC}    ${DIM}# 会输出: ${USER_NAME}${NC}"
echo -e "   ${CYAN}git config user.email${NC}   ${DIM}# 会输出: ${USER_EMAIL}${NC}\n"

echo -e "${BOLD}3. 遇到问题怎么自查？(FAQ)${NC}"
echo -e "   ${YELLOW}Q1: 为什么提交后 GitHub 绿墙没有亮起小方块？${NC}"
echo -e "       ${DIM}A: 请登录 GitHub 网页 -> Settings -> Emails，确保【${USER_EMAIL}】在这个列表里。${NC}"
echo -e "   ${YELLOW}Q2: 为什么以前克隆的已有旧项目，作者名没有自动变过来？${NC}"
echo -e "       ${DIM}A: 旧项目本地如果有单独设置，会覆盖全局配置。进入该旧仓库运行：${NC}"
echo -e "          ${CYAN}git config --local --unset user.name${NC}"
echo -e "          ${CYAN}git config --local --unset user.email${NC}"
echo -e "   ${YELLOW}Q3: 为什么 push 时提示要输入密码或 Personal Access Token？${NC}"
echo -e "       ${DIM}A: 说明仓库地址错用了 HTTPS 格式。运行以下命令一键转为 SSH 格式：${NC}"
echo -e "          ${CYAN}git remote set-url origin git@github.com:用户名/仓库名.git${NC}\n"

echo -e "${BOLD}${GREEN}✔ 账号 [${TAG}] 配置流程全部结束，祝编码愉快！${NC}\n"
