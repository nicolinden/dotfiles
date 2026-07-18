PATH="$PATH:/Applications/WezTerm.app/Contents/MacOS"
export PATH

# prompt
if command -v starship >/dev/null 2>&1; then
	eval "$(starship init zsh)"
fi
