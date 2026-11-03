#!/usr/bin/env bash
# ==============================================================================
# Script Name: setup_git_account.sh (Master Launcher)
# Function: Language router for macOS Git Multi-Account Manager
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check command line flags
case "$1" in
    --en|-en|en|--english)
        shift
        exec "${SCRIPT_DIR}/setup_git_account_en.sh" "$@"
        ;;
    --zh|-zh|zh|--cn|-cn|cn|--chinese)
        shift
        exec "${SCRIPT_DIR}/setup_git_account_zh.sh" "$@"
        ;;
esac

# Interactive language selection
echo ""
echo "======================================================"
echo "  macOS Git Multi-Account Manager / 多账号自动化管理  "
echo "======================================================"
echo "Please select your language / 请选择语言:"
echo "  1) 简体中文 (Chinese)  [默认 / Default]"
echo "  2) English"
echo "======================================================"
read -r -p "👉 Please choose / 请选择 [1-2, 默认: 1]: " LANG_CHOICE

case "$LANG_CHOICE" in
    2|[Ee][Nn]|[Ee][Nn][Gg]*)
        exec "${SCRIPT_DIR}/setup_git_account_en.sh" "$@"
        ;;
    *)
        exec "${SCRIPT_DIR}/setup_git_account_zh.sh" "$@"
        ;;
esac
