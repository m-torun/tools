# hubfollow

Makes a Magic Keyboard and Magic Mouse follow a monitor's input, for two Macs sharing one Dell U3225QE.

The Dell's USB hub moves to whichever Mac the monitor is showing. When the hub arrives on a Mac, hubfollow runs `open -g "magicswitch://switch?direction=take"`, and [Magic Switch](https://github.com/MegaManSec/magic-switch) does the Bluetooth handoff. The monitor's own button is the only control, so switching still works when the keyboard battery is dead.

## Install

Needs Magic Switch set up on both Macs and the Xcode Command Line Tools. On each Mac:

```sh
./install.sh
```

The log is `~/Library/Logs/hubfollow.log`. To remove it, run `./install.sh --uninstall`.

To watch for arrivals without moving anything, stop the agent and run the binary with `--dry-run`.

For a different hub, change `vendorID` and `productID` in `hubfollow.swift`.

## other-mac/

[other-mac/INSTRUCTIONS.md](other-mac/INSTRUCTIONS.md) is the setup for the second Mac, written for an assistant running there.
