#!/bin/bash
# Lets the 1Password SSH agent offer keys from the "gavin" vault (by default it
# only offers the Private vault). Runs again whenever this file changes.
set -euo pipefail

dir="$HOME/.config/1Password/ssh"
mkdir -p "$dir"
cat > "$dir/agent.toml" <<'EOF'
# Managed by dotfiles (run_onchange_after_25-1password-ssh.sh)
[[ssh-keys]]
vault = "gavin"
EOF
