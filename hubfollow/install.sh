#!/bin/sh
# Builds hubfollow and runs it at login. Remove with: ./install.sh --uninstall
set -eu
label=local.hubfollow
plist="$HOME/Library/LaunchAgents/$label.plist"
bin="$HOME/.local/bin/hubfollow"

launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
if [ "${1:-}" = "--uninstall" ]; then
    rm -f "$plist" "$bin"
    echo "removed"
    exit 0
fi

mkdir -p "$(dirname "$bin")" "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
swiftc -O "$(dirname "$0")/hubfollow.swift" -o "$bin"
cat > "$plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>$label</string>
    <key>ProgramArguments</key><array><string>$bin</string></array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>StandardOutPath</key><string>$HOME/Library/Logs/hubfollow.log</string>
    <key>StandardErrorPath</key><string>$HOME/Library/Logs/hubfollow.log</string>
</dict>
</plist>
PLIST
launchctl bootstrap "gui/$(id -u)" "$plist"
echo "installed; log: $HOME/Library/Logs/hubfollow.log"
