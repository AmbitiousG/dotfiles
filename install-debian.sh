#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install-debian.sh [--nvim]

Install or upgrade Vim by default and link ~/.vimrc to this repository.
With --nvim, install or upgrade Neovim and link ~/.config/nvim/init.lua.

If the other editor already exists on the system, its config link is refreshed
too. Existing real config files are backed up before links are created.
EOF
}

mode="vim"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --nvim|-n)
      mode="nvim"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This script requires apt-get and is intended for Debian-based systems." >&2
  exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
  sudo_cmd=()
else
  if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo is required when running as a non-root user." >&2
    exit 1
  fi
  sudo_cmd=(sudo)
fi

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
vimrc_source="$repo_dir/.vimrc"
nvim_source="$repo_dir/nvim/init.lua"

require_file() {
  local path="$1"
  if [ ! -f "$path" ]; then
    echo "Missing required file: $path" >&2
    exit 1
  fi
}

apt_install_or_upgrade() {
  local package="$1"
  echo "Updating apt package lists..."
  "${sudo_cmd[@]}" apt-get update
  echo "Installing/upgrading $package..."
  "${sudo_cmd[@]}" apt-get install -y "$package"
}

backup_path() {
  local path="$1"
  local stamp
  local candidate
  stamp="$(date +%Y%m%d%H%M%S)"
  candidate="$path.backup.$stamp"
  while [ -e "$candidate" ] || [ -L "$candidate" ]; do
    sleep 1
    stamp="$(date +%Y%m%d%H%M%S)"
    candidate="$path.backup.$stamp"
  done
  printf '%s\n' "$candidate"
}

link_config() {
  local source="$1"
  local target="$2"
  local target_dir
  local source_real
  local target_real
  local backup

  require_file "$source"
  target_dir="$(dirname "$target")"
  mkdir -p "$target_dir"

  source_real="$(readlink -f "$source")"
  if [ -L "$target" ]; then
    target_real="$(readlink -f "$target" || true)"
    if [ "$target_real" = "$source_real" ]; then
      echo "Already linked: $target -> $source"
      return
    fi
    backup="$(backup_path "$target")"
    echo "Backing up existing link $target to $backup"
    mv "$target" "$backup"
  elif [ -e "$target" ]; then
    backup="$(backup_path "$target")"
    echo "Backing up existing file $target to $backup"
    mv "$target" "$backup"
  fi

  ln -s "$source" "$target"
  echo "Linked: $target -> $source"
}

link_vim() {
  link_config "$vimrc_source" "$HOME/.vimrc"
}

link_nvim() {
  link_config "$nvim_source" "$HOME/.config/nvim/init.lua"
}

if [ "$mode" = "nvim" ]; then
  apt_install_or_upgrade neovim
  link_nvim
  if command -v vim >/dev/null 2>&1; then
    link_vim
  fi
else
  apt_install_or_upgrade vim
  link_vim
  if command -v nvim >/dev/null 2>&1; then
    link_nvim
  fi
fi

echo "Done."
