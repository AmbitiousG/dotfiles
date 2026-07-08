export EDITOR=vim
export VISUAL=vim

export HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"
HISTSIZE=10000
SAVEHIST=10000

setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY

autoload -Uz compinit
compinit

bindkey -e

if [ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  bindkey '^f' autosuggest-accept
fi

if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
elif command -v fdfind >/dev/null 2>&1; then
  alias fd=fdfind
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git'
fi

export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'

if [ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]; then
  source /usr/share/doc/fzf/examples/key-bindings.zsh
fi

if [ -r /usr/share/doc/fzf/examples/completion.zsh ]; then
  source /usr/share/doc/fzf/examples/completion.zsh
fi

alias ..='cd ..'
alias la='ls -A'
alias ll='ls -alF'
alias dotfiles='cd ~/.dotfiles'
alias dotfiles-apply='~/.dotfiles/install.sh --no-packages'
alias ga='git add'
alias gc='git commit'
alias gl='git pull'
alias gp='git push'
alias gs='git status --short'
alias v='vim'

if command -v lazygit >/dev/null 2>&1; then
  alias lg='lazygit'
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  PROMPT='%n@%m %~ %# '
fi

if [ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
