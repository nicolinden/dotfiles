#!/usr/bin/env bash
set -euo pipefail

# De huidige Portainer-installatie is een losse Docker-container, geen Compose-service.
# De image moet vooraf met docker pull zijn opgehaald en in het menu zijn beoordeeld.
[[ "$(docker inspect -f '{{.Config.Image}}' portainer)" == portainer/portainer-ce:latest ]] || {
  echo "Onverwachte Portainer-image; update via Portainer zelf." >&2
  exit 1
}
old_id="$(docker inspect -f '{{.Image}}' portainer)"
new_id="$(docker image inspect -f '{{.Id}}' portainer/portainer-ce:latest)"
[[ "$old_id" != "$new_id" ]] || { echo "Portainer is al actueel."; exit 0; }
if docker container inspect portainer-before-update >/dev/null 2>&1; then
  echo "Er staat nog een Portainer-back-upcontainer. Controleer die eerst; update afgebroken." >&2
  exit 1
fi

renamed=false
complete=false
restore_old() {
  [[ "$complete" == true ]] && return
  if [[ "$renamed" == true ]]; then
    docker rm -f portainer >/dev/null 2>&1 || true
    docker rename portainer-before-update portainer
  fi
  docker start portainer >/dev/null 2>&1 || true
}
trap restore_old EXIT
docker stop portainer
docker rename portainer portainer-before-update
renamed=true
docker run -d \
  --name portainer --restart unless-stopped --network proxy \
  -p 9000:9000 -p 9443:9443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /srv/docker/infra/portainer/data:/data \
  portainer/portainer-ce:latest
sleep 5
if [[ "$(docker inspect -f '{{.State.Running}}' portainer)" != true ]]; then
  echo "Portainer startte niet; oude container wordt hersteld." >&2
  exit 1
fi
complete=true
trap - EXIT
echo "Portainer draait met de nieuwe image. Oude container blijft als portainer-before-update voor handmatig herstel."
