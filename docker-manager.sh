#!/usr/bin/env bash

# Small Docker container manager for machines where Docker is already installed.
set -euo pipefail

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker is not installed."
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "Docker is unavailable. Start the Docker service and ensure your user can access it."
  exit 1
fi

while true; do
  mapfile -t containers < <(docker ps --all --format '{{.ID}}|{{.Names}}|{{.Status}}|{{.Image}}')

  echo
  echo "Docker container manager"
  echo

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
    echo "  b) Back"
    echo
    read -r -p "Choose an action: " action

    case "$action" in
      1) docker start "$id" ;;
      2) docker stop "$id" ;;
      3) docker restart "$id" ;;
      4) docker logs --tail 200 "$id" ;;
      5) docker logs --tail 200 --follow "$id" ;;
      b|B|"") break ;;
      *) echo "Invalid choice." ;;
    esac
  done
done
