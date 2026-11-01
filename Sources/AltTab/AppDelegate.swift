import AppKit
import os

let log = Logger(subsystem: "com.dvemar.alttab", category: "app")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        log.info("AltTab started")
    }
}
