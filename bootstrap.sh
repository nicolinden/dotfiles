#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "$(uname -s)" in
  Darwin)
    if ! command -v brew >/dev/null 2>&1; then
      echo "Homebrew is nog niet geïnstalleerd."
      echo "Installeer Homebrew eerst via https://brew.sh"
      exit 1
    fi

    echo "Beheerdersrechten voorbereiden..."
    sudo -v

    # Houd sudo alleen tijdens deze installatie beschikbaar
    while true; do
      sudo -n true
      sleep 60
    done 2>/dev/null &
    SUDO_KEEPALIVE_PID=$!

    trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT INT TERM

    echo "Homebrew-pakketten installeren..."
    caffeinate -i brew bundle install --file="$DOTFILES_DIR/Brewfile"
    ;;

  Linux)
    if [[ ! -r /etc/os-release ]]; then
      echo "Deze Linux-distributie wordt nog niet ondersteund."
      exit 1
    fi

    source /etc/os-release

    if [[ "${ID:-}" != "ubuntu" ]]; then
      echo "Alleen Ubuntu wordt momenteel ondersteund."
      exit 1
    fi

    if ! command -v apt-get >/dev/null 2>&1; then
      echo "apt-get is niet beschikbaar."
      exit 1
    fi

    echo "Ubuntu-pakketten installeren..."
    sudo apt-get update
    sudo apt-get install -y \
      curl \
      fzf \
      git \
      ripgrep \
      stow \
      tmux \
      zsh \
      zsh-autosuggestions \
      zsh-syntax-highlighting

    mkdir -p "$HOME/.local/bin"

    if ! command -v starship >/dev/null 2>&1 &&
       [[ ! -x "$HOME/.local/bin/starship" ]]; then
      echo "Starship installeren..."
      curl -sS https://starship.rs/install.sh |
        sh -s -- --yes --bin-dir "$HOME/.local/bin"
    else
      echo "Starship is al geïnstalleerd."
    fi

    if ! command -v nvim >/dev/null 2>&1; then
      echo
      echo "Waarschuwing: Neovim is niet geïnstalleerd."
      echo "Installeer een actuele Neovim 0.12-versie voordat je de configuratie gebruikt."
    fi
    ;;

  *)
    echo "Dit besturingssysteem wordt niet ondersteund."
    exit 1
    ;;
esac

OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"

if [[ ! -d "$OH_MY_ZSH_DIR" ]]; then
  echo "Oh My Zsh installeren..."
  git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$OH_MY_ZSH_DIR"
else
  echo "Oh My Zsh is al geïnstalleerd."
fi

echo "Dotfiles koppelen..."
stow --dir="$DOTFILES_DIR" --target="$HOME" --verbose home

if [[ "$(uname -s)" == "Darwin" ]]; then
  echo "macOS-dotfiles koppelen..."
  stow --dir="$DOTFILES_DIR" --target="$HOME" --verbose macos
fi

echo "Setup voltooid."
