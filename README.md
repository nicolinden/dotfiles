# dotfiles
A repo for my dot file configuration


Install these apps: 

- homeBrew
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
  eval "$(/opt/homebrew/bin/brew shellenv)"

- oh my zsh
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

- brew packages
    brew install --cask wezterm
    brew install font-meslo-lg-nerd-font
    brew install powerlevel10k
    brew install eza
    brew install node
    brew install stow
    brew install neovim
    brew install tmux
    brew install ripgrep
    brew install zsh-autosuggestions
    brew install zsh-syntax-highlighting
    brew install --cask visual-studio-code
    brew install lazygit

- clone repos
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    git clone https://github.com/nicolinden/dotfiles.git ~/dotfiles

- Start VS Code
    execute command to add code to path 
    enable vim extension
    ln -s "$HOME/dotfiles/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
    ln -s "$HOME/dotfiles/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"

    stow all dot files