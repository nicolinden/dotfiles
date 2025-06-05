#!/bin/bash

# Raycast metadata
# @raycast.schemaVersion 1
# @raycast.title Chrome Profiel Keuze (met SwiftDialog)
# @raycast.mode silent
# @raycast.packageName Chrome Tools
# @raycast.icon 🧑‍💻

# Profielen mapping
declare -A profiles=(
  ["Persoonlijk"]="Default"
  ["Werk"]="Profile 1"
  ["Test"]="Profile 2"
)

# Toon dialog met selectielijst
selected=$(dialog \
  --title "Kies een Chrome-profiel" \
  --message "Welk profiel wil je openen?" \
  --selecttitle "Profiel" \
  --select "Persoonlijk=Persoonlijk" "Werk=Werk" "Test=Test" \
  --button1text "Open" \
  --button2text "Annuleer" \
  --icon SF=person.circle \
  --moveable \
  --height 200 \
  --json | grep -o '"selectResult":"[^"]*"' | cut -d':' -f2 | tr -d '"')

# Als niets gekozen of geannuleerd
if [ -z "$selected" ]; then
  exit 0
fi

# Koppel naam aan map
profileDir="${profiles[$selected]}"

# Start Chrome met gekozen profiel
open -na "Google Chrome" --args --profile-directory="$profileDir"

# bartreardon
#  https://github.com/bartreardon/swiftDialog/releases/latest