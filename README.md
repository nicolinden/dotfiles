# Dotfiles

Mijn macOS- en Ubuntu-configuratie, beheerd met GNU Stow. De map `home/`
bevat configuratie die op beide platforms werkt; `macos/` bevat uitsluitend
macOS-configuratie voor AeroSpace en SketchyBar.

## Nieuwe Mac installeren

1. Installeer de Xcode Command Line Tools wanneer macOS daarom vraagt:

   ```bash
   xcode-select --install
   ```

2. Clone deze repository en start de manager:

   ```bash
   git clone https://github.com/nicolinden/dotfiles.git ~/dotfiles
   cd ~/dotfiles
   ./setup.sh
   ```

Het script detecteert macOS of Ubuntu en kiest automatisch de juiste route.
Ontbrekende basissoftware wordt geïnstalleerd: op macOS Homebrew, de core
tools, window-management en Stow; op Ubuntu de equivalente apt-pakketten,
Starship, Oh My Zsh en de gedeelde dotfiles. Daarna opent het een interactief
menu. Tijdens lange downloads blijft de Mac wakker.

Na afloop open je een nieuw terminalvenster zodat de nieuwe shellconfiguratie
wordt geladen.

### Handmatige stappen na de installatie

- Log in bij 1Password, Tailscale, WhatsApp, ChatGPT en andere account-apps.
- Kies in de manager voor optionele app-profielen. Het menu toont per profiel
  hoeveel apps al zijn geïnstalleerd en biedt keuzes voor development,
  persoonlijke apps, Mac App Store, Office/iWork en Docker. Hetzelfde menu
  biedt ook een veilige verwijderlijst met alleen optionele apps en profielen.
  Log vóór een App Store-keuze in bij de Mac App Store. Voor betaalde apps,
  zoals Caffeinated en Pixelmator Pro, moet de app eerst aan hetzelfde
  Apple-account zijn gekoppeld.
- AeroSpace start automatisch na de bootstrap en registreert daarna zijn
  login-item. Geef de gevraagde Accessibility-permissie in macOS.
- Bij twee schermen heeft het hoofdscherm workspaces `1` t/m `6`; het tweede
  scherm heeft `1` t/m `3`. Focus eerst het gewenste scherm met `⌥.` en kies
  daarna het gewenste nummer. Verplaats de gefocuste app naar het gekozen
  nummer op het actieve scherm met `⌥⇧1`–`⌥⇧6`; op het tweede scherm hebben
  `4`–`6` bewust geen effect. `⌥⇧.` verplaatst een app naar het andere scherm
  en volgt hem.
  De standaard appindeling komt op het hoofdscherm terecht. SketchyBar toont
  de actieve app uitsluitend op het scherm dat op dat moment focus heeft.

  | Toets | Actie |
  | --- | --- |
  | `⌥H/J/K/L` | Focus venster links/onder/boven/rechts |
  | `⌥⇧H/J/K/L` | Verplaats venster links/onder/boven/rechts |
  | `⌥.` | Focus volgend scherm |
  | `⌥⇧.` | Verplaats app naar volgend scherm en volg hem |
  | `⌥1`–`⌥6` | Open workspace op het gefocuste scherm (op scherm twee: 1–3) |
  | `⌥⇧1`–`⌥⇧6` | Verplaats app naar workspace (op scherm twee: 1–3) |
  | `⌥M` | Maximaliseer/herstel venster |
  | `⌥⇧Spatie` | Toggle floating/tiling |
  | `⌃⌥Spatie` | Wissel tussen SketchyBar en de native macOS-menubalk |
- SketchyBar wordt na de bootstrap als gebruikersservice gestart, komt bij
  iedere volgende login automatisch terug en wordt op alle aangesloten
  schermen getoond. De bootstrap verbergt hiervoor ook de native macOS-menubalk
  automatisch. SketchyBar tekent bovendien boven de native balk, zodat er geen
  dubbele of versprongen balken ontstaan wanneer macOS die tijdelijk toont.
  Elke aangesloten monitor markeert daarbij zijn eigen zichtbare
  AeroSpace-workspace.
  Druk `⌃⌥Spatie` om SketchyBar tijdelijk te verbergen en de native menubalk te
  gebruiken; druk opnieuw om SketchyBar terug te zetten.
- Installeer Docker Desktop desgewenst apart met:

  ```bash
  ./install-system-apps.sh
  ```

  Dit keuzemenu vraagt alleen voor Docker om je wachtwoord. Docker staat bewust
  niet in de unattended bootstrap, omdat het privileged helpers in
  systeemlocaties plaatst. Tailscale komt via de Mac App Store.

- Installeer Apple iWork en Microsoft Office los, nadat je bij de Mac App Store
  bent ingelogd:

  ```bash
  ./office-installer.sh
  ```

  Dit installeert Numbers, Keynote, Pages, Excel, Outlook, Word en PowerPoint.
  Een Microsoft 365-licentie of -account kan daarna nog nodig zijn om de
  Microsoft-apps te gebruiken.

Apps uit de Brewfiles komen in `~/Applications`, niet in de systeemmap
`/Applications`. Daardoor hoeft Homebrew voor gewone GUI-apps niet om
beheerdersrechten te vragen. Command Line Tools, macOS-permissies en de twee
bewust handmatige systeemapps kunnen nog wel een systeemdialoog tonen.

## Linux (Ubuntu)

Op Ubuntu installeert hetzelfde script de basispakketten, Starship, Oh My Zsh
en de algemene dotfiles. De macOS-configuratie wordt daar niet gekoppeld.
LazyGit en LazyDocker worden daarbij ook geïnstalleerd.

Wanneer Docker al op de Ubuntu-machine aanwezig is, verschijnt in `./setup.sh`
de optie **Manage Docker containers**. Daarmee kun je containers starten,
stoppen, herstarten en logs bekijken; lokale images zijn vanuit hetzelfde menu
op te vragen.

## Dagelijks onderhoud

Na een `git pull` hoef je bootstrap niet opnieuw te draaien. Pas alleen de
nieuwe configuratie direct toe met:

```bash
./reload.sh
```

Dit koppelt de Stow-pakketten opnieuw, herlaadt AeroSpace, SketchyBar en de
vensterborder, en leest de tmux-configuratie opnieuw in. Open alleen een nieuw
terminalvenster wanneer `.zshrc` is gewijzigd.

Open het centrale menu voor installeren, verwijderen, updaten of herladen met:

```bash
./setup.sh
```

De update-optie werkt alle geïnstalleerde Homebrew-apps en -tools bij, probeert
updates uit de Mac App Store en voert daarna altijd een configuratie-reload uit.

Controleer de basisinstallatie eventueel handmatig met:

```bash
brew bundle check --file=Brewfile
```

Start `./install-apps.sh` om aanvullende development-, persoonlijke, App Store-
of Office-apps te kiezen.

## Structuur

```text
Brewfile       Basisformules, taps en macOS-workflow
Brewfile.dev   Optionele development-tools en -apps
Brewfile.personal  Optionele persoonlijke apps
Brewfile.mas   Persoonlijke Mac App Store-apps
Brewfile.office.mas  Apple iWork- en Microsoft Office-apps
bootstrap.sh   Installatie voor macOS en Ubuntu
setup.sh       Centrale manager voor installatie, verwijderen en updates
docker-manager.sh  Interactief beheer van Docker-containers op Ubuntu
reload.sh      Pas configuratiewijzigingen toe na git pull
update.sh      Homebrew-updates voor macOS
install-apps.sh  Interactief keuzemenu voor app-profielen
uninstall-apps.sh  Interactief menu voor het verwijderen van optionele apps
install-system-apps.sh  Optionele macOS-apps met systeemcomponenten
install-mac-apps.sh  Persoonlijke Mac App Store-apps
office-installer.sh  Losse installatie van Office-apps uit de App Store
home/          Gedeelde shell-, terminal- en editorconfiguratie
macos/         AeroSpace- en SketchyBar-configuratie
```

De installatie gebruikt Stow en stopt bij bestaande, conflicterende bestanden
in je thuismap. Maak die eerst bewust veilig of verplaats ze naar deze
repository; het script overschrijft nooit stilzwijgend persoonlijke
configuratie.
