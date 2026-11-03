#!/usr/bin/env bash
# ==============================================================================
# Script Name: setup_git_account_en.sh
# Platform: macOS (Apple Silicon & Intel)
# Function: Interactive multi-account GitHub setup with isolated SSH keys,
#           directory binding, and automated connection diagnostics.
# ==============================================================================

# Graceful exit on Ctrl+C
trap 'echo -e "\n\n\033[0;33m[!] Operation cancelled by user. Setup aborted safely without saving incomplete state.\033[0m\n"; exit 1' INT

# Colors and styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
UNDERLINE='\033[4m'
NC='\033[0m' # No Color

# Helper print functions
print_title() {
    echo -e "\n${BOLD}${CYAN}======================================================================${NC}"
    echo -e "${BOLD}${CYAN}  macOS Git Multi-Account & Directory Automation Tool (English)       ${NC}"
    echo -e "${BOLD}${CYAN}======================================================================${NC}\n"
    echo -e "${DIM}Hint: You can press Ctrl+C anytime to safely abort.${NC}\n"
}

print_step() {
    local num="$1"
    local title="$2"
    echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"
    echo -e "${BOLD}${GREEN}【Step $num/4】$title${NC}"
    echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"
}

print_tip() {
    echo -e "${DIM}💡 Note: $1${NC}"
}

# Expand tilde (~ to $HOME)
expand_path() {
    local p="$1"
    if [[ "$p" == ~* ]]; then
        echo "${p/#\~/$HOME}"
    else
        echo "$p"
    fi
}

# ------------------------------------------------------------------------------
# Check and display existing accounts
# ------------------------------------------------------------------------------
check_and_display_existing_accounts() {
    local gitconfig_global="$HOME/.gitconfig"
    local found_count=0
    local cur_dir=""
    local cur_path=""
    
    echo -e "${BOLD}${CYAN}🔍 Inspecting existing Git multi-accounts and directories...${NC}\n"
    
    if [[ -f "$gitconfig_global" ]]; then
        # Scan includeIf rules in ~/.gitconfig
        while IFS= read -r line || [[ -n "$line" ]]; do
            if [[ "$line" =~ \[includeIf[[:space:]]+\"gitdir:([^\"]+)\"\] ]]; then
                cur_dir="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]*path[[:space:]]*=[[:space:]]*(.+) ]]; then
                cur_path="${BASH_REMATCH[1]}"
                cur_path=$(expand_path "$cur_path")
                
                if [[ -n "$cur_dir" && -n "$cur_path" ]]; then
                    found_count=$((found_count + 1))
                    
                    # Extract TAG from .gitconfig-<TAG>
                    local tag_name="custom"
                    if [[ "$cur_path" =~ \.gitconfig-(.+) ]]; then
                        tag_name="${BASH_REMATCH[1]}"
                    fi
                    
                    # Read author info and key from the child config
                    local u_name="Not Set"
                    local u_email="Not Set"
                    local ssh_key="Not Detected"
                    local key_status=""
                    local dir_status=""
                    
                    if [[ -f "$cur_path" ]]; then
                        u_name=$(git config --file "$cur_path" user.name 2>/dev/null || echo "Not Set")
                        u_email=$(git config --file "$cur_path" user.email 2>/dev/null || echo "Not Set")
                        local ssh_cmd
                        ssh_cmd=$(git config --file "$cur_path" core.sshCommand 2>/dev/null || echo "")
                        if [[ "$ssh_cmd" =~ -i[[:space:]]+([^[:space:]]+) ]]; then
                            ssh_key="${BASH_REMATCH[1]}"
                            local resolved_key
                            resolved_key=$(expand_path "$ssh_key")
                            if [[ -f "$resolved_key" ]]; then
                                key_status=" ${GREEN}(Key OK ✔)${NC}"
                            else
                                key_status=" ${RED}(Key File Missing ⚠️)${NC}"
                            fi
                        fi
                    fi
                    
                    local resolved_dir
                    resolved_dir=$(expand_path "$cur_dir")
                    if [[ -d "$resolved_dir" ]]; then
                        dir_status="${GREEN}(Directory Ready ✔)${NC}"
                    else
                        dir_status="${YELLOW}(Directory Not Created)${NC}"
                    fi
                    
                    echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"
                    echo -e "${BOLD} [${found_count}] Account Tag: ${GREEN}${tag_name}${NC}"
                    echo -e "     • Bound Directory:   ${BOLD}${cur_dir}${NC} ${dir_status}"
                    echo -e "     • Commit Author:     ${u_name} <${u_email}>"
                    echo -e "     • SSH Private Key:   ${ssh_key}${key_status}"
                    echo -e "     • Sub-config File:   ${cur_path}"
                    
                    cur_dir=""
                    cur_path=""
                fi
            fi
        done < "$gitconfig_global"
    fi
    
    if [[ $found_count -eq 0 ]]; then
        echo -e "${YELLOW}ℹ️  No Git multi-account bindings detected in your global configuration yet.${NC}"
        echo -e "${DIM}   (Running this wizard will set up your first account configuration)${NC}\n"
    else
        echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"
        echo -e "${GREEN}✔ Detected ${found_count} configured account rule(s).${NC}\n"
    fi
}

# ------------------------------------------------------------------------------
# Main Flow Starts
# ------------------------------------------------------------------------------
print_title
check_and_display_existing_accounts

echo -e "👉 Press ${BOLD}[Enter]${NC} to configure/add an account (or enter ${BOLD}q${NC} to quit): "
read -r CONTINUE_CHOICE
if [[ "$CONTINUE_CHOICE" =~ ^[Qq]$ ]]; then
    echo -e "\n${CYAN}Exited.${NC}\n"
    exit 0
fi
echo ""

# ------------------------------------------------------------------------------
# Step 1: Account Tag (TAG)
# ------------------------------------------------------------------------------
print_step "1" "Set Local Account Identifier Tag (TAG)"
print_tip "This tag is used locally to name your SSH key and config files."
print_tip "Examples: work (company account), personal (open source), client_a (freelance)."
echo ""

while true; do
    read -r -p "👉 Enter account tag (alphanumeric/hyphen/underscore): " TAG
    TAG=$(echo "$TAG" | tr -d '[:space:]')
    if [[ -z "$TAG" ]]; then
        echo -e "${RED}❌ Error: Account tag cannot be empty.${NC}"
    elif [[ ! "$TAG" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}❌ Error: Tag can only contain letters, numbers, hyphens (-), and underscores (_).${NC}"
    else
        break
    fi
done

SSH_KEY_FILE="$HOME/.ssh/id_ed25519_${TAG}"
GITCONFIG_SUB="$HOME/.gitconfig-${TAG}"
GITCONFIG_GLOBAL="$HOME/.gitconfig"

echo -e "   ${GREEN}✔${NC} Account tag set to: ${BOLD}${TAG}${NC}"
echo -e "   ${DIM}Private key path: ${SSH_KEY_FILE}${NC}"
echo -e "   ${DIM}Sub-config path:  ${GITCONFIG_SUB}${NC}\n"

# ------------------------------------------------------------------------------
# Step 2: Git Author Name (user.name)
# ------------------------------------------------------------------------------
print_step "2" "Set Git Commit Author Name (user.name)"
print_tip "This is the author name displayed in Git commit logs on GitHub."
print_tip "Can be your real name or developer handle (e.g., Alex Zhang)."
echo ""

while true; do
    read -r -p "👉 Enter Git author name (e.g., Alex Zhang): " USER_NAME
    USER_NAME=$(echo "$USER_NAME" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    if [[ -z "$USER_NAME" ]]; then
        echo -e "${RED}❌ Error: Author name cannot be empty.${NC}"
    else
        break
    fi
done
echo -e "   ${GREEN}✔${NC} Author name set to: ${BOLD}${USER_NAME}${NC}\n"

# ------------------------------------------------------------------------------
# Step 3: Git Commit Email (user.email)
# ------------------------------------------------------------------------------
print_step "3" "Set Git Commit Email (user.email)"
print_tip "【CRITICAL】This email MUST be added to your target GitHub account's email settings!"
print_tip "(Check via GitHub -> Settings -> Emails)."
print_tip "If emails do not match, commits will NOT contribute to your GitHub green contribution squares!"
echo ""

while true; do
    read -r -p "👉 Enter Git commit email (e.g., alex@company.com): " USER_EMAIL
    USER_EMAIL=$(echo "$USER_EMAIL" | tr -d '[:space:]')
    if [[ -z "$USER_EMAIL" ]]; then
        echo -e "${RED}❌ Error: Email cannot be empty.${NC}"
    elif [[ ! "$USER_EMAIL" =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]]; then
        echo -e "${YELLOW}⚠️  Warning: Email format looks unusual, but you may still proceed.${NC}"
        read -r -p "Confirm using this email? (y/N): " CONFIRM_EMAIL
        if [[ "$CONFIRM_EMAIL" =~ ^[Yy]$ ]]; then
            break
        fi
    else
        break
    fi
done
echo -e "   ${GREEN}✔${NC} Email set to: ${BOLD}${USER_EMAIL}${NC}\n"

# ------------------------------------------------------------------------------
# Step 4: Associated Project Directory
# ------------------------------------------------------------------------------
DEFAULT_DIR="~/Projects/${TAG}"
print_step "4" "Specify Associated Project Directory"
print_tip "All repositories placed inside this directory will automatically use this identity and key!"
print_tip "If the directory does not exist, it will be created; existing folders remain completely untouched."
echo ""

read -r -p "👉 Enter project directory path [Press Enter for default: ${DEFAULT_DIR}]: " INPUT_DIR
if [[ -z "$INPUT_DIR" ]]; then
    DIR_PATH="$DEFAULT_DIR"
else
    DIR_PATH="$INPUT_DIR"
fi

RESOLVED_DIR=$(expand_path "$DIR_PATH")
# Ensure trailing slash for gitdir: child directory matching
[[ "$DIR_PATH" != */ ]] && DIR_GIT_FORMAT="${DIR_PATH}/" || DIR_GIT_FORMAT="$DIR_PATH"

echo -e "   ${GREEN}✔${NC} Project directory set to: ${BOLD}${RESOLVED_DIR}${NC}\n"

# ------------------------------------------------------------------------------
# Configuration Summary & Confirmation
# ------------------------------------------------------------------------------
echo -e "${BOLD}${CYAN}======================================================================${NC}"
echo -e "${BOLD}                       📋 Configuration Summary                       ${NC}"
echo -e "${BOLD}${CYAN}======================================================================${NC}"
echo -e "  Account Tag:        ${BOLD}${TAG}${NC}"
echo -e "  Author Name:        ${BOLD}${USER_NAME}${NC}"
echo -e "  Commit Email:       ${BOLD}${USER_EMAIL}${NC}"
echo -e "  Bound Directory:    ${BOLD}${RESOLVED_DIR}${NC}"
echo -e "  SSH Private Key:    ${BOLD}${SSH_KEY_FILE}${NC}"
echo -e "  Sub-config File:    ${BOLD}${GITCONFIG_SUB}${NC}"
echo -e "${BOLD}${CYAN}======================================================================${NC}"
read -r -p "Proceed and apply this configuration? (Y/n, Default Y): " CONFIRM_ALL
if [[ "$CONFIRM_ALL" =~ ^[Nn]$ ]]; then
    echo -e "\n${YELLOW}[!] Aborted by user. No changes were made.${NC}\n"
    exit 0
fi

# ------------------------------------------------------------------------------
# Apply Configuration
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${PURPLE}==> Applying configuration...${NC}"

# 1. Check & create project directory
if [[ -d "$RESOLVED_DIR" ]]; then
    echo -e "  ${YELLOW}ℹ️  Directory already exists: ${RESOLVED_DIR} (Bound directly, files safe)${NC}"
else
    mkdir -p "$RESOLVED_DIR"
    echo -e "  ${GREEN}✔  Created directory: ${RESOLVED_DIR}${NC}"
fi

# 2. Check & generate SSH Key
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

GENERATE_SSH=true
if [[ -f "$SSH_KEY_FILE" ]]; then
    echo -e "\n  ${YELLOW}⚠️  Existing SSH key detected:${NC} ${SSH_KEY_FILE}"
    read -r -p "  Overwrite and generate a new key? (y/N, Default N to keep existing): " CONFIRM_SSH
    if [[ "$CONFIRM_SSH" =~ ^[Yy]$ ]]; then
        echo -e "  ${YELLOW}Overwriting with newly generated key...${NC}"
        rm -f "$SSH_KEY_FILE" "$SSH_KEY_FILE.pub"
    else
        echo -e "  ${CYAN}✔ Preserving existing key, skipping generation.${NC}"
        GENERATE_SSH=false
    fi
fi

if [[ "$GENERATE_SSH" == true ]]; then
    ssh-keygen -t ed25519 -C "$USER_EMAIL" -f "$SSH_KEY_FILE" -N "" > /dev/null 2>&1
    chmod 600 "$SSH_KEY_FILE"
    chmod 644 "$SSH_KEY_FILE.pub"
    echo -e "  ${GREEN}✔  Generated new Ed25519 SSH key${NC}"
fi

# 3. Check & write sub-config ~/.gitconfig-<TAG>
WRITE_SUB_CONFIG=true
if [[ -f "$GITCONFIG_SUB" ]]; then
    echo -e "\n  ${YELLOW}⚠️  Configuration file already exists:${NC} ${GITCONFIG_SUB}"
    read -r -p "  Overwrite this configuration file? (Y/n, Default Y): " CONFIRM_CFG
    if [[ "$CONFIRM_CFG" =~ ^[Nn]$ ]]; then
        echo -e "  ${CYAN}✔ Skipping overwrite of ${GITCONFIG_SUB}${NC}"
        WRITE_SUB_CONFIG=false
    fi
fi

if [[ "$WRITE_SUB_CONFIG" == true ]]; then
    cat << EOF > "$GITCONFIG_SUB"
[user]
    name = ${USER_NAME}
    email = ${USER_EMAIL}

[core]
    # Enforces using this specific key exclusively to prevent authentication limits
    sshCommand = ssh -i ${SSH_KEY_FILE} -o IdentitiesOnly=yes
EOF
    echo -e "  ${GREEN}✔  Updated account sub-config: ${GITCONFIG_SUB}${NC}"
fi

# 4. Check & append includeIf to ~/.gitconfig
touch "$GITCONFIG_GLOBAL"
if grep -q "gitdir:${DIR_GIT_FORMAT}" "$GITCONFIG_GLOBAL" 2>/dev/null; then
    echo -e "  ${YELLOW}ℹ️  Global ~/.gitconfig already contains rule for [${DIR_GIT_FORMAT}], skipping duplicate.${NC}"
else
    cat << EOF >> "$GITCONFIG_GLOBAL"

[includeIf "gitdir:${DIR_GIT_FORMAT}"]
    path = ${GITCONFIG_SUB}
EOF
    echo -e "  ${GREEN}✔  Registered includeIf directory rule in global ~/.gitconfig${NC}"
fi

# 5. Copy public key to clipboard
if [[ -f "$SSH_KEY_FILE.pub" ]]; then
    pbcopy < "$SSH_KEY_FILE.pub"
    echo -e "  ${GREEN}✔  SSH public key copied to Mac clipboard automatically!${NC}"
fi

# ------------------------------------------------------------------------------
# Guide adding public key to GitHub
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}${CYAN}======================================================================${NC}"
echo -e "${BOLD}${YELLOW}👉 Next Step: Add Public Key to Your GitHub Account${NC}"
echo -e "${BOLD}${CYAN}======================================================================${NC}"
echo -e "1. The public key is already in your clipboard (paste anytime with ${BOLD}Cmd + V${NC})."
echo -e "2. Direct settings URL: ${UNDERLINE}https://github.com/settings/ssh/new${NC}\n"

read -r -p "Open GitHub SSH settings page in your default browser now? (Y/n, Default Y): " OPEN_BROWSER
if [[ ! "$OPEN_BROWSER" =~ ^[Nn]$ ]]; then
    echo -e "${CYAN}Opening browser...${NC}"
    open "https://github.com/settings/ssh/new" 2>/dev/null || true
fi

echo -e "\n${BOLD}Please perform these simple steps on the webpage:${NC}"
echo -e "  ① ${BOLD}Title${NC} field: Enter a memorable name (e.g., ${CYAN}MacMini-${TAG}${NC})"
echo -e "  ② ${BOLD}Key${NC} field: Click the box and press ${BOLD}Cmd + V${NC} to paste the public key"
echo -e "  ③ Click the green button ${BOLD}Add SSH key${NC} to save"
echo ""

# ------------------------------------------------------------------------------
# Live Connection Handshake Test
# ------------------------------------------------------------------------------
echo -e "${BOLD}${BLUE}----------------------------------------------------------------------${NC}"
read -r -p "Saved the key on GitHub? Press [Enter] to run live handshake test (or type 's' to skip): " DO_TEST
if [[ ! "$DO_TEST" =~ ^[Ss]$ ]]; then
    echo -e "\n${CYAN}Connecting to GitHub to verify credentials (ssh -T git@github.com)...${NC}"
    
    # Attempt handshake with GitHub
    SSH_TEST_OUTPUT=$(ssh -i "$SSH_KEY_FILE" -o StrictHostKeyChecking=accept-new -o ConnectTimeout=8 -o IdentitiesOnly=yes -T git@github.com 2>&1 || true)
    
    if echo "$SSH_TEST_OUTPUT" | grep -q "successfully authenticated"; then
        GITHUB_USER=$(echo "$SSH_TEST_OUTPUT" | grep -oE "Hi [^!]+" | sed 's/Hi //')
        echo -e "\n${BOLD}${GREEN}======================================================================${NC}"
        echo -e "${BOLD}${GREEN}    🎉 Handshake Successful! GitHub verified your credentials!        ${NC}"
        echo -e "${BOLD}${GREEN}======================================================================${NC}"
        echo -e "   Authenticated GitHub User: ${BOLD}${CYAN}@${GITHUB_USER}${NC}"
        echo -e "   The directory [${RESOLVED_DIR}] is now active and ready for use!\n"
    else
        echo -e "\n${BOLD}${RED}======================================================================${NC}"
        echo -e "${BOLD}${RED}    ⚠️ Handshake failed. Details returned from GitHub:               ${NC}"
        echo -e "${BOLD}${RED}======================================================================${NC}"
        echo -e "${DIM}${SSH_TEST_OUTPUT}${NC}\n"
        
        echo -e "${BOLD}${YELLOW}【Diagnosis & Recommendations】:${NC}"
        if echo "$SSH_TEST_OUTPUT" | grep -qi "Permission denied"; then
            echo -e "  1. You might not have clicked [Add SSH key] on the GitHub page yet."
            echo -e "  2. Your browser may be logged into a different GitHub account than intended."
            echo -e "  3. Fix: Re-copy key via ${CYAN}pbcopy < ${SSH_KEY_FILE}.pub${NC} and add it to the correct account."
        elif echo "$SSH_TEST_OUTPUT" | grep -qi "timed out"; then
            echo -e "  1. Connection timed out. Your network or VPN may be blocking SSH port 22."
            echo -e "  2. Fix: Check your internet connection or proxy settings."
        else
            echo -e "  You can test manually anytime using:"
            echo -e "  ${CYAN}ssh -i ${SSH_KEY_FILE} -o IdentitiesOnly=yes -T git@github.com${NC}"
        fi
        echo ""
    fi
fi

# ------------------------------------------------------------------------------
# Daily Usage Cheatsheet & FAQ
# ------------------------------------------------------------------------------
echo -e "${BOLD}${CYAN}======================================================================${NC}"
echo -e "${BOLD}                       📖 Daily Cheatsheet & Guide                    ${NC}"
echo -e "${BOLD}${CYAN}======================================================================${NC}"

echo -e "\n${BOLD}1. How to start a new project?${NC}"
echo -e "   Navigate to your configured directory and clone using standard SSH URLs (${BOLD}no rewrites needed${NC}):"
echo -e "   ${CYAN}cd ${RESOLVED_DIR}${NC}"
echo -e "   ${CYAN}git clone git@github.com:your-account/your-repo.git${NC}"
echo -e "   ${DIM}(Note: Always use SSH git@github.com:... URLs, avoid https://)${NC}\n"

echo -e "${BOLD}2. How to check active identity in a repo?${NC}"
echo -e "   Run these inside any repository under that directory:"
echo -e "   ${CYAN}git config user.name${NC}    ${DIM}# Outputs: ${USER_NAME}${NC}"
echo -e "   ${CYAN}git config user.email${NC}   ${DIM}# Outputs: ${USER_EMAIL}${NC}\n"

echo -e "${BOLD}3. Common Troubleshooting (FAQ):${NC}"
echo -e "   ${YELLOW}Q1: Why aren't my commits showing up on my contribution graph?${NC}"
echo -e "       ${DIM}A: Ensure [${USER_EMAIL}] is listed under GitHub -> Settings -> Emails.${NC}"
echo -e "   ${YELLOW}Q2: Why does an existing moved repository still use my old author name?${NC}"
echo -e "       ${DIM}A: Local repo configs override directory rules. Run inside that repository:${NC}"
echo -e "          ${CYAN}git config --local --unset user.name${NC}"
echo -e "          ${CYAN}git config --local --unset user.email${NC}"
echo -e "   ${YELLOW}Q3: Why am I asked for a password or Token when pushing?${NC}"
echo -e "       ${DIM}A: The repository was cloned via HTTPS. Switch it to SSH with:${NC}"
echo -e "          ${CYAN}git remote set-url origin git@github.com:owner/repo.git${NC}\n"

echo -e "${BOLD}${GREEN}✔ Setup for account [${TAG}] completed! Happy coding!${NC}\n"
