// hubfollow: when the Dell's USB hub arrives on this Mac, take the keyboard, then the mouse.
// The hub moves with the monitor's input, so the monitor's own button drives the handoff.
import Foundation
import IOKit

let vendorID = 0x0424   // Microchip/SMSC
let productID = 0x7206  // USB7206 Smart Hub, inside the Dell U3225QE

// One device at a time. macOS remembers that an app asked to pair as one flag per app, and
// clears it after each pairing, so when two pairings overlap it shows a "Connection Request"
// popup for the second. The keyboard goes first so this Mac can be woken and unlocked.
let keyboardURL = "magicswitch://switch?peripheral=keyboard&direction=take"
let mouseURL = "magicswitch://switch?peripheral=mouse&direction=take"
let keyboardName = "Magic Keyboard" // its Bluetooth name, which tells us when it has connected
let keyboardWaitSeconds = 20.0      // take the mouse anyway if the keyboard never shows up

let settleSeconds = 0.25   // only coalesces the hub's USB devices; a longer wait just delays the keyboard
let debounceSeconds = 15.0 // the hub shows up as several USB devices per switch
let dryRun = CommandLine.arguments.contains("--dry-run")

var lastTake = Date.distantPast
var waitingForKeyboard = false
var handoff = 0 // tells a timeout which handoff it belongs to

func log(_ message: String) {
    let stamp = ISO8601DateFormatter().string(from: Date())
    print("\(stamp) \(message)")
    fflush(stdout)
}

// Empties the iterator, which also re-arms the notification. Returns how many devices it held.
func drain(_ iterator: io_iterator_t) -> Int {
    var count = 0
    while case let device = IOIteratorNext(iterator), device != 0 {
        IOObjectRelease(device)
        count += 1
    }
    return count
}

func keyboardMatching() -> CFDictionary {
    let matching = IOServiceMatching("IOHIDInterface") as NSMutableDictionary
    matching["IOPropertyMatch"] = ["Product": keyboardName, "Transport": "Bluetooth"]
    return matching as CFDictionary
}

func keyboardIsHere() -> Bool {
    var found: io_iterator_t = 0
    guard IOServiceGetMatchingServices(kIOMainPortDefault, keyboardMatching(), &found) == KERN_SUCCESS else {
        return false
    }
    defer { IOObjectRelease(found) }
    return drain(found) > 0
}

func hubArrived() {
    guard Date().timeIntervalSince(lastTake) > debounceSeconds else { return }
    lastTake = Date()
    log("hub arrived")
    DispatchQueue.main.asyncAfter(deadline: .now() + settleSeconds, execute: takeKeyboard)
}

func takeKeyboard() {
    handoff += 1
    if keyboardIsHere() {
        log("keyboard already here")
        openURL(mouseURL)
        return
    }
    waitingForKeyboard = true
    openURL(keyboardURL)
    let thisHandoff = handoff
    DispatchQueue.main.asyncAfter(deadline: .now() + keyboardWaitSeconds) {
        guard waitingForKeyboard, thisHandoff == handoff else { return }
        log("keyboard did not connect in \(keyboardWaitSeconds)s")
        takeMouse()
    }
}

func takeMouse() {
    waitingForKeyboard = false
    openURL(mouseURL)
}

func openURL(_ url: String) {
    if dryRun {
        log("dry run: would open \(url)")
        return
    }
    let open = Process()
    open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
    open.arguments = ["-g", url]
    do {
        try open.run()
        log("opened \(url)")
    } catch {
        log("could not run open: \(error)")
    }
}

guard let port = IONotificationPortCreate(kIOMainPortDefault) else {
    log("could not create a notification port")
    exit(1)
}
CFRunLoopAddSource(CFRunLoopGetMain(), IONotificationPortGetRunLoopSource(port).takeUnretainedValue(), .defaultMode)

let hubMatching = IOServiceMatching("IOUSBHostDevice") as NSMutableDictionary
hubMatching["idVendor"] = vendorID
hubMatching["idProduct"] = productID

var hubIterator: io_iterator_t = 0
var status = IOServiceAddMatchingNotification(
    port, kIOFirstMatchNotification, hubMatching as CFDictionary,
    { _, iterator in
        if drain(iterator) > 0 { hubArrived() }
    },
    nil, &hubIterator)
guard status == KERN_SUCCESS else {
    log("could not watch for the hub: \(status)")
    exit(1)
}

var keyboardIterator: io_iterator_t = 0
status = IOServiceAddMatchingNotification(
    port, kIOFirstMatchNotification, keyboardMatching(),
    { _, iterator in
        if drain(iterator) > 0, waitingForKeyboard {
            log("keyboard connected")
            takeMouse()
        }
    },
    nil, &keyboardIterator)
guard status == KERN_SUCCESS else {
    log("could not watch for the keyboard: \(status)")
    exit(1)
}
_ = drain(keyboardIterator)

// A hub already here at launch is not an arrival: don't pull devices off the other Mac on login.
log("watching for \(String(format: "%04x:%04x", vendorID, productID)); present now: \(drain(hubIterator))\(dryRun ? " (dry run)" : "")")
CFRunLoopRun()
