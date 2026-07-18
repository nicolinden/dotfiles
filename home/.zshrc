# WezTerm CLI on macOS
if [[ -d "/Applications/WezTerm.app/Contents/MacOS" ]]; then
  export PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"
fi

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)

if [[ -r "$ZSH/oh-my-zsh.sh" ]]; then
  source "$ZSH/oh-my-zsh.sh"
fi

# Fuzzy history and file search
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# Command suggestions from shell history
if command -v brew >/dev/null 2>&1; then
  source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
elif [[ -r "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  source "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Starship prompt
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Syntax highlighting must be loaded last
if command -v brew >/dev/null 2>&1; then
  source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
elif [[ -r "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  source "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
