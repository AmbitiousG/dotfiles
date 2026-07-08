# dotfiles

Lightweight Debian VPS dotfiles managed with GNU Stow.

## What this manages

- `zsh` with completion, autosuggestions, syntax highlighting, fzf integration, and aliases
- `vim` with a small no-plugin config
- `tmux` for persistent SSH sessions
- `starship` prompt config
- `git` defaults

System-level VPS hardening stays outside this repo. Use cloud-init or Ansible for SSH, firewall, fail2ban, Docker, systemd services, users, and sudo policy.

## Layout

Each top-level tool directory is a Stow package:

- `zsh/.zshrc` -> `~/.zshrc`
- `vim/.vimrc` -> `~/.vimrc`
- `tmux/.tmux.conf` -> `~/.tmux.conf`
- `starship/.config/starship.toml` -> `~/.config/starship.toml`
- `git/.config/git/config` -> `~/.config/git/config`

## First use on Debian

On a fresh Debian VPS, install the minimal bootstrap tools first:

```sh
apt-get update
apt-get install -y ca-certificates curl git
git clone https://github.com/AmbitiousG/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

If `git` is already available, clone the repo, then run:

```sh
cd dotfiles
./install.sh
```

`install.sh` installs common Debian packages with apt when available, installs Starship from apt or the official installer when apt does not provide it, links this repo to `~/.dotfiles`, and runs Stow for every package.

To also change your login shell to zsh:

```sh
./install.sh --chsh
```

`--chsh` only changes the login shell. It runs directly as root, or uses passwordless `sudo usermod` for non-root users. If passwordless sudo is not available, it prints a warning and skips the shell change instead of prompting for a password. The zsh prompt, fzf integration, autosuggestions, syntax highlighting, and aliases are loaded by the linked `~/.zshrc` when their commands or package files are available.

To change the login shell later:

```sh
sudo usermod -s "$(command -v zsh)" "$USER"
```

If packages are already installed and you only want to relink dotfiles:

```sh
./install.sh --no-packages
```

## Daily use

Edit files in this repo, then relink:

```sh
./install.sh --no-packages
```

If Stow reports a conflict, move the existing target file out of the way first, then rerun the command. This is intentional so existing manual config is not overwritten silently.
