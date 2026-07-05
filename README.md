# dotfiles

Personal Vim and Neovim configuration.

## Files

- `.vimrc`: Vimscript version of the Neovim settings.
- `nvim/init.lua`: Neovim Lua configuration.
- `install-debian.sh`: Debian bootstrap script for linking the configs.

## Debian setup

Clone this repository on a new Debian machine, then run:

```sh
cd dotfiles
chmod +x install-debian.sh
./install-debian.sh
```

To install or upgrade Neovim and link the Neovim config:

```sh
./install-debian.sh --nvim
```

After future dotfile updates:

```sh
git pull
./install-debian.sh
```

The script backs up existing config files before replacing them with symlinks.
