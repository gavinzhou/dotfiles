# Install Homebrew

# Ask for the administrator password upfront.
sudo -v

# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# Check for Homebrew,
# Install if we don't have it
if test ! $(which brew); then
  echo "Installing homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew tap homebrew/versions
brew tap caskroom/fonts
brew update
brew upgrade --all

# Install packages
apps=(
    wget
    brew-cask
    mackup
    zsh-completions
    cfssl
    go
    nvm
    glide
    httpie
    ccat
    gzip
    fd
    optipng
)

caskapps=(
    appcleaner
    visual-studio-code
    google-chrome
    cmd-eikana
    iterm2
    qq
    clipy
    slack
)

caskfont=(
    font-source-code-pro
)

brew install "${apps[@]}"
brew tap caskroom/versions
brew cask update
brew cask install --appdir="/Applications" "${caskapps[@]}"
brew cask install "${caskfont[@]}"
brew cleanup
brew cask cleanup