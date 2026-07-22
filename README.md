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
non-interactive installer. Daarna worden alle formules, casks, Oh My Zsh en de
symlinks geïnstalleerd. Aan het einde vraagt bootstrap of de Mac App
Store-apps ook mogen worden geïnstalleerd. Tijdens lange downloads blijft de
Mac wakker.

Na afloop open je een nieuw terminalvenster zodat de nieuwe shellconfiguratie
wordt geladen.

### Handmatige stappen na de installatie

- Log in bij 1Password, Tailscale, WhatsApp, ChatGPT en andere account-apps.
- Log vóór bootstrap in bij de Mac App Store. Kies aan het einde van bootstrap
  `y` om PastePal, Goodnotes, Tailscale, Caffeinated, The Unarchiver en
  Pixelmator Pro te installeren. Je kunt die stap ook los uitvoeren met
  `./install-mac-apps.sh`. Voor betaalde apps, zoals Caffeinated en Pixelmator
  Pro, moet de app eerst aan hetzelfde Apple-account zijn gekoppeld.
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
  | `⌥⇧M` | Wissel tussen SketchyBar en de native macOS-menubalk |
- SketchyBar wordt na de bootstrap als gebruikersservice gestart, komt bij
  iedere volgende login automatisch terug en wordt op alle aangesloten
  schermen getoond. De bootstrap verbergt hiervoor ook de native macOS-menubalk
  automatisch. SketchyBar tekent bovendien boven de native balk, zodat er geen
  dubbele of versprongen balken ontstaan wanneer macOS die tijdelijk toont.
  Elke aangesloten monitor markeert daarbij zijn eigen zichtbare
  AeroSpace-workspace.
  Druk `⌥⇧M` om SketchyBar tijdelijk te verbergen en de native menubalk te
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
Brewfile.mas   Persoonlijke Mac App Store-apps
Brewfile.office.mas  Apple iWork- en Microsoft Office-apps
bootstrap.sh   Installatie voor macOS en Ubuntu
update.sh      Homebrew-updates voor macOS
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
