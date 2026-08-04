#!/usr/bin/env bash

# Install optional Ubuntu tools without turning a server into a desktop setup.
set -euo pipefail

if [[ "$(uname -s)" != "Linux" ]] || ! command -v apt-get >/dev/null 2>&1; then
  echo "This script supports Ubuntu only."
  exit 1
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"

DEVELOPER_PACKAGES=(gh jq tree)
MONITORING_PACKAGES=(btop htop ncdu)
TERMINAL_EXTRA_PACKAGES=(cmatrix)
NEOVIM_LABEL="Current stable Neovim from the official release"

join_items() {
  local separator="" item
  for item in "$@"; do
    printf '%s%s' "$separator" "$item"
    separator=", "
  done
}

install_apt_packages() {
  sudo apt-get update
  sudo apt-get install -y "$@"
}

install_neovim() {
  local architecture asset temp_dir

  case "$(uname -m)" in
    x86_64) architecture="x86_64" ;;
    aarch64|arm64) architecture="arm64" ;;
    *)
      echo "Unsupported Neovim architecture: $(uname -m)"
      return 1
      ;;
  esac

  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN

  asset="nvim-linux-$architecture.tar.gz"
  echo "Installing the current stable Neovim release..."
  curl -fL "https://github.com/neovim/neovim-releases/releases/download/stable/$asset" \
    -o "$temp_dir/$asset"
  tar -xzf "$temp_dir/$asset" -C "$temp_dir"

  mkdir -p "$HOME/.local/share" "$HOME/.local/bin"
  rm -rf "$HOME/.local/share/nvim"
  mv "$temp_dir/nvim-linux-$architecture" "$HOME/.local/share/nvim"
  ln -sfn "$HOME/.local/share/nvim/bin/nvim" "$HOME/.local/bin/nvim"
}

print_menu_header "Optional Ubuntu tools"
echo "  1) Developer CLI"
echo "  2) Monitoring and disk usage"
echo "  3) Neovim"
echo "  4) Terminal extras"
echo "  a) Install everything"
echo "  q) Quit"
echo
read -r -p "Choose one or more numbers (for example 1 2), a or q: " selection

case "$selection" in
  q|Q|"") exit 0 ;;
  a|A) selected=(1 2 3 4) ;;
  *) IFS=', ' read -r -a selected <<< "$selection" ;;
esac

for choice in "${selected[@]}"; do
  if ! [[ "$choice" =~ ^[1-4]$ ]]; then
    echo "Invalid choice: $choice"
    exit 1
  fi
done

echo
echo "This will install or update:"
for choice in "${selected[@]}"; do
  case "$choice" in
    1) printf '  - %s\n' "$(join_items "${DEVELOPER_PACKAGES[@]}")" ;;
    2) printf '  - %s\n' "$(join_items "${MONITORING_PACKAGES[@]}")" ;;
    3) printf '  - %s\n' "$NEOVIM_LABEL" ;;
    4) printf '  - %s\n' "$(join_items "${TERMINAL_EXTRA_PACKAGES[@]}")" ;;
  esac
done

if ! confirm_action "Install selected Ubuntu tools?"; then
  echo "Cancelled."
  exit "$MENU_CANCELLED"
fi

for choice in "${selected[@]}"; do
  case "$choice" in
    1) install_apt_packages "${DEVELOPER_PACKAGES[@]}" ;;
    2) install_apt_packages "${MONITORING_PACKAGES[@]}" ;;
    3) install_neovim ;;
    4) install_apt_packages "${TERMINAL_EXTRA_PACKAGES[@]}" ;;
  esac
done

echo "Selected Ubuntu tools have been processed. Open a new terminal if Neovim was installed."
wait_for_menu_return
