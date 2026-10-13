#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# AI agent CLIs (Claude Code, Codex, ...) source this file to snapshot the
# environment. They need PATH and env vars, but not prompts, aliases or
# output-producing commands. Set AGENT_SHELL=1 to force agent mode elsewhere.
if [[ -n "$CLAUDECODE" || -n "$CODEX_SANDBOX" || -n "$CODEX_THREAD_ID" || -n "$AGENT_SHELL" ]]; then
  _agent_shell=1
fi

#
# Environment (shared by humans and agents)
#

export EDITOR=vim

export GOPATH=${HOME}/go
export GO111MODULE=on
export GOBIN=${HOME}/go/bin

export N_PREFIX="$HOME/n"
export BUN_INSTALL="$HOME/.bun"
export PYENV_ROOT="$HOME/.pyenv"
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
export USE_GKE_GCLOUD_AUTH_PLUGIN=True
export PKG_CONFIG_PATH="/opt/homebrew/opt/jpeg/lib/pkgconfig"
export JAVA_HOME="/opt/homebrew/opt/openjdk@25/libexec/openjdk.jdk/Contents/Home"
export ANDROID_HOME="$HOME/Library/Android/sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"

# PATH: earlier entries win, duplicates are dropped, and (N-/) keeps only
# directories that exist, so stale tool paths do nothing.
typeset -U path
path=(
  $HOME/.local/bin(N-/)
  $HOME/bin(N-/)
  $BUN_INSTALL/bin(N-/)
  /opt/homebrew/opt/openjdk@25/bin(N-/)
  $ANDROID_HOME/platform-tools(N-/)
  $ANDROID_HOME/emulator(N-/)
  $ANDROID_HOME/cmdline-tools/latest/bin(N-/)
  $HOME/.daml/bin(N-/)
  /opt/homebrew/opt/openvpn/sbin(N-/)
  /opt/homebrew/opt/libpq/bin(N-/)
  $HOME/.gloo/bin(N-/)
  $PYENV_ROOT/bin(N-/)
  $GOBIN(N-/)
  /opt/homebrew/bin(N-/)
  /opt/homebrew/sbin(N-/)
  /usr/local/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
  $N_PREFIX/bin(N-/)
  $HOME/.krew/bin(N-/)
  $HOME/.rvm/bin(N-/)
  $HOME/.platformio/penv/bin(N-/)
  /Applications/Keybase.app/Contents/SharedSupport/bin(N-/)
)
export PATH

# Google Cloud SDK
_gcloud_sdk=/opt/homebrew/share/google-cloud-sdk
[[ -f $_gcloud_sdk/path.zsh.inc ]] && source $_gcloud_sdk/path.zsh.inc

# Secrets live outside this repo (and outside git), e.g. ~/.secrets.zsh with
# `export SLACK_MCP_TOKEN=...`. Keep it chmod 600.
[[ -r ~/.secrets.zsh ]] && source ~/.secrets.zsh

#
# Interactive only (skipped for agents)
#

if [[ -n "$_agent_shell" ]]; then
  unset _agent_shell _gcloud_sdk
  return
fi

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

HISTSIZE=1000000
SAVEHIST=1000000
HISTFILE=~/.zsh_history

#alias list
source ~/.aliases

#gpg
GPG_TTY=$(tty)
export GPG_TTY

#ssh
ssh-add -q 2>/dev/null

# Completions
[[ -f $_gcloud_sdk/completion.zsh.inc ]] && source $_gcloud_sdk/completion.zsh.inc
(( $+commands[kubectl] )) && source <(kubectl completion zsh)
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"
[ -f "$HOME/.openclaw/completions/openclaw.zsh" ] && source "$HOME/.openclaw/completions/openclaw.zsh"

unset _agent_shell _gcloud_sdk
