# Instructions for the other Mac

Round: 1

You are an assistant on the second Mac that shares a Dell U3225QE with the owner's Mac mini. This file is how the assistant on the Mac mini gives you work. You answer in `REPORT.md`, next to this file. Do only the current round, then stop.

## Rules

- Do not use sudo. Do not change firewall or device-management settings.
- Do not unpair, disconnect or otherwise touch any Bluetooth device.
- Do not run any `magicswitch://` URL.
- If a step is blocked or needs an admin, skip it and say so in the report. Do not work around it.

## This repository is public

Everything you commit can be read by anyone, permanently. The report must contain only what its template asks for. Never put any of these in it: usernames, full home paths (write `~`), hostnames, serial numbers, Bluetooth or network addresses, IP addresses, device names, employer or organization names, or tokens.

## Round 1: install

The owner has been told to have the Dell showing this Mac for this round.

1. Collect, without copying raw output into the report:
   - `sw_vers -productVersion`
   - `profiles status -type enrollment`: is this Mac enrolled in device management?
   - `xcode-select -p` and `swiftc --version`. If the Command Line Tools are missing, report it and do not install them. Step 3 will not work without them.
   - `which brew`
   - `ioreg -p IOUSB -w0 | grep -c USB7206`. If this is 0, also run `system_profiler SPUSBDataType | grep -iE 'hub:'` and report only the hub product names.
   - `system_profiler SPBluetoothDataType`: is a device with "Magic Keyboard" in its name connected to this Mac, yes or no? The same for "Magic Mouse". Report only yes or no.

2. If Homebrew is available, install Magic Switch and launch it. Do not try to answer its permission prompts; the owner will.

   ```sh
   brew tap megamansec/tap && brew install --cask megamansec/tap/magic-switch
   open -a "Magic Switch"
   ```

3. Read `hubfollow/hubfollow.swift` and `hubfollow/install.sh`. If they do anything other than watch for a USB hub and open a `magicswitch://` URL, stop and say so in the report. Otherwise run:

   ```sh
   hubfollow/install.sh
   ```

4. Verify:

   ```sh
   launchctl print "gui/$(id -u)/local.hubfollow" | grep -E 'state|last exit code'
   tail -3 ~/Library/Logs/hubfollow.log
   ```

   The log should say `present now: 1` while the Dell is showing this Mac.

5. Overwrite `hubfollow/other-mac/REPORT.md` with this template, filled in:

   ```markdown
   # Report

   Round: 1

   - macOS version:
   - Enrolled in device management (yes/no):
   - Command Line Tools (yes/no) and Swift version:
   - Homebrew (yes/no):
   - USB7206 count, and hub names if the count is 0:
   - Magic Keyboard connected here (yes/no):
   - Magic Mouse connected here (yes/no):
   - Magic Switch installed (yes/no) and version:
   - Magic Switch launched (yes/no):
   - Anything unexpected in the code (yes/no, and what):
   - hubfollow agent state and last exit code:
   - hubfollow log, the `present now` number:
   - Blocked or skipped, and why:
   ```

## Sending the report

Check the file against the public repository rule above, then commit only that file. Set the identity on the command as shown, so that this Mac's default git identity does not end up in public history:

```sh
git add hubfollow/other-mac/REPORT.md
git -c user.name=m-torun -c user.email=332165974+m-torun@users.noreply.github.com commit -m "hubfollow: other Mac report, round 1"
git pull --rebase --autostash origin hubfollow
git push origin hubfollow
```

Push using the access to `m-torun` this Mac already has. Do not change git or gh configuration, and do not switch accounts. If you cannot push, print the report in the terminal, tell the owner, and stop.
