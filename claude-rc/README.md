# claude-rc

Keeps Claude Code's Remote Control host (`claude remote-control`) running on the Mac as a launchd service, so new sessions can be started from claude.ai/code or the Claude app.

## The problem

Remote Control starts each new session from the path of its own binary. Homebrew removes the old version's folder when it upgrades Claude Code, so a host started before an upgrade can no longer start sessions. Sessions already open keep working.

## What it does

- `local.claude-rc` runs `claude-rc`, which copies the current Homebrew binary to `~/Library/Application Support/claude-rc/<version>/` and runs Remote Control from that copy in `~/code`. Homebrew never touches the copy. launchd starts it at login and again if it exits.
- `local.claude-rc-update` runs `claude-rc restart-if-new` daily at 04:00. If Homebrew has a newer version, it restarts the host on it. **The restart ends any sessions open at that time.**
- Both log to `~/Library/Logs/claude-rc.log`.

## Install

```sh
cp local.claude-rc.plist local.claude-rc-update.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.claude-rc.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.claude-rc-update.plist
```

Stop any `claude rc` running in a terminal first, or there are two hosts.

Restart by hand: `launchctl kickstart -k gui/$(id -u)/local.claude-rc`.
