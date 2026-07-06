#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./install-debian.sh [--nvim]

Install or upgrade Vim by default and link ~/.vimrc to this repository.
With --nvim, install or upgrade Neovim and link ~/.config/nvim/init.lua.

If the other editor already exists on the system, its config link is refreshed
too. Existing real config files are backed up before links are created.

When this script is run without a cloned repository, it downloads the dotfiles
to DOTFILES_DIR, defaulting to ~/.dotfiles.
EOF
}

mode="vim"
raw_base="${DOTFILES_RAW_BASE:-https://raw.githubusercontent.com/AmbitiousG/dotfiles/main}"
bashrc_path="${HOME}/.bashrc"
bashrc_updated=0
bashrc_block_start="# dotfiles sudo vim helpers start"
bashrc_block_end="# dotfiles sudo vim helpers end"

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

script_path="${BASH_SOURCE[0]:-$0}"
script_dir=""
if [ -n "$script_path" ] && [ -f "$script_path" ]; then
  script_dir="$(cd "$(dirname "$script_path")" && pwd -P)"
fi

download_file() {
  local url="$1"
  local destination="$2"
  local destination_dir
  local tmp

  destination_dir="$(dirname "$destination")"
  mkdir -p "$destination_dir"
  tmp="$(mktemp)"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$tmp"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$tmp" "$url"
  else
    rm -f "$tmp"
    echo "curl or wget is required to download dotfiles without cloning." >&2
    exit 1
  fi

  mv "$tmp" "$destination"
}

bootstrap_dotfiles() {
  local destination="$1"

  echo "Downloading dotfiles to $destination..."
  download_file "$raw_base/.vimrc" "$destination/.vimrc"
  download_file "$raw_base/nvim/init.lua" "$destination/nvim/init.lua"
  download_file "$raw_base/install-debian.sh" "$destination/install-debian.sh"
  download_file "$raw_base/README.md" "$destination/README.md"
  chmod +x "$destination/install-debian.sh"
}

extract_vim_colorscheme() {
  local vimrc_path="$1"
  local scheme

  scheme="$(sed -n 's/^[[:space:]]*colorscheme[[:space:]]\+\([[:alnum:]_-]\+\)[[:space:]]*$/\1/p' "$vimrc_path" | tail -n 1)"
  printf '%s\n' "$scheme"
}

if [ -n "$script_dir" ] && [ -f "$script_dir/.vimrc" ] && [ -f "$script_dir/nvim/init.lua" ]; then
  repo_dir="$script_dir"
else
  repo_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
  bootstrap_dotfiles "$repo_dir"
fi

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

ensure_slate_colorscheme() {
  local colors_dir
  local slate_target
  local slate_url

  colors_dir="$HOME/.vim/colors"
  slate_target="$colors_dir/slate.vim"
  slate_url="https://raw.githubusercontent.com/vim/vim/master/runtime/colors/slate.vim"

  mkdir -p "$colors_dir"
  echo "Installing slate colorscheme compatibility file..."
  download_file "$slate_url" "$slate_target"
}

vim_major_version() {
  local version_line
  local version_value

  if ! command -v vim >/dev/null 2>&1; then
    return 1
  fi

  version_line="$(vim --version 2>/dev/null | sed -n '1p')"
  version_value="$(printf '%s\n' "$version_line" | sed -n 's/.*Vi IMproved \([0-9][0-9]*\)\..*/\1/p')"
  if [ -n "$version_value" ]; then
    printf '%s\n' "$version_value"
    return 0
  fi

  return 1
}

append_line_if_missing() {
  local file_path="$1"
  local line="$2"

  if [ ! -f "$file_path" ]; then
    : > "$file_path"
  fi

  if ! grep -Fqx "$line" "$file_path"; then
    printf '%s\n' "$line" >> "$file_path"
    bashrc_updated=1
  fi
}

ensure_bashrc_block() {
  local file_path="$1"
  local tmp
  local block_tmp

  if [ ! -f "$file_path" ]; then
    : > "$file_path"
  fi

  tmp="$(mktemp)"
  block_tmp="$(mktemp)"
  cat > "$block_tmp" <<EOF

$bashrc_block_start
# Use normal Vim when possible. For protected files, edit a temporary copy as
# the current user and install it back with sudo after Vim exits.
_dotfiles_target_needs_sudo() {
    local target="\$1"
    local target_dir

    case "\$target" in
        --|-*) return 1 ;;
    esac

    target_dir=\$(dirname -- "\$target")
    if [ -e "\$target" ] || [ -L "\$target" ]; then
        [ ! -w "\$target" ] || [ ! -w "\$target_dir" ]
        return \$?
    fi

    [ ! -d "\$target_dir" ] || [ ! -w "\$target_dir" ]
}

_dotfiles_edit_protected_one() {
    local target="\$1"
    local target_dir
    local base
    local tmp
    local before
    local stat_out
    local rest
    local owner
    local group
    local mode
    local vim_status
    local install_status

    if sudo test -L "\$target"; then
        target=\$(sudo readlink -f -- "\$target") || {
            return 1
        }
    fi

    target_dir=\$(dirname -- "\$target")
    base=\$(basename -- "\$target")
    if [ -z "\$base" ] || [ "\$base" = "." ] || [ "\$base" = "/" ]; then
        echo "se: unsupported target: \$target" >&2
        return 2
    fi

    tmp=\$(mktemp --tmpdir "se.XXXXXX.\$base") || return 1
    before="\$tmp.before"

    if sudo test -e "\$target"; then
        stat_out=\$(sudo stat -c '%u %g %a' -- "\$target") || {
            rm -f "\$tmp" "\$before"
            return 1
        }
        owner=\${stat_out%% *}
        rest=\${stat_out#* }
        group=\${rest%% *}
        mode=\${rest##* }
        sudo cp -- "\$target" "\$tmp" || {
            rm -f "\$tmp" "\$before"
            return 1
        }
    else
        if ! sudo test -d "\$target_dir"; then
            sudo mkdir -p -- "\$target_dir" || {
                rm -f "\$tmp" "\$before"
                return 1
            }
        fi
        stat_out=\$(sudo stat -c '%u %g' -- "\$target_dir") || {
            rm -f "\$tmp" "\$before"
            return 1
        }
        owner=\${stat_out%% *}
        group=\${stat_out##* }
        mode=644
        : > "\$tmp"
    fi

    chmod u+rw "\$tmp"
    cp -- "\$tmp" "\$before"
    vim "\$tmp"
    vim_status=\$?
    if [ "\$vim_status" -ne 0 ]; then
        rm -f "\$tmp" "\$before"
        return "\$vim_status"
    fi

    if cmp -s "\$before" "\$tmp"; then
        echo "se: no changes: \$target"
        rm -f "\$tmp" "\$before"
        return 0
    fi

    sudo install -m "\$mode" -o "\$owner" -g "\$group" -- "\$tmp" "\$target"
    install_status=\$?
    rm -f "\$tmp" "\$before"
    if [ "\$install_status" -eq 0 ]; then
        echo "se: wrote: \$target"
    fi
    return "\$install_status"
}

_dotfiles_edit_protected() {
    local target
    local status=0

    if [ "\$#" -eq 0 ]; then
        vim
        return \$?
    fi

    for target in "\$@"; do
        case "\$target" in
            --|-*)
                echo "se: Vim options are only supported for files writable by the current user." >&2
                return 2
                ;;
        esac
    done

    for target in "\$@"; do
        _dotfiles_edit_protected_one "\$target" || status=\$?
    done

    return "\$status"
}

se() {
    local needs_sudo=0
    local target

    if [ "\$#" -eq 0 ]; then
        vim
        return \$?
    fi

    for target in "\$@"; do
        if _dotfiles_target_needs_sudo "\$target"; then
            needs_sudo=1
            break
        fi
    done

    if [ "\$needs_sudo" -eq 1 ]; then
        _dotfiles_edit_protected "\$@"
    else
        vim "\$@"
    fi
}

svim() {
    _dotfiles_edit_protected "\$@"
}
$bashrc_block_end
EOF
  if grep -Fqx "$bashrc_block_start" "$file_path"; then
    awk -v start="$bashrc_block_start" -v end="$bashrc_block_end" '
      $0 == start { skipping = 1; next }
      $0 == end { skipping = 0; next }
      !skipping { print }
    ' "$file_path" > "$tmp"
    cat "$block_tmp" >> "$tmp"
  else
    cat "$file_path" > "$tmp"
    cat "$block_tmp" >> "$tmp"
  fi

  mv "$tmp" "$file_path"
  rm -f "$block_tmp"
  bashrc_updated=1
}

ensure_shell_defaults() {
  append_line_if_missing "$bashrc_path" 'export EDITOR=vim'
  append_line_if_missing "$bashrc_path" 'export VISUAL=vim'
  ensure_bashrc_block "$bashrc_path"
}

vim_colorscheme="$(extract_vim_colorscheme "$vimrc_source")"
ensure_shell_defaults

if [ "$mode" = "nvim" ]; then
  apt_install_or_upgrade neovim
  if [ "$vim_colorscheme" = "slate" ] && command -v vim >/dev/null 2>&1; then
    vim_major="$(vim_major_version || true)"
    if [ -n "$vim_major" ] && [ "$vim_major" -lt 9 ]; then
      ensure_slate_colorscheme
    fi
  fi
  link_nvim
  if command -v vim >/dev/null 2>&1; then
    link_vim
  fi
else
  apt_install_or_upgrade vim
  if [ "$vim_colorscheme" = "slate" ]; then
    vim_major="$(vim_major_version || true)"
    if [ -n "$vim_major" ] && [ "$vim_major" -lt 9 ]; then
      ensure_slate_colorscheme
    fi
  fi
  link_vim
  if command -v nvim >/dev/null 2>&1; then
    link_nvim
  fi
fi

echo "Done."
if [ "$bashrc_updated" -eq 1 ]; then
  echo "Run 'source ~/.bashrc' or open a new shell to pick up EDITOR, VISUAL, se, and svim."
fi
