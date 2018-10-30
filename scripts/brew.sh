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
    mackup
    zsh-completions
    cfssl
    golang
    glide
    httpie
    ccat
    gzip
    fd
    optipng
    zsh
    hub
    ripgrep
)

caskapps=(
    appcleaner
    visual-studio-code
    google-chrome
    google-japanese-ime
    cmd-eikana
    iterm2
    qq
    clipy
    slack
    insomnia
)

caskfont=(
    font-source-code-pro
)

brew install "${apps[@]}"
brew cask install "${caskapps[@]}"
brew cask install "${caskfont[@]}"
brew cleanup
