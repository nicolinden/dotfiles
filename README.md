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
- Calibre staat lokaal op iedere Mac, zodat Kobo via USB en de Calibre-plug-ins
  normaal werken. Kies in de centrale manager **Backup / restore** om één
  Mac als startbibliotheek te uploaden naar `server.nokionline.com`. Daarna
  download je vóór gebruik de nieuwste bibliotheek en upload je hem pas nadat
  Calibre gesloten is. Het menu probeert eerst Tailscale en daarna het lokale
  fallback-adres. Upload vóór je van Mac wisselt en download vóór je op de
  andere Mac werkt. Elke upload maakt op de server eerst een timestamp-back-up
  van de bestaande bibliotheek; alleen de nieuwste drie blijven bewaard.
  Kies eenmalig **SSH key backup and recovery** in de centrale manager om de
  Calibre-sleutel aan te maken en te installeren. Dat menu maakt ook versleutelde `.ssh`
  back-ups op de server. Herstel vervangt na bevestiging `~/.ssh`, maar maakt
  daarvoor altijd eerst een lokale, gecomprimeerde veiligheidskopie.
  Git bevat bewust geen boeken of `metadata.db`.
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
  De core-installatie beheert zowel `sketchybar-app-font` voor app-iconen als
  Apple SF Symbols voor de systeemiconen. De SF Symbols-installer vraagt tijdens
  **(Re)install and apply configuration** eenmalig om het macOS-beheerderswachtwoord.
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

Kies **Install optional Ubuntu tools** in hetzelfde menu om aanvullende tools
te kiezen: GitHub CLI, `jq`, `tree`, `btop`, `htop`, `ncdu`, de actuele
stabiele Neovim-release en `cmatrix` in de aparte categorie **Terminal extras**.
Dit zijn bewuste optionele keuzes; Docker zelf wordt niet automatisch op een
server geïnstalleerd. Op macOS staat `cmatrix` in het optionele
development-profiel. Binnen tmux werkt het daarna als schermvullende screensaver:
automatisch na 15 minuten inactiviteit of handmatig met `Ctrl+A`, gevolgd door
`Shift+M`; een willekeurige toets brengt de bestaande panes terug.

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

Op Ubuntu kun je dit na de installatie ook vanuit elke map openen met:

```bash
dotfiles
```

Het hoofdmenu blijft bewust klein: **(Re)install and apply configuration**
herstelt de basissoftware en past Stow opnieuw toe; **Manage apps** of
**Manage optional tools** bevat de installaties; **Update** werkt software bij;
en **Diagnostics** bevat de health check en logweergave.
Gebruik **Reload configuration after git pull** om dezelfde reload na
bevestiging vanuit het hoofdmenu uit te voeren, zonder apps te installeren of
bij te werken.
Elke actie die software installeert, bijwerkt, Stow opnieuw toepast of het
systeem herstart, toont eerst een korte beschrijving en vraagt om bevestiging.

De update-optie werkt alle geïnstalleerde Homebrew-apps en -tools bij, probeert
updates uit de Mac App Store en voert daarna altijd een configuratie-reload uit.
Gebruik op macOS **Update managed Homebrew packages only** als je uitsluitend
de al geïnstalleerde pakketten uit jouw drie Brewfiles wilt bijwerken.

Kies **Run health check** in het centrale menu om zonder wijzigingen te zien of
de kernonderdelen, services en Stow-configuratie beschikbaar zijn.

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
menu-ui.sh     Gedeelde ASCII-header en schermnavigatie voor menu's
docker-manager.sh  Interactief beheer van Docker-containers op Ubuntu
reload.sh      Pas configuratiewijzigingen toe na git pull
update.sh      Homebrew-updates voor macOS
update-managed-brew.sh  Update alleen geïnstalleerde Brewfile-pakketten
update-menu.sh  Keuze tussen volledige en beheerde macOS-updates
health-check.sh  Leesbare controle van de installatie zonder wijzigingen
diagnostics.sh  Health check, service-status en logweergave
install-apps.sh  Interactief keuzemenu voor app-profielen
calibre-setup.sh  Oude master/client-configuratie voor Calibre Content Server
calibre-backup.sh  Maak een consistente masterbibliotheek-snapshot in iCloud
calibre-sync.sh   Veilige upload/download; eerst Tailscale, daarna lokaal via 10.10.2.2
ssh-key-manager.sh  Calibre-sleutel, versleutelde .ssh-back-ups en veilig herstel
backup-restore-manager.sh  Centrale ingang voor server, SSH, Calibre en Downloads-back-ups
downloads-backup-manager.sh  Losse, gecomprimeerde Downloads-back-ups op de server
install-linux-apps.sh  Interactief keuzemenu voor optionele Ubuntu-tools
uninstall-apps.sh  Interactief menu voor het verwijderen van optionele apps
install-system-apps.sh  Optionele macOS-apps met systeemcomponenten
system-apps.conf  Gedeelde lijst van macOS-apps met systeemcomponenten
install-mac-apps.sh  Persoonlijke Mac App Store-apps
office-installer.sh  Losse installatie van Office-apps uit de App Store
home/          Gedeelde shell-, terminal- en editorconfiguratie
macos/         AeroSpace- en SketchyBar-configuratie
```

De installatie gebruikt Stow en stopt bij bestaande, conflicterende bestanden
in je thuismap. Maak die eerst bewust veilig of verplaats ze naar deze
repository; het script overschrijft nooit stilzwijgend persoonlijke
configuratie.
