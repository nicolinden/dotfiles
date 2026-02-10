# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git 1password sudo web-search copypath copyfile copybuffer dirhistory history jsontools macos docker)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='nvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias zs='nvim ~/.zshrc'

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# history setup
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt share_history
setopt hist_expire_dups_first
setopt hist_ignore_dups
setopt hist_verify

source ~/.zprofile

# completion using arrow keys (based on history)
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward

# alias ls="eza --icons=always"
alias sshmacmini='ssh nico@100.115.42.3'
alias sshmacair='ssh nico@100.65.18.30'

# ---- Zoxide (better cd) ----
# eval "$(zoxide init zsh)"
# alias cd="z"
export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
export SAP_ANDROID_HOME="/Users/nico/Library/Application Support/Google/AndroidStudio2025.1.3/plugins"
export SAP_ANDROID_HOME="/Users/nico/Development/SAP/BTP/SDK"
export SAP_ANDROID_HOME="/Users/nico/Development/SAP/BTP/SDK"

# Use Android Studio bundled JDK
# export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
export PATH="$JAVA_HOME/bin:$PATH"

# To use indexes in adb command
adbdisc() {
  index="$1"
  serial=$(adb devices | sed -n "$((index+1))p" | awk '{print $1}')

  if [[ -z "$serial" ]]; then
    echo "No device at index $index"
    return
  fi

  # Emulator? (force kill process)
  if [[ "$serial" =~ ^emulator-[0-9]+$ ]]; then
    echo "Killing emulator process for $serial..."
    # Find PID via ps
    pid=$(ps aux | grep "$serial" | grep -v grep | awk '{print $2}')
    
    if [[ -n "$pid" ]]; then
      kill "$pid"
      echo "Killed emulator PID: $pid"
    else
      echo "No emulator process found—maybe already closed?"
    fi
    return
  fi

  # TCP device?
  if [[ "$serial" == *:* ]]; then
    echo "Disconnecting TCP device: $serial"
    adb disconnect "$serial"
    return
  fi

  echo "USB / physical device, not disconnecting: $serial"
}

snap() {
  name="$1"
  override_device="$2"

  if [[ -z "$name" ]]; then
    echo "Usage: snap <name> [device-id]"
    return 1
  fi

  ADB="$HOME/Library/Android/sdk/platform-tools/adb"
  mkdir -p "$HOME/Downloads/screenshots"

  # Als device expliciet is opgegeven → gebruik die
  if [[ -n "$override_device" ]]; then
    device="$override_device"
  else
    # Pak het eerste *echte* device (geen emulator)
    device=$("$ADB" devices \
      | awk 'NR>1 && $2=="device" && $1 !~ /^emulator-/ {print $1; exit}')
  fi

  if [[ -z "$device" ]]; then
    echo "❌ No physical Android device found"
    echo "ℹ️ Available devices:"
    "$ADB" devices
    return 1
  fi

  localpath="$HOME/Downloads/screenshots/${name}.png"

  echo "📸 Capturing from $device → $localpath"
  "$ADB" -s "$device" exec-out screencap -p > "$localpath"

  echo "✔ Saved to $localpath"
}




# snap() {
#   name="$1"
# 
#   if [[ -z "$name" ]]; then
#     echo "Usage: snap <name>"
#     return 1
#   fi
# 
#   ADB="/Users/nico/Library/Android/sdk/platform-tools/adb"
#   mkdir -p "$HOME/Downloads/screenshots"
# 
#   localpath="$HOME/Downloads/screenshots/${name}.png"
# 
#   echo "📸 Capturing → $localpath"
#   "$ADB" exec-out screencap -p > "$localpath"
# 
#   echo "✔ Saved to $localpath"
#   #open "$localpath" &>/dev/null
# }
# 
