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
alias cat=ccat
alias k=kubectl

#set env
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:/usr/local/opt/gettext/bin:$PATH