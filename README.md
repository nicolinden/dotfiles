# Dotfiles

Mijn macOS- en Ubuntu-configuratie, beheerd met GNU Stow. De map `home/`
bevat configuratie die op beide platforms werkt; `macos/` bevat uitsluitend
macOS-configuratie voor AeroSpace en SketchyBar.

## Nieuwe Mac installeren

1. Installeer de Xcode Command Line Tools wanneer macOS daarom vraagt:

   ```bash
   xcode-select --install
   ```

2. Clone deze repository en start de bootstrap:

   ```bash
   git clone https://github.com/nicolinden/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ./bootstrap.sh
   ```

Het script vraagt op macOS eenmaal om het beheerderswachtwoord. Als Homebrew
nog niet aanwezig is, installeert het script dit met de officiële,
non-interactive installer. Daarna worden alle formules, casks, Oh My Zsh en
de symlinks geïnstalleerd. Tijdens lange downloads blijft de Mac wakker.

Na afloop open je een nieuw terminalvenster zodat de nieuwe shellconfiguratie
wordt geladen.

### Handmatige stappen na de installatie

- Log in bij 1Password, Tailscale, WhatsApp, ChatGPT en andere account-apps.
- Geef AeroSpace de gevraagde Accessibility-permissie in macOS.
- Start SketchyBar als het niet automatisch draait: `brew services start sketchybar`.
- Installeer Docker Desktop en Tailscale desgewenst apart met:

  ```bash
  ./install-system-apps.sh
  ```

  Dit keuzemenu vraagt alleen voor de gekozen systeemapps om je wachtwoord.
  Docker en Tailscale staan bewust niet in de unattended bootstrap, omdat ze
  privileged helpers of een macOS-pakket in systeemlocaties plaatsen.

Apps uit de Brewfile komen in `~/Applications`, niet in de systeemmap
`/Applications`. Daardoor hoeft Homebrew voor gewone GUI-apps niet om
beheerdersrechten te vragen. Command Line Tools, macOS-permissies en de twee
bewust handmatige systeemapps kunnen nog wel een systeemdialoog tonen.

## Linux (Ubuntu)

Op Ubuntu installeert hetzelfde script de basispakketten, Starship, Oh My Zsh
en de algemene dotfiles. De macOS-configuratie wordt daar niet gekoppeld.

## Dagelijks onderhoud

Werk alle macOS Homebrew-pakketten en casks bij met:

```bash
./update.sh
```

Controleer of alles uit de Brewfile geïnstalleerd is met:

```bash
brew bundle check --file=Brewfile
```

## Structuur

```text
Brewfile       Homebrew-formules, taps en macOS-apps
bootstrap.sh   Installatie voor macOS en Ubuntu
update.sh      Homebrew-updates voor macOS
install-system-apps.sh  Optionele macOS-apps met systeemcomponenten
home/          Gedeelde shell-, terminal- en editorconfiguratie
macos/         AeroSpace- en SketchyBar-configuratie
```

De installatie gebruikt Stow en stopt bij bestaande, conflicterende bestanden
in je thuismap. Maak die eerst bewust veilig of verplaats ze naar deze
repository; het script overschrijft nooit stilzwijgend persoonlijke
configuratie.
