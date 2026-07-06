# dotfiles

Personal Vim and Neovim configuration.

## Files

- `.vimrc`: Vimscript version of the Neovim settings.
- `nvim/init.lua`: Neovim Lua configuration.
- `install-debian.sh`: Debian bootstrap script for linking the configs.

## Debian setup

One-line install without cloning:

```sh
curl -fsSL https://raw.githubusercontent.com/AmbitiousG/dotfiles/main/install-debian.sh | bash
```

Or with `wget`:

```sh
wget -qO- https://raw.githubusercontent.com/AmbitiousG/dotfiles/main/install-debian.sh | bash
```

For Neovim without cloning:

```sh
curl -fsSL https://raw.githubusercontent.com/AmbitiousG/dotfiles/main/install-debian.sh | bash -s -- --nvim
```

The no-clone path stores the downloaded files in `~/.dotfiles`. Override that
with `DOTFILES_DIR=/path/to/dotfiles`.

## Clone setup

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

The script also:

- Installs `~/.vim/colors/slate.vim` when your `.vimrc` uses `colorscheme slate`,
  but only on Vim versions older than 9, overriding the built-in older copy so
  Vim 8 can use the newer `slate` variant too.
- Ensures `~/.bashrc` contains `export EDITOR=vim`, `export VISUAL=vim`, and
  `alias svim='sudoedit'` so sudo-based editing still uses your Vim config.
- Backs up existing config files before replacing them with symlinks.
