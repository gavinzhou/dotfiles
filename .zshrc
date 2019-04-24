#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...
HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.zsh_history

#alias list
source ~/.aliases

#gpg
GPG_TTY=$(tty)
export GPG_TTY

#set env
export GOPATH=${HOME}/go
export GO111MODULE=on
export GOBIN=${HOME}/go/bin
export PATH=${GOBIN}:${HOME}/Library/Python/3.7/bin:${HOME}/google-cloud-sdk/bin:/bin:/usr/local/opt/gettext/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
export PATH=$HOME/bin:$PATH

export EDITOR=vim

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc' ]; then . '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc' ]; then . '/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc'; fi

export N_PREFIX="$HOME/n"; [[ :$PATH: == *":$N_PREFIX/bin:"* ]] || PATH+=":$N_PREFIX/bin"  # Added by n-install (see http://git.io/n-install-repo).

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
export PATH="/usr/local/opt/redis@3.2/bin:$PATH"
export PATH="/usr/local/opt/icu4c/bin:$PATH"
export PATH="/usr/local/opt/icu4c/sbin:$PATH"
export PATH=$HOME/.gloo/bin:$PATH
