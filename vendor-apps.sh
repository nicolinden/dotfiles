#!/usr/bin/env bash

# Vendor installers that are not available as maintained Homebrew casks.
set -euo pipefail
[[ "$(uname -s)" == Darwin ]] || { echo "This script is for macOS only."; exit 1; }
case "${1:-}" in
  razer)
    if [[ "$(uname -m)" != arm64 ]] || (( $(sw_vers -productVersion | cut -d. -f1) < 15 )); then
      echo "Razer Synapse for Mac requires Apple Silicon and macOS 15 or newer."
      exit 1
    fi
    if [[ -d "/Applications/Razer Synapse.app" || -d "/Applications/Razer/Razer Synapse.app" ]]; then
      echo "Razer Synapse is already installed; use its built-in updater."
      exit 0
    fi
    temp_dir="$(mktemp -d)"
    trap 'rm -rf "$temp_dir"' EXIT
    package="$temp_dir/RazerSynapseInstaller.pkg"
    curl --fail --location --proto '=https' --proto-redir '=https' \
      https://dl.razerzone.com/drivers/Synapse4/mac/RazerSynapseInstaller.pkg -o "$package"
    # Reject installers that macOS does not trust. Do not disable Gatekeeper.
    spctl --assess --type install "$package"
    sudo installer -pkg "$package" -target /
    echo "Razer Synapse installed. Complete its first-run setup when prompted."
    ;;
  *) echo "Usage: ./vendor-apps.sh razer"; exit 1 ;;
esac
