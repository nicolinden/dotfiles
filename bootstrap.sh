#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

start_sudo_keepalive() {
  # Vraag eenmaal om het beheerderswachtwoord. De keepalive voorkomt verdere
  # wachtwoordprompts tijdens de Homebrew-installatie.
  echo "Beheerdersrechten voorbereiden (eenmalig)..."
  sudo -v

  while sudo -n true; do
    sleep 60
  done 2>/dev/null &
  SUDO_KEEPALIVE_PID=$!

  trap 'kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true' EXIT INT TERM
}

configure_homebrew_for_current_shell() {
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  else
    echo "Homebrew is na installatie niet gevonden."
    exit 1
  fi
}

case "$(uname -s)" in
  Darwin)
    # Een bestaande Homebrew-installatie kan na een verse login nog ontbreken
    # in PATH. Activeer de standaardlocatie eerst voor dit script.
    if ! command -v brew >/dev/null 2>&1 &&
       { [[ -x "/opt/homebrew/bin/brew" ]] || [[ -x "/usr/local/bin/brew" ]]; }; then
      configure_homebrew_for_current_shell
    fi

    if ! command -v brew >/dev/null 2>&1; then
      start_sudo_keepalive
      echo "Homebrew installeren..."
      NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
      configure_homebrew_for_current_shell
    fi

    echo "Homebrew-pakketten installeren..."
    # Installeer GUI-apps per gebruiker. Daardoor zijn ze zonder sudo te
    # installeren en blijven ze gescheiden van door macOS beheerde systeemapps.
    mkdir -p "$HOME/Applications"
    HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" \
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

    echo "Beheerdersrechten voorbereiden..."
    sudo -v

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

  # SketchyBar vervangt de native menubalk. Verberg die daarom consequent op
  # alle schermen; SystemUIServer leest deze voorkeur direct opnieuw in.
  defaults write -g _HIHideMenuBar -bool true
  defaults write -g AppleMenuBarVisibleInFullscreen -bool false
  killall SystemUIServer 2>/dev/null || true

  # AeroSpace registreert `start-at-login` pas nadat de app minstens één keer
  # heeft gedraaid. Start hem daarom na het koppelen van de configuratie.
  if [[ -d "$HOME/Applications/AeroSpace.app" ]]; then
    open "$HOME/Applications/AeroSpace.app"
  elif [[ -d "/Applications/AeroSpace.app" ]]; then
    open "/Applications/AeroSpace.app"
  fi

  # SketchyBar is een Homebrew-gebruikersservice. Herstart hem nadat de eigen
  # configuratie is gekoppeld, zodat wijzigingen direct zichtbaar zijn.
  if command -v brew >/dev/null 2>&1 && brew list sketchybar >/dev/null 2>&1; then
    brew services restart felixkratz/formulae/sketchybar
  fi
fi

echo "Setup voltooid."
