import AppKit
import ApplicationServices
import os

let log = Logger(subsystem: "com.dvemar.alttab", category: "app")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotkeyTap = HotkeyTap()
    private var trustTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        log.info("AltTab started")
        hotkeyTap.onTab = {
            let windows = WindowList.current()
            log.info("onTab: \(windows.count) windows")
            if windows.count > 1 { WindowList.focus(windows[1]) }
        }
        hotkeyTap.onOptionReleased = { log.info("onOptionReleased") }

        if isTrusted(prompt: true) {
            startTap()
        } else {
            log.notice("Waiting for Accessibility permission")
            trustTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                MainActor.assumeIsolated { self.checkTrust() }
            }
        }
    }

    private func checkTrust() {
        guard isTrusted(prompt: false) else { return }
        trustTimer?.invalidate()
        trustTimer = nil
        startTap()
    }

    private func startTap() {
        if !hotkeyTap.start() {
            log.error("Cannot start the event tap")
        }
    }

    private func isTrusted(prompt: Bool) -> Bool {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        return AXIsProcessTrustedWithOptions([key: prompt] as CFDictionary)
    }
}
