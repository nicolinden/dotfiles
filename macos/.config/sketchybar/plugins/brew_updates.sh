#!/usr/bin/env bash

CONFIG_DIR="${CONFIG_DIR:-$HOME/.config/sketchybar}"
source "$CONFIG_DIR/colors.sh"
source "$CONFIG_DIR/plugins/popup_hover.sh"
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

MAX_ITEMS=20
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/Library/Caches}/sketchybar"
CACHE_FILE="$CACHE_DIR/updates.tsv"

color_for_count() {
  local count="$1"

  case "$count" in
    0) printf '%s' "$GREEN" ;;
    [1-9]) printf '%s' "$WHITE" ;;
    [1-2][0-9]) printf '%s' "$YELLOW" ;;
    [3-5][0-9]) printf '%s' "$ORANGE" ;;
    *) printf '%s' "$RED" ;;
  esac
}

render_cache() {
  [[ -s "$CACHE_FILE" ]] || return 1

  local record total brew_count mas_count checked source package installed current
  local index=0 color
  IFS=$'\t' read -r record total brew_count mas_count checked < "$CACHE_FILE"
  [[ "$record" == "META" && "$total" =~ ^[0-9]+$ ]] || return 1

  color="$(color_for_count "$total")"
  SKETCHYBAR_ARGS=(
    --set brew_updates "label=$total" "icon.color=$color"
    --set brew_updates.header "label=Updates · $total  (Homebrew $brew_count · App Store $mas_count${checked:+ · $checked})"
  )

  for index in $(seq 1 "$MAX_ITEMS"); do
    SKETCHYBAR_ARGS+=(--set "brew_updates.$index" drawing=off)
  done
  SKETCHYBAR_ARGS+=(--set brew_updates.more drawing=off)

  index=0
  while IFS=$'\t' read -r source package installed current; do
    [[ -n "$source" ]] || continue
    index=$((index + 1))
    (( index <= MAX_ITEMS )) || break
    SKETCHYBAR_ARGS+=(
      --set "brew_updates.$index"
      drawing=on
      "label=$source · $package  ·  $installed → $current"
    )
  done < <(sed '1d' "$CACHE_FILE")

  if (( total > MAX_ITEMS )); then
    SKETCHYBAR_ARGS+=(
      --set brew_updates.more
      drawing=on
      "label=plus $((total - MAX_ITEMS)) andere updates"
    )
  fi

  sketchybar "${SKETCHYBAR_ARGS[@]}"
}

case "${SENDER:-routine}" in
  mouse.entered)
    popup_hover_enter brew_updates
    exit 0
    ;;
  mouse.exited)
    popup_hover_exit brew_updates
    exit 0
    ;;
  mouse.clicked)
    sketchybar --set brew_updates popup.drawing=toggle
    exit 0
    ;;
  mouse.exited.global)
    sketchybar --set brew_updates popup.drawing=off
    exit 0
    ;;
esac

# Toon na een reload meteen de vorige momentopname. De controles hieronder
# vernieuwen hem daarna; klikken leest uitsluitend SketchyBars bestaande staat.
render_cache || true

if ! command -v brew >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
  sketchybar --set brew_updates label="!" icon.color="$RED" \
             --set brew_updates.header label="Updatecontrole niet beschikbaar"
  exit 0
fi

if ! OUTDATED_JSON="$(HOMEBREW_NO_AUTO_UPDATE=1 /usr/bin/perl -e 'alarm 45; exec @ARGV' \
    "$(command -v brew)" outdated --json=v2 2>/dev/null)" ||
   ! printf '%s' "$OUTDATED_JSON" | jq -e '.formulae and .casks' >/dev/null 2>&1; then
  sketchybar --set brew_updates label="!" icon.color="$RED" \
             --set brew_updates.header label="Updatecontrole mislukt · wordt later opnieuw geprobeerd"
  exit 0
fi

BREW_COUNT="$(printf '%s' "$OUTDATED_JSON" \
  | jq '(.formulae | length) + (.casks | length)')"
MAS_JSON=""
if command -v mas >/dev/null 2>&1; then
  # `mas` kan op een trage App Store-respons blijven wachten. De timeout houdt
  # de uurlijkse SketchyBar-update begrensd zonder een dialoog te openen.
  MAS_JSON="$(/usr/bin/perl -e 'alarm 20; exec @ARGV' \
    "$(command -v mas)" outdated --json 2>/dev/null || true)"
fi
MAS_COUNT="$(printf '%s\n' "$MAS_JSON" | jq -s 'map(select(type == "object")) | length')"
TOTAL=$((BREW_COUNT + MAS_COUNT))
CHECKED="$(date '+%H:%M')"

mkdir -p "$CACHE_DIR"
TEMP_CACHE="$(mktemp "$CACHE_DIR/updates.XXXXXX")" || exit 0
{
  printf 'META\t%s\t%s\t%s\t%s\n' "$TOTAL" "$BREW_COUNT" "$MAS_COUNT" "$CHECKED"
  printf '%s' "$OUTDATED_JSON" | jq -r '
    (.formulae + .casks)[]
    | ["Homebrew", .name, (.installed_versions | join(", ")), .current_version]
    | @tsv
  '
  printf '%s\n' "$MAS_JSON" | jq -sr '
    .[] | select(type == "object")
    | ["App Store", (.displayName // .name), .version, .newVersion]
    | @tsv
  '
} > "$TEMP_CACHE"
mv "$TEMP_CACHE" "$CACHE_FILE"

render_cache
