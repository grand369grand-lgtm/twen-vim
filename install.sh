#!/usr/bin/env bash
#
# Twen Vim - CLI Installer
# A LazyVim-based Neovim configuration framework
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/grand369grand-lgtm/twen-vim/main/install.sh | bash
#   OR
#   git clone https://github.com/grand369grand-lgtm/twen-vim.git ~/.config/nvim
#

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Config
REPO_URL="https://github.com/grand369grand-lgtm/twen-vim.git"
NVIM_CONFIG_DIR="${NVIM_CONFIG_DIR:-$HOME/.config/nvim}"
BACKUP_DIR="${NVIM_CONFIG_DIR}.backup.$(date +%Y%m%d%H%M%S)"

# Banner
print_banner() {
    echo -e "${CYAN}"
    echo "  ╔═══════════════════════════════════════╗"
    echo "  ║         T W E N   V I M              ║"
    echo "  ║   LazyVim-based Neovim Framework     ║"
    echo "  ╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

# Logging helpers
info()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Check if a command exists
has_cmd() {
    command -v "$1" &>/dev/null
}

# Detect OS
detect_os() {
    local os="unknown"
    case "$(uname -s)" in
        Linux*)  os="linux" ;;
        Darwin*) os="macos" ;;
        *)       os="other" ;;
    esac
    echo "$os"
}

# Install Neovim if not present
install_neovim() {
    if has_cmd nvim; then
        local nvim_version
        nvim_version=$(nvim --version | head -1)
        success "Neovim already installed: ${nvim_version}"
        return 0
    fi

    info "Neovim not found. Installing..."

    local os
    os=$(detect_os)

    case "$os" in
        linux)
            if has_cmd apt-get; then
                info "Installing via apt-get..."
                sudo apt-get update -qq && sudo apt-get install -y -qq neovim
            elif has_cmd dnf; then
                info "Installing via dnf..."
                sudo dnf install -y neovim
            elif has_cmd pacman; then
                info "Installing via pacman..."
                sudo pacman -S --noconfirm neovim
            elif has_cmd zypper; then
                info "Installing via zypper..."
                sudo zypper install -y neovim
            else
                error "Unsupported package manager. Please install Neovim manually:"
                error "  https://github.com/neovim/neovim/wiki/Installing-Neovim"
                exit 1
            fi
            ;;
        macos)
            if has_cmd brew; then
                info "Installing via Homebrew..."
                brew install neovim
            elif has_cmd port; then
                info "Installing via MacPorts..."
                sudo port install neovim
            else
                error "No package manager found. Install Homebrew first: https://brew.sh"
                exit 1
            fi
            ;;
        *)
            error "Unsupported OS. Please install Neovim manually:"
            error "  https://github.com/neovim/neovim/wiki/Installing-Neovim"
            exit 1
            ;;
    esac

    if has_cmd nvim; then
        success "Neovim installed successfully!"
    else
        error "Neovim installation failed. Please install it manually."
        exit 1
    fi
}

# Install Git if not present
install_git() {
    if has_cmd git; then
        success "Git already installed."
        return 0
    fi

    info "Git not found. Installing..."

    local os
    os=$(detect_os)

    case "$os" in
        linux)
            if has_cmd apt-get; then
                sudo apt-get update -qq && sudo apt-get install -y -qq git
            elif has_cmd dnf; then
                sudo dnf install -y git
            elif has_cmd pacman; then
                sudo pacman -S --noconfirm git
            fi
            ;;
        macos)
            if has_cmd brew; then
                brew install git
            fi
            ;;
    esac

    if has_cmd git; then
        success "Git installed successfully!"
    else
        error "Git installation failed. Please install it manually."
        exit 1
    fi
}

# Install dependencies
install_dependencies() {
    info "Checking dependencies..."

    local os
    os=$(detect_os)

    case "$os" in
        linux)
            if has_cmd apt-get; then
                info "Installing dependencies via apt-get..."
                sudo apt-get update -qq 2>/dev/null || true
                sudo apt-get install -y -qq gcc make ripgrep fd-find unzip gzip git curl wget 2>/dev/null || true
            elif has_cmd pacman; then
                info "Installing dependencies via pacman..."
                sudo pacman -S --noconfirm --needed gcc make ripgrep fd unzip gzip git curl wget 2>/dev/null || true
            elif has_cmd dnf; then
                info "Installing dependencies via dnf..."
                sudo dnf install -y gcc make ripgrep fd-find unzip gzip git curl wget 2>/dev/null || true
            fi
            ;;
        macos)
            if has_cmd brew; then
                info "Installing dependencies via Homebrew..."
                brew install gcc make ripgrep fd unzip gzip git curl wget 2>/dev/null || true
            fi
            ;;
    esac

    success "Dependencies checked."
}

# Backup existing config
backup_config() {
    if [ -d "$NVIM_CONFIG_DIR" ]; then
        warn "Existing Neovim config found at ${NVIM_CONFIG_DIR}"
        info "Backing up to ${BACKUP_DIR}..."
        mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
        success "Backup created."
    fi
}

# Clone Twen Vim
clone_twenvim() {
    info "Cloning Twen Vim from ${REPO_URL}..."
    git clone "$REPO_URL" "$NVIM_CONFIG_DIR"
    success "Twen Vim cloned to ${NVIM_CONFIG_DIR}"
}

# Initial setup - run Neovim headless to install plugins
install_plugins() {
    info "Installing LazyVim plugins (this may take a moment)..."
    timeout 120 nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    success "Plugins installed."
}

# Uninstall function
uninstall_twenvim() {
    print_banner
    warn "Uninstalling Twen Vim..."

    if [ -d "$NVIM_CONFIG_DIR" ]; then
        info "Removing ${NVIM_CONFIG_DIR}..."
        rm -rf "$NVIM_CONFIG_DIR"
        success "Twen Vim config removed."
    else
        warn "No Twen Vim config found at ${NVIM_CONFIG_DIR}."
    fi

    local state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/nvim"
    local data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/nvim"
    local cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/nvim"

    info "To fully remove all Neovim data, run:"
    echo -e "  ${CYAN}rm -rf ${data_dir} ${state_dir} ${cache_dir}${NC}"

    success "Twen Vim uninstalled."
    exit 0
}

# Update function
update_twenvim() {
    print_banner
    info "Updating Twen Vim..."

    if [ ! -d "$NVIM_CONFIG_DIR/.git" ]; then
        error "Twen Vim not found at ${NVIM_CONFIG_DIR}"
        exit 1
    fi

    cd "$NVIM_CONFIG_DIR"
    git pull origin main
    success "Twen Vim updated."

    info "Updating plugins..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    success "Plugins updated."

    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --uninstall|-u)
            uninstall_twenvim
            ;;
        --update|-U)
            update_twenvim
            ;;
        --help|-h)
            print_banner
            echo -e "${BOLD}Usage:${NC}"
            echo "  install.sh              Install Twen Vim"
            echo "  install.sh --update     Update Twen Vim"
            echo "  install.sh --uninstall  Uninstall Twen Vim"
            echo "  install.sh --help       Show this help"
            echo ""
            echo -e "${BOLD}Environment Variables:${NC}"
            echo "  NVIM_CONFIG_DIR         Override default config directory"
            echo "                          (default: ~/.config/nvim)"
            echo ""
            echo -e "${BOLD}One-liner Install:${NC}"
            echo -e "  ${CYAN}curl -sL https://raw.githubusercontent.com/grand369grand-lgtm/twen-vim/main/install.sh | bash${NC}"
            echo ""
            echo -e "${BOLD}Manual Install:${NC}"
            echo -e "  ${CYAN}git clone https://github.com/grand369grand-lgtm/twen-vim.git ~/.config/nvim${NC}"
            echo ""
            echo -e "${BOLD}More info:${NC}"
            echo -e "  ${CYAN}https://github.com/grand369grand-lgtm/twen-vim${NC}"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Run 'install.sh --help' for usage."
            exit 1
            ;;
    esac
    shift
done

# Main install flow
main() {
    print_banner

    info "Starting Twen Vim installation..."
    echo ""

    install_git
    install_neovim
    install_dependencies
    backup_config
    clone_twenvim
    install_plugins

    echo ""
    success "Twen Vim installed successfully!"
    echo ""
    echo -e "${BOLD}Next steps:${NC}"
    echo -e "  1. Launch Neovim:  ${CYAN}nvim${NC}"
    echo -e "  2. Plugins will auto-install on first launch if not done already."
    echo -e "  3. Check health:   ${CYAN}:checkhealth${NC} (inside Neovim)"
    echo ""
    echo -e "${BOLD}Useful commands:${NC}"
    echo -e "  Update Twen Vim:   ${CYAN}~/.config/nvim/install.sh --update${NC}"
    echo -e "  Uninstall:         ${CYAN}~/.config/nvim/install.sh --uninstall${NC}"
    echo -e "  LazyVim docs:      ${CYAN}:help LazyVim${NC} (inside Neovim)"
    echo ""
    echo -e "${BOLD}Project:${NC}"
    echo -e "  ${CYAN}https://github.com/grand369grand-lgtm/twen-vim${NC}"
    echo ""
}

main
