# Instructions for the other Mac

You are an assistant on the second Mac that shares a Dell U3225QE with the owner's Mac mini. The Dell should be showing this Mac while you do this.

Do not commit or push anything to this repository. It is public. Tell the owner the results in the terminal.

## Rules

- Do not use sudo. Do not change firewall or device-management settings.
- Do not unpair, disconnect or otherwise touch any Bluetooth device.
- Do not run any `magicswitch://` URL.
- If a step is blocked or needs an admin, skip it and tell the owner. Do not work around it.

## Steps

1. Check that `swiftc --version` works and `which brew` finds Homebrew. If the Command Line Tools are missing, tell the owner and do not install them; step 3 will not work without them.

2. If Homebrew is available, install Magic Switch and launch it. Do not try to answer its permission prompts; the owner will.

   ```sh
   brew tap megamansec/tap && brew install --cask megamansec/tap/magic-switch
   open -a "Magic Switch"
   ```

3. Read `hubfollow/hubfollow.swift` and `hubfollow/install.sh`. If they do anything other than watch for a USB hub and a Bluetooth keyboard connecting, and open `magicswitch://` URLs, stop and tell the owner. Otherwise run:

   ```sh
   hubfollow/install.sh
   ```

4. Verify:

   ```sh
   launchctl print "gui/$(id -u)/local.hubfollow" | grep -E 'state|last exit code'
   tail -3 ~/Library/Logs/hubfollow.log
   ```

   The agent should be running and the log should say `present now: 1`. If it says `present now: 0` while the Dell is showing this Mac, tell the owner clearly: the tool will not work on this Mac until that is solved. Show them the output of `system_profiler SPUSBDataType | grep -iE 'hub:'`.

5. Tell the owner in one or two lines whether everything worked, and what is left for them to do in Magic Switch.
