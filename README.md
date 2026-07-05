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

The default Vim package is `vim-gtk3`, because Debian's plain `vim` package
may not include `+clipboard`. That lets normal yanks use the system clipboard
through `set clipboard=unnamedplus`.

For a smaller terminal-only install, override the package:

```sh
VIM_PACKAGE=vim ./install-debian.sh
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
