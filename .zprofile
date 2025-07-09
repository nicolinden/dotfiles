# Detecteer waar brew staat
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
autoload -Uz compinit
compinit

# VARIABLES
export medini_container=09dccc00732d
export office_db_container=da472e44464f
export office_admin_container=f9cde467251f

export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

alias runBabel='npx babel src --out-dir webapp --source-maps true --extensions ".ts,.js" --copy-files'
alias getBuildNumber='date +%s'
alias c='clear'

# MEDINI
alias medini='cd ~/Development/Expertum/customers/medini/medini-vetorder'
alias login='cf login --sso'
alias startSSO='npm run start:sshtunnel'
alias startProxy='npm run start:proxy'
alias cdsWatch='cds w --profile hybrid'
alias docker-medini='docker-stop-all; docker start $medini_container'

# OFFICE APP
alias officeApp='cd ~/Development/Expertum/internal/expertum-office-app'
alias docker-office-app='docker-stop-all; docker start $office_db_container; docker start $office_admin_container'

# DOCKER
alias docker-stop-all='docker stop $(docker ps -a -q)'


alias src='omz reload' # instead
alias tree="find . -print | sed -E 's|[^/]*/|  |g; s|  ([^ ]*)$|- \1|'"
