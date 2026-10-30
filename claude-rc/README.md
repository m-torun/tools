# claude-rc

Keeps Claude Code's Remote Control host (`claude remote-control`) running on the Mac as a launchd service, so new sessions can be started from claude.ai/code or the Claude app, and updates Claude Code at night.

## The problem

Remote Control starts each new session from the path of its own binary. Homebrew removes the old version's folder when it upgrades Claude Code, so a host started before an upgrade can no longer start sessions. Sessions already open keep working.

## What it does

- `local.claude-rc` runs Remote Control from Homebrew's Claude Code in `~/code`. launchd starts it at login and again if it exits.
- `local.claude-rc-update` runs `claude-rc update` daily at 04:00: `brew upgrade --cask claude-code@latest`, then a restart of the host if the version changed. **The restart ends any sessions open at that time.**
- Claude Code's own background upgrade must be off, so upgrades happen only at 04:00: no `CLAUDE_CODE_PACKAGE_MANAGER_AUTO_UPDATE` in `~/.claude/settings.json`.
- Both log to `~/Library/Logs/claude-rc.log`.

Running the host from a copy of the binary outside Homebrew would avoid the restart, but a copy cannot read Claude Code's login from the keychain and hangs at startup.

## Install

Stop any `claude rc` running in a terminal first: only one host can serve a folder.

```sh
cp local.claude-rc.plist local.claude-rc-update.plist ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.claude-rc.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.claude-rc-update.plist
```

Restart by hand: `launchctl kickstart -k gui/$(id -u)/local.claude-rc`.
