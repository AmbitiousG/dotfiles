#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
INSTALL_PACKAGES=1
CHANGE_SHELL=0

usage() {
  cat <<'USAGE'
Usage: ./install.sh [--no-packages] [--chsh]

Options:
  --no-packages  Skip apt package installation and only run stow.
  --chsh         Change the current user's login shell to zsh.
  -h, --help     Show this help.
USAGE
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --no-packages)
      INSTALL_PACKAGES=0
      ;;
    --chsh)
      CHANGE_SHELL=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

run_as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

install_packages() {
  if ! command -v apt-get >/dev/null 2>&1; then
    echo "==> apt-get not found, skipping package installation"
    return
  fi

  if [ "$(id -u)" -ne 0 ] && ! command -v sudo >/dev/null 2>&1; then
    echo "error: sudo is required for apt package installation" >&2
    echo "       rerun as root or use --no-packages" >&2
    exit 1
  fi

  local base_packages=(
    ca-certificates
    curl
    fd-find
    fzf
    git
    htop
    jq
    lsof
    ripgrep
    stow
    tmux
    tree
    unzip
    vim
    wget
    zsh
    zsh-autosuggestions
    zsh-syntax-highlighting
  )
  local optional_packages=(
    starship
    lazygit
  )

  echo "==> Installing base packages"
  run_as_root apt-get update
  run_as_root apt-get install -y "${base_packages[@]}"

  for package in "${optional_packages[@]}"; do
    if apt-cache show "$package" >/dev/null 2>&1; then
      echo "==> Installing optional package: $package"
      run_as_root apt-get install -y "$package"
    else
      echo "==> Optional package not available in apt: $package"
    fi
  done
}

run_stow() {
  if ! command -v stow >/dev/null 2>&1; then
    echo "error: stow is not installed" >&2
    echo "       install it with: sudo apt-get install stow" >&2
    exit 1
  fi

  local packages=(
    zsh
    vim
    tmux
    starship
    git
    lazygit
  )

  echo "==> Linking dotfiles with stow"
  stow --dir="$DOTFILES_DIR" --target="$HOME" --restow "${packages[@]}"
}

change_shell() {
  if [ "$CHANGE_SHELL" -ne 1 ]; then
    return
  fi

  if ! command -v zsh >/dev/null 2>&1; then
    echo "error: zsh is not installed" >&2
    exit 1
  fi

  local zsh_path
  zsh_path="$(command -v zsh)"

  if ! grep -qxF "$zsh_path" /etc/shells; then
    printf "%s\n" "$zsh_path" | run_as_root tee -a /etc/shells >/dev/null
  fi

  chsh -s "$zsh_path"
}

if [ "$INSTALL_PACKAGES" -eq 1 ]; then
  install_packages
fi

run_stow
change_shell

cat <<EOF
==> Done

Dotfiles linked from: $DOTFILES_DIR

If you did not pass --chsh, change your shell later with:
  chsh -s "\$(command -v zsh)"
EOF
