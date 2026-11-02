// hubfollow: when the Dell's USB hub arrives on this Mac, take the keyboard and mouse.
// The hub moves with the monitor's input, so the monitor's own button drives the handoff.
import Foundation
import IOKit

let vendorID = 0x0424   // Microchip/SMSC
let productID = 0x7206  // USB7206 Smart Hub, inside the Dell U3225QE
// One device at a time. When two pairings overlap, macOS loses track of the app that asked
// for the second one and shows a "Connection Request" popup for it. The mouse goes first
// because macOS will not auto-accept a mouse, so a mistimed mouse could need a real click,
// while a mistimed keyboard only gets a popup that does nothing.
let takeURLs = [
    "magicswitch://switch?peripheral=mouse&direction=take",
    "magicswitch://switch?peripheral=keyboard&direction=take",
]
let gapSeconds = 4.0       // long enough for the mouse to finish pairing
let settleSeconds = 0.25   // only coalesces the hub's USB devices; a longer wait just delays the keyboard
let debounceSeconds = 15.0 // the hub shows up as several USB devices per switch
let dryRun = CommandLine.arguments.contains("--dry-run")

var lastTake = Date.distantPast

func log(_ message: String) {
    let stamp = ISO8601DateFormatter().string(from: Date())
    print("\(stamp) \(message)")
    fflush(stdout)
}

// Empties the iterator, which also re-arms the notification. Returns how many hubs it held.
func drain(_ iterator: io_iterator_t) -> Int {
    var count = 0
    while case let device = IOIteratorNext(iterator), device != 0 {
        IOObjectRelease(device)
        count += 1
    }
    return count
}

func take() {
    guard Date().timeIntervalSince(lastTake) > debounceSeconds else { return }
    lastTake = Date()
    log("hub arrived, taking peripherals in \(settleSeconds)s")
    for (index, url) in takeURLs.enumerated() {
        DispatchQueue.main.asyncAfter(deadline: .now() + settleSeconds + Double(index) * gapSeconds) {
            openURL(url)
        }
    }
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

let matching = IOServiceMatching("IOUSBHostDevice") as NSMutableDictionary
matching["idVendor"] = vendorID
matching["idProduct"] = productID

var iterator: io_iterator_t = 0
let status = IOServiceAddMatchingNotification(
    port, kIOFirstMatchNotification, matching as CFDictionary,
    { _, iterator in
        if drain(iterator) > 0 { take() }
    },
    nil, &iterator)
guard status == KERN_SUCCESS else {
    log("could not watch for the hub: \(status)")
    exit(1)
}

// A hub already here at launch is not an arrival: don't pull devices off the other Mac on login.
log("watching for \(String(format: "%04x:%04x", vendorID, productID)); present now: \(drain(iterator))\(dryRun ? " (dry run)" : "")")
CFRunLoopRun()
