#!/usr/bin/env bash

# Read-only health check for the dotfiles setup.
set -u

failures=0
warnings=0

ok() { printf '  ✓ %s\n' "$1"; }
warn() { printf '  ! %s\n' "$1"; warnings=$((warnings + 1)); }
missing() { printf '  ✗ %s\n' "$1"; failures=$((failures + 1)); }

check_command() {
  local command_name="$1" label="${2:-$1}"
  if command -v "$command_name" >/dev/null 2>&1; then
    ok "$label"
  else
    missing "$label is missing"
  fi
}

check_file() {
  local file="$1" label="$2"
  if [[ -e "$file" ]]; then
    ok "$label"
  else
    missing "$label is missing"
  fi
}

case "$(uname -s)" in
  Darwin)
    echo "macOS dotfiles health check"
    echo
    check_command brew "Homebrew"
    check_command stow "GNU Stow"
    check_command aerospace "AeroSpace"
    check_command sketchybar "SketchyBar"
    check_command borders "Borders"
    check_command skhd "Global hotkey helper (skhd)"
    check_file "$HOME/.config/aerospace/aerospace.toml" "AeroSpace configuration"
    check_file "$HOME/.config/sketchybar/sketchybarrc" "SketchyBar configuration"
    check_file "$HOME/.config/skhd/skhdrc" "Global hotkey configuration"

    skhd_bin=""
    if [[ -x "/Applications/skhd.app/Contents/MacOS/skhd" ]]; then
      skhd_bin="/Applications/skhd.app/Contents/MacOS/skhd"
    elif command -v skhd >/dev/null 2>&1; then
      skhd_bin="$(command -v skhd)"
    fi

    if [[ -n "$skhd_bin" ]]; then
      skhd_status="$("$skhd_bin" --status 2>&1 || true)"
      if grep -q 'Hotkeys functional:[[:space:]]*Yes' <<<"$skhd_status"; then
        ok "Global hotkeys are functional; no skhd action is needed"
      elif grep -q 'Service installed:[[:space:]]*No' <<<"$skhd_status"; then
        warn "skhd service is not installed; run ./reload.sh"
      elif grep -q 'Daemon running:[[:space:]]*No' <<<"$skhd_status"; then
        warn "skhd daemon is not running; run ./reload.sh"
      elif grep -qi 'Accessibility.*denied' <<<"$skhd_status"; then
        warn "skhd needs permission in Privacy & Security → Accessibility"
      elif grep -qi 'Input Monitoring:[[:space:]]*Denied' <<<"$skhd_status"; then
        warn "skhd needs permission in Privacy & Security → Input Monitoring"
      else
        warn "Global hotkeys are not functional; choose Diagnostics option 5 for details"
      fi
    fi

    if command -v docker >/dev/null 2>&1; then
      if docker info >/dev/null 2>&1; then
        ok "Docker is reachable"
      else
        warn "Docker is installed but unavailable"
      fi
    else
      warn "Docker Desktop is not installed"
    fi

    if command -v brew >/dev/null 2>&1; then
      if brew services list 2>/dev/null | awk '$1 == "sketchybar" && $2 == "started" { found = 1 } END { exit !found }'; then
        ok "SketchyBar service is running"
      else
        warn "SketchyBar service is not running (run ./reload.sh)"
      fi

      if brew services list 2>/dev/null | awk '$1 == "borders" && $2 == "started" { found = 1 } END { exit !found }'; then
        ok "Borders service is running"
      else
        warn "Borders service is not running (run ./reload.sh)"
      fi
    fi

    ;;

  Linux)
    echo "Ubuntu dotfiles health check"
    echo
    check_command git "Git"
    check_command stow "GNU Stow"
    check_command fzf "fzf"
    check_command starship "Starship"
    check_command lazygit "LazyGit"
    check_command lazydocker "LazyDocker"
    check_file "$HOME/.zshrc" "Zsh configuration"
    check_file "$HOME/.local/bin/dotfiles" "Global dotfiles command"

    if [[ -f /var/run/reboot-required ]]; then
      warn "System restart is required"
    else
      ok "No restart is pending"
    fi

    if command -v docker >/dev/null 2>&1; then
      if docker info >/dev/null 2>&1; then
        ok "Docker is reachable"
      else
        warn "Docker is installed but unavailable to this user"
      fi
    else
      warn "Docker is not installed"
    fi
    ;;

  *)
    echo "Unsupported operating system."
    exit 1
    ;;
esac

echo
if (( failures > 0 )); then
  echo "Health check found $failures required item(s) to fix."
elif (( warnings > 0 )); then
  echo "Health check complete with $warnings warning(s)."
else
  echo "Health check complete; no action is needed."
fi
