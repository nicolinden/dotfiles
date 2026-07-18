PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"
export PATH

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""
plugins=(git)
source "$ZSH/oh-my-zsh.sh"

# Starship prompt
if command -v starship >/dev/null 2>&1; then
	eval "$(starship init zsh)"
fi
