#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CORE_ONLY=false
source "$DOTFILES_DIR/menu-ui.sh"

case "${1:-}" in
  "") ;;
  --core-only) CORE_ONLY=true ;;
  *)
    echo "Usage: ./bootstrap.sh [--core-only]"
    exit 1
    ;;
esac

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

install_lazygit() {
  local architecture lazygit_version temp_dir archive

  case "$(uname -m)" in
    x86_64) architecture="x86_64" ;;
    aarch64|arm64) architecture="arm64" ;;
    *)
      echo "LazyGit architecture is not supported: $(uname -m)"
      return 1
      ;;
  esac

  lazygit_version="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest | sed -nE 's/.*"tag_name": "v?([^"]+)".*/\1/p' | head -n 1)"
  if [[ -z "$lazygit_version" ]]; then
    echo "Could not determine the latest LazyGit version."
    return 1
  fi

  temp_dir="$(mktemp -d)"
  archive="lazygit_${lazygit_version}_Linux_${architecture}.tar.gz"

  echo "LazyGit installeren..."
  curl -fL "https://github.com/jesseduffield/lazygit/releases/download/v${lazygit_version}/${archive}" \
    -o "$temp_dir/$archive"
  tar -xzf "$temp_dir/$archive" -C "$temp_dir" lazygit
  install -m 0755 "$temp_dir/lazygit" "$HOME/.local/bin/lazygit"
  rm -rf "$temp_dir"
}

configure_zsh_as_login_shell() {
  local zsh_path current_shell current_user

  zsh_path="$(command -v zsh)"
  current_user="$(id -un)"
  current_shell="$(getent passwd "$current_user" | cut -d: -f7)"

  if [[ "$current_shell" == "$zsh_path" ]]; then
    echo "Zsh is al de standaard shell."
    return
  fi

  echo "Zsh instellen als standaard shell voor $current_user..."
  sudo chsh -s "$zsh_path" "$current_user"
  echo "De nieuwe shell wordt actief nadat je opnieuw hebt ingelogd."
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
    run_with_progress "Homebrew-pakketten installeren" \
      env HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications" \
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

    configure_zsh_as_login_shell

    mkdir -p "$HOME/.local/bin"

    if ! command -v lazygit >/dev/null 2>&1 &&
       [[ ! -x "$HOME/.local/bin/lazygit" ]]; then
      install_lazygit
    else
      echo "LazyGit is al geïnstalleerd."
    fi

    if ! command -v starship >/dev/null 2>&1 &&
       [[ ! -x "$HOME/.local/bin/starship" ]]; then
      echo "Starship installeren..."
      curl -sS https://starship.rs/install.sh |
        sh -s -- --yes --bin-dir "$HOME/.local/bin"
    else
      echo "Starship is al geïnstalleerd."
    fi

    if ! command -v lazydocker >/dev/null 2>&1 &&
       [[ ! -x "$HOME/.local/bin/lazydocker" ]]; then
      echo "LazyDocker installeren..."
      curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh |
        bash
    else
      echo "LazyDocker is al geïnstalleerd."
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

  # Borders is a separate user service so it remains active after AeroSpace
  # restarts and is automatically restored at the next login.
  if command -v brew >/dev/null 2>&1 && brew list borders >/dev/null 2>&1; then
    brew services restart borders
  fi

  if [[ "$CORE_ONLY" != true ]]; then
    echo
    read -r -p "Optionele app-profielen nu kiezen? [y/N] " install_optional_apps
    case "${install_optional_apps:-}" in
      y|Y|yes|YES|Yes)
        if ! "$DOTFILES_DIR/install-apps.sh"; then
          echo "Niet alle gekozen app-profielen konden worden geïnstalleerd; start ./install-apps.sh later opnieuw."
        fi
        ;;
      *)
        echo "Optionele apps overgeslagen. Start later ./install-apps.sh."
        ;;
    esac
  fi
fi

echo "Setup voltooid."
