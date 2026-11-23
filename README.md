# Dotfiles

Mijn macOS- en Ubuntu-configuratie, beheerd met GNU Stow. De map `home/`
bevat configuratie die op beide platforms werkt; `macos/` bevat uitsluitend
optionele lokale macOS-scripts.

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

Het script detecteert macOS of Ubuntu. Op macOS opent `./setup.sh` direct het
menu, zonder apps te installeren of bij te werken. Kies op een nieuwe Mac eerst
**1) (Re)install and apply configuration** voor Homebrew, de core tools, Codex CLI,
WhichSpace, Stow en de dotfiles. Aanvullende apps kies je daarna via **Manage
apps → Install apps**. Op Ubuntu worden ontbrekende basispakketten automatisch
geïnstalleerd voordat het menu verschijnt. Tijdens lange downloads blijft de Mac
wakker.

Na afloop open je een nieuw terminalvenster zodat de nieuwe shellconfiguratie
wordt geladen.

### Handmatige stappen na de installatie

De actuele desktop-app met Codex heet in Homebrew `chatgpt`; dit is de nieuwe
gecombineerde app met Codex, Chat en Work. `codex-app` is uitgefaseerd en wordt
niet geïnstalleerd. ChatGPT Classic is een andere app en wordt ook niet
geïnstalleerd. Kies na aanmelden desgewenst Codex als standaardweergave en het
Codex-appicoon. Zie [de officiële uitleg over de nieuwe desktop-app](https://help.openai.com/en/articles/20001276-moving-to-the-new-chatgpt-desktop-app).

- Log in bij 1Password, Tailscale, WhatsApp, Codex en andere account-apps.
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
  Kies pakketten: **1 Basis**, **2 Werk**, **3 Persoonlijk** en
  **4 Development/design**. Basis bevat dagelijkse apps, Codex CLI, Tailscale en Razer.
  Persoonlijk bevat Calibre, DaisyDisk, iWork, Goodnotes, Pixelmator Pro en The
  Unarchiver. Figma en Sketch horen bij Development/design. Je hoeft niet per app
  te kiezen: voer bijvoorbeeld `1 3 4` in en bevestig één keer om die pakketten
  samen te installeren. Elk pakket slaat bestaande apps over; updates blijven
  apart. Alleen `2` opent het werkmenu met een keuze per app of alle werkapps
  tegelijk. Wanneer je `2` met andere pakketnummers combineert, worden alle
  werkapps meegenomen. Er is geen aparte algemene alles-installerenkeuze. **Update apps** toont
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
  **Manage apps → Install apps → Work apps → c) Citrix / Caffeinated automation** voor installeren,
  status of verwijderen. De achtergrondservice schakelt Caffeinated aan als
  Citrix Viewer start en uit als de laatste Viewer afsluit. Bij beide
  overgangen verschijnt een macOS-melding. Handmatig aan- en uitzetten blijft
  tussendoor mogelijk. Zet in Caffeinated zelf **Keep Awake with Lid Closed**
  aan als je de sessie met gesloten MacBook wilt behouden. De healthcheck
  controleert de service alleen wanneer deze optioneel is geïnstalleerd.
- Basis installeert Tailscale via de Mac App Store. Log vooraf in bij de
  App Store; na installatie moet je Tailscale aanmelden en de VPN-configuratie
  toestaan. Ook de App Store-versie kan een macOS-sleutelhanger- of
  toestemmingsmelding geven. Een bestaande Tailscale-installatie wordt
  overgeslagen, ook als het de zelfstandige versie is. De scripts wisselen
  bestaande varianten niet automatisch om. Installeer beide varianten niet
  naast elkaar. Zie [de varianten van Tailscale](https://tailscale.com/docs/concepts/macos-variants).
- **Install apps → Work apps** toont Outlook, Word, Excel, PowerPoint, Teams,
  DisplayLink Manager, Citrix Workspace, Okta Verify, Docker Desktop, Wacom en
  Caffeinated. Kies één nummer, meerdere
  nummers of **a** voor alle werkapps. Een Microsoft 365-account of -licentie
  kan nodig zijn. DisplayLink heeft toestemming voor schermopname nodig en kan
  om een herstart vragen. VMware Fusion is bewust niet opgenomen.
- Razer Synapse komt bij de standaardapps, via de officiële, door macOS
  gecontroleerde installer voor Apple Silicon en macOS 15 of hoger. Voltooi
  eventuele eerste-startvragen en gebruik daarna de eigen updater van Razer.
  Docker, Wacom, Citrix en Caffeinated zijn optionele werkapps en worden niet
  meegenomen met **1 Basis**.

Alle gewone apps worden in `/Applications` geïnstalleerd. Homebrew zelf draait
als gewone gebruiker; alleen macOS of een installer kan waar nodig om je
beheerderswachtwoord vragen. Toestemmingen, aanmeldingen en App Store-aankopen
kunnen niet volledig automatisch worden afgehandeld.

### Bestaande Mac opschonen

Onder **Diagnostics** staan ook de controle- en verplaatsopties:

- **Review / remove apps outside the install profiles** vergelijkt apps in `/Applications`
  en `~/Applications` en lokale Homebrew-installatiegegevens met alle profielen,
  inclusief optionele werkapps. Ingebouwde Apple-apps en automatisch geïnstalleerde
  Homebrew-afhankelijkheden worden overgeslagen. De lijst meet geen daadwerkelijk appgebruik. Kies nummers om ongewenste
  onderdelen te verwijderen; pas na een afzonderlijke bevestiging gebeurt er
  iets. Homebrew-apps en tools worden zonder `--zap` verwijderd; overige apps
  gaan naar de prullenmand. Voorkeuren en documenten blijven staan. Alleen
  kijken kan met `./audit-apps.sh` (zonder `--manage`).
- Het losse script `./cleanup-retired-apps.sh` verwijdert
  AeroSpace, Borders, SketchyBar, skhd, het SketchyBar-lettertype,
  `switchaudio-osx` en Proton Pass voor zover die via Homebrew zijn geïnstalleerd.
  Deze eenmalige opruimactie staat niet in het blijvende menu. Oude configuratie wordt naar `~/.local/share/dotfiles-backups/retired.*`
  verplaatst. Appgegevens worden niet gewist met `--zap`. Verwijder een eventueel
  oud Toggle AeroSpace-sneltoetscommando ook uit Raycast.
- **Move home-folder apps to /Applications** zet bestaande apps over.
  Homebrew-apps worden opnieuw geïnstalleerd zodat ook de installatiegegevens
  en commandoreferenties kloppen. Overige appbundels worden verplaatst. Bestaande
  bestemmingen worden nooit overschreven; dubbele exemplaren worden gemeld en
  moeten eerst afzonderlijk worden opgelost. Sluit de betrokken apps vooraf.
  Ruim eerst de uitgefaseerde apps op. Een overzicht zonder wijzigingen krijg je
  ook met `./migrate-apps.sh --dry-run`.

De screenshots bevatten daarnaast Draw Things, Scroll Reverser en Simple Comic.
Deze zijn niet opgenomen, omdat je ze niet hebt gekozen om mee te nemen. De
Apple-systeemapps op de screenshots hoeven niet via deze scripts te worden
geïnstalleerd. SF Symbols staat bij development (de stabiele versie, geen beta),
UniFi, The Unarchiver en PastePal staan bij de gewone apps. Caffeinated staat
bij Werk; Figma, Sketch en `cmatrix` blijven behouden.


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

Op macOS en Ubuntu kun je dit na de installatie ook vanuit elke map openen met:

```bash
dotfiles
```

Het macOS-hoofdmenu bevat **(Re)install and apply configuration**,
**Manage apps**, **Diagnostics**, **Backup / restore** en **Reload
configuration**. Binnen **Manage apps** staan installeren, bijwerken en
verwijderen. De updateactie haalt eerst de beschikbare Homebrew- en Mac App
Store-updates op, toont ze en vraagt daarna bevestiging. Herladen van de
dotfiles blijft een aparte actie. Alle geïnstalleerde Homebrew-pakketten tellen
mee, ook buiten de Brewfiles. `--greedy` neemt apps met een eigen updater en
`latest`-versies mee; expliciet vastgezette pakketten blijven door Homebrew beheerd.
De Homebrew-lijsten worden eerst ververst, maar installeren gebeurt pas na
bevestiging. Razer-updates lopen via Razer zelf.

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

Gebruik **Manage apps** om standaardapps te installeren, werkapps en hardwaredrivers
te kiezen, updates te bekijken of apps te verwijderen. De controle op apps
buiten de profielen en het verplaatsen van apps staan onder **Diagnostics**.

## Structuur

```text
Brewfile       Basisformules, Codex CLI, WhichSpace en Raycast
Brewfile.dev   Optionele development-tools en -apps
Brewfile.daily  Dagelijkse apps in pakket Basis
Brewfile.personal  Optionele persoonlijke apps
Brewfile.personal.mas  Persoonlijke App Store-apps en iWork
Brewfile.mas   Dagelijkse Mac App Store-apps
Brewfile.office      Teams, DisplayLink, Citrix, Okta, Docker en Wacom
Brewfile.office.mas  Microsoft Office en Caffeinated uit de App Store
bootstrap.sh   Installatie voor macOS en Ubuntu
setup.sh       Centrale manager voor installatie en configuratie
manage-apps.sh Menu voor installeren, bijwerken en verwijderen van Mac-apps
menu-ui.sh     Gedeelde ASCII-header en schermnavigatie voor menu's
docker-manager.sh  Interactief beheer van Docker-containers op Ubuntu
reload.sh      Pas configuratiewijzigingen toe na git pull
update.sh      Toont en installeert alle Homebrew- en Mac App Store-updates
audit-apps.sh / audit-apps.py  Vergelijking met installatielijsten en optioneel verwijderen
app-installed.py  Herken ook handmatig geïnstalleerde appbundels
migrate-apps.sh  Bestaande apps veilig naar /Applications overzetten
cleanup-retired-apps.sh  Uitgefaseerde tools opruimen met configuratieback-up
vendor-apps.sh  Officiële Razer-installer
health-check.sh  Leesbare controle van de installatie zonder wijzigingen
diagnostics.sh  Health check, service-status en logweergave
install-apps.sh  Standaardapps, werkapps en optionele hardwaredrivers
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
office-installer.sh  Werkapps individueel of allemaal installeren
home/          Gedeelde shell-, terminal- en editorconfiguratie
macos/         Optionele lokale macOS-scripts
```

De installatie gebruikt Stow en stopt bij bestaande, conflicterende bestanden
in je thuismap. Maak die eerst bewust veilig of verplaats ze naar deze
repository; het script overschrijft nooit stilzwijgend persoonlijke
configuratie.
