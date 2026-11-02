import AppKit
import ApplicationServices
import os
import ServiceManagement

let log = Logger(subsystem: "com.dvemar.alttab-alpine", category: "app")

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let hotkeyTap = HotkeyTap()
    private let controller = SwitcherController()
    private var trustTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        log.info("AltTab started")
        registerLoginItemOnce()
        hotkeyTap.onTab = { [controller] in controller.onTab() }
        hotkeyTap.onOptionReleased = { [controller] in controller.onOptionReleased() }

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

    /// Only the first start registers, so a later removal in System Settings stays in effect.
    private func registerLoginItemOnce() {
        let key = "loginItemRegistered"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        do {
            try SMAppService.mainApp.register()
            UserDefaults.standard.set(true, forKey: key)
            log.info("Login item registered")
        } catch {
            log.error("Login item registration failed: \(error.localizedDescription)")
        }
    }

    private func isTrusted(prompt: Bool) -> Bool {
        let key = "AXTrustedCheckOptionPrompt" as CFString
        return AXIsProcessTrustedWithOptions([key: prompt] as CFDictionary)
    }
}
