# Dotfiles

Mijn macOS- en Ubuntu-configuratie, beheerd met GNU Stow. De map `home/`
bevat configuratie die op beide platforms werkt; `macos/` bevat uitsluitend
macOS-configuratie voor Raycast en optionele lokale scripts.

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
tools, WhichSpace en Stow; op Ubuntu de equivalente apt-pakketten,
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
- Kies **Manage apps → Install apps** om de ingestelde apps te installeren.
  Office en iWork hebben een aparte installatiekeuze. **Update apps** toont
  eerst Homebrew- en Mac App Store-updates en vraagt daarna bevestiging;
  **Remove apps** toont alleen apps uit deze configuratie. Log vóór de
  installatie in bij de Mac App Store. Betaalde apps, zoals Caffeinated en
  Pixelmator Pro, moeten aan hetzelfde Apple-account zijn gekoppeld.
- WhichSpace wordt via de core Brewfile geïnstalleerd. Open de app na de installatie en
  zet **Launch at Login** aan. Zet in **Settings → Displays** de weergave van
  Spaces op alle schermen aan. Dan toont de menubalk de Spaces per scherm,
  gescheiden door een verticale lijn. macOS spiegelt dezelfde menubalkindicator
  op alle schermen; er staat dus niet een afzonderlijk nummer op elk scherm.
- Zet in **Systeeminstellingen → Bureaublad en Dock → Mission Control**
  **Rangschik Spaces automatisch op basis van recent gebruik** uit als je vaste
  nummers en sneltoetsen gebruikt. Configureer eventuele sneltoetsen in
  WhichSpace zelf en voorkom overlap met Raycast-sneltoetsen.
- De Citrix Viewer/Caffeinated-automatisering is optioneel. Kies in
  **Manage apps → Install apps → Citrix Viewer / Caffeinated automation** voor installeren,
  status of verwijderen. De achtergrondservice schakelt Caffeinated aan als
  Citrix Viewer start en uit als de laatste Viewer afsluit. Bij beide
  overgangen verschijnt een macOS-melding. Handmatig aan- en uitzetten blijft
  tussendoor mogelijk. Zet in Caffeinated zelf **Keep Awake with Lid Closed**
  aan als je de sessie met gesloten MacBook wilt behouden. De healthcheck
  controleert de service alleen wanneer deze optioneel is geïnstalleerd.
- Docker Desktop staat in **Manage apps → Install apps**. De installatie vraagt
  om je wachtwoord omdat Docker een privileged helper installeert. Tailscale
  wordt via de Mac App Store geïnstalleerd.

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

Op Ubuntu groepeert `./setup.sh` de opties onder **Dotfiles setup**,
**Manage Ubuntu server** en **Manage Docker containers and images**. Onder
server health vind je de algemene controle, de
Matter IPv6-controle en de bestaande IPv6-reparatie. Die reparatie activeert
de netwerkverbinding opnieuw en vraagt daarom eerst bevestiging.

Het Docker-menu toont containers en hun start/stop/logopties. **Check available
image updates** voert op aanvraag `docker pull` uit voor images van actieve of
gestopte containers. Dat haalt images op maar herstart nog niets. Daarna
vergelijkt het menu de image-ID van iedere container met de opgehaalde image.
**Update one** en **Update all** tonen de betrokken containers en vragen
bevestiging voordat Compose de gekozen services opnieuw aanmaakt. Zelfgebouwde
images en onduidelijke gevallen worden overgeslagen. Portainer is op deze
server een losse container en gebruikt een apart script; de oude container
blijft na een geslaagde update als `portainer-before-update` bestaan.
Controleer voor een update zelf de release notes: een nieuwe digest vertelt
niet welke functionele wijzigingen een applicatie bevat.

De overgenomen serverscripts staan in `server-scripts/`. Het schijfcontrole-
script voor Uptime Kuma verwacht `KUMA_DISK_PUSH_URL` in een lokale, niet
ingecheckte `/etc/dotfiles/kuma-disk.env` (eventueel ook `KUMA_DISK_MOUNT` en
`KUMA_DISK_THRESHOLD`). Migratie van een bestaande cronjob naar dit script
vereist die lokale configuratie; de huidige serverjob blijft anders intact.

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

Dit koppelt de Stow-pakketten opnieuw en leest de tmux-configuratie opnieuw
in. Open alleen een nieuw terminalvenster wanneer `.zshrc` is gewijzigd.

Open het centrale menu voor installeren, verwijderen, updaten of herladen met:

```bash
./setup.sh
```

Op Ubuntu kun je dit na de installatie ook vanuit elke map openen met:

```bash
dotfiles
```

Het macOS-hoofdmenu bevat **(Re)install and apply configuration**,
**Manage apps**, **Diagnostics**, **Backup / restore** en **Reload
configuration**. Binnen **Manage apps** staan installeren, bijwerken en
verwijderen. De updateactie haalt eerst de beschikbare Homebrew- en Mac App
Store-updates op, toont ze en vraagt daarna bevestiging. Herladen van de
dotfiles blijft een aparte actie.

Elke actie die software installeert, bijwerkt, Stow opnieuw toepast of het
systeem herstart, vraagt om bevestiging.

Op Ubuntu gebruikt **Update Ubuntu packages (conservative)** `apt-get upgrade --with-new-pkgs`
om ook benodigde nieuwe afhankelijkheden te installeren, maar zonder bestaande
pakketten te verwijderen (`--no-remove`). Package holds en Ubuntu's
gefaseerde uitrol blijven gerespecteerd. Bij fouten tijdens het verversen van een
repository stopt de actie. Er is geen release-upgrade, autoremove of automatische
herstart; updates kunnen wel services herstarten. Dit geldt voor alle ingestelde
APT-repositories, inclusief eventuele externe bronnen, en is geen garantie op
risicoloze updates. Updates die verwijderingen vereisen of door phasing, holds of
dependencyconflicten worden tegengehouden, worden niet geforceerd.
Na afloop toont het menu het aantal en de lijst van resterende updates (of expliciet
nul resterende updates), holds en of een herstart
nodig is. ESM Apps-updates vereisen een actief Ubuntu Pro-recht. Een SSH-loginmelding
over beschikbare updates betekent daarom niet vanzelf dat de update is mislukt.

Kies **Run health check** in het centrale menu om zonder wijzigingen te zien of
de kernonderdelen, services en Stow-configuratie beschikbaar zijn.

Controleer de basisinstallatie eventueel handmatig met:

```bash
brew bundle check --file=Brewfile
```

Gebruik **Manage apps** om alle geconfigureerde apps te installeren, Office en
iWork apart te installeren, updates te bekijken of apps te verwijderen.

## Structuur

```text
Brewfile       Basisformules, taps en macOS-workflow
Brewfile.dev   Optionele development-tools en -apps
Brewfile.personal  Optionele persoonlijke apps
Brewfile.mas   Persoonlijke Mac App Store-apps
Brewfile.office      Microsoft Office-apps via Homebrew
Brewfile.office.mas  Apple iWork- en Microsoft Office-apps uit de App Store
bootstrap.sh   Installatie voor macOS en Ubuntu
setup.sh       Centrale manager voor installatie en configuratie
manage-apps.sh Menu voor installeren, bijwerken en verwijderen van Mac-apps
menu-ui.sh     Gedeelde ASCII-header en schermnavigatie voor menu's
docker-manager.sh  Interactief beheer van Docker-containers op Ubuntu
reload.sh      Pas configuratiewijzigingen toe na git pull
update.sh      Toont en installeert Homebrew- en Mac App Store-updates
health-check.sh  Leesbare controle van de installatie zonder wijzigingen
diagnostics.sh  Health check, service-status en logweergave
install-apps.sh  Installatie van apps en Office/iWork
citrix-caffeinated-manager.sh  Optionele installatie, status en verwijdering
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
macos/         Raycast-configuratie en optionele lokale scripts
```

De installatie gebruikt Stow en stopt bij bestaande, conflicterende bestanden
in je thuismap. Maak die eerst bewust veilig of verplaats ze naar deze
repository; het script overschrijft nooit stilzwijgend persoonlijke
configuratie.
