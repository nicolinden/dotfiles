#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is nog niet geïnstalleerd."
  echo "Installeer Homebrew eerst via https://brew.sh"
  exit 1
fi

echo "Homebrew-pakketten installeren..."
brew bundle install --file="$DOTFILES_DIR/Brewfile"

OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"

if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
  echo "Oh My Zsh installeren..."
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
else
  echo "Oh My Zsh is al geïnstalleerd."
fi

echo "Dotfiles koppelen..."
stow --dir="$DOTFILES_DIR" --target="$HOME" --verbose home

echo "Setup voltooid."
