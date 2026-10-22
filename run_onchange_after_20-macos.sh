#!/bin/bash
# macOS settings. Runs again whenever this file changes.
set -euo pipefail

# Dock on the left, icon size 59
defaults write com.apple.dock orientation -string left
defaults write com.apple.dock tilesize -int 59

# Finder opens folders in list view
defaults write com.apple.finder FXPreferredViewStyle -string Nlsv

# Tap to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1

# hidutil and tapBehavior reset at login, so LaunchAgents reapply them.
# Caps Lock -> Left Control: https://developer.apple.com/library/archive/technotes/tn2450/
agents=~/Library/LaunchAgents
mkdir -p "$agents"

cat > "$agents/com.keyboard.macos.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.keyboard.KeyRemapping</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/hidutil</string>
        <string>property</string>
        <string>--set</string>
        <string>{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":0x700000039,"HIDKeyboardModifierMappingDst":0x7000000E0}]}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

cat > "$agents/com.tapbehavior.macos.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.tapbehavior</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/defaults</string>
        <string>-currentHost</string>
        <string>write</string>
        <string>-g</string>
        <string>com.apple.mouse.tapBehavior</string>
        <string>1</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
EOF

for plist in "$agents/com.keyboard.macos.plist" "$agents/com.tapbehavior.macos.plist"; do
  launchctl bootout "gui/$UID" "$plist" 2>/dev/null || true
  launchctl bootstrap "gui/$UID" "$plist"
done

killall Dock Finder 2>/dev/null || true
