#!/usr/bin/env bash
set -euo pipefail

if [[ "$(docker inspect -f '{{.State.Running}}' nginx)" == true ]]; then
  echo "nginx draait al."
else
  docker start nginx
fi
