#!/usr/bin/env bash

# Small Docker container manager for machines where Docker is already installed.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$DOTFILES_DIR/menu-ui.sh"

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker is unavailable. Start the Docker service and ensure your user can access it."
  exit 1
fi

while true; do
  # macOS ships Bash 3.2, which does not support `mapfile`.
  containers=()
  while IFS= read -r container; do
    containers+=("$container")
  done < <(docker ps --all --format '{{.ID}}|{{.Names}}|{{.Status}}|{{.Image}}')

  print_menu_header "Docker container manager"

  if [[ ${#containers[@]} -eq 0 ]]; then
    echo "No containers found."
  else
    for index in "${!containers[@]}"; do
      IFS='|' read -r id name status image <<< "${containers[$index]}"
      printf '  %d) %s — %s (%s)\n' "$((index + 1))" "$name" "$status" "$image"
    done
  fi

  echo
  echo "  i) List local images"
  echo "  q) Back"
  echo
  read -r -p "Choose a container: " choice

  case "$choice" in
    q|Q|"") exit 0 ;;
    i|I)
      echo
      docker image ls
      wait_for_menu_return
      continue
      ;;
  esac

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#containers[@]} )); then
    echo "Invalid choice."
    continue
  fi

  IFS='|' read -r id name status image <<< "${containers[$((choice - 1))]}"

  while true; do
    echo
    echo "Container: $name"
    echo "  1) Start"
    echo "  2) Stop"
    echo "  3) Restart"
    echo "  4) Show last 200 log lines"
    echo "  5) Follow logs (press Ctrl-C to return)"
    if command -v lazydocker >/dev/null 2>&1; then
      echo "  6) Open LazyDocker"
    fi
    echo "  b) Back"
    echo
    read -r -p "Choose an action: " action

    case "$action" in
      1) docker start "$id" ;;
      2) docker stop "$id" ;;
      3) docker restart "$id" ;;
      4) docker logs --tail 200 "$id" ;;
      5)
        # Ctrl-C deliberately stops only `docker logs`; return to this menu.
        docker logs --tail 200 --follow "$id" || true
        ;;
      6)
        if command -v lazydocker >/dev/null 2>&1; then
          lazydocker
        else
          echo "LazyDocker is not installed. Choose core tooling reinstall to install it."
        fi
        ;;
      b|B|"") break ;;
      *) echo "Invalid choice." ;;
    esac

    if [[ "$action" != "b" && "$action" != "B" && -n "$action" ]]; then
      wait_for_menu_return
    fi
  done
done
