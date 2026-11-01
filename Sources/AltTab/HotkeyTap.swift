import AppKit
import CoreGraphics

@MainActor
final class HotkeyTap {
    private static let tabKeyCode: Int64 = 48

    var onTab: () -> Void = {}
    var onOptionReleased: () -> Void = {}

    private var tap: CFMachPort?
    private var sessionOpen = false

    func start() -> Bool {
        let mask = (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << CGEventType.flagsChanged.rawValue)
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: hotkeyTapCallback,
            userInfo: refcon
        ) else {
            log.error("CGEvent.tapCreate failed")
            return false
        }
        self.tap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        log.info("Event tap started")
        return true
    }

    /// Returns true when the event must be consumed.
    fileprivate func handle(type: CGEventType, keyCode: Int64, flags: CGEventFlags) -> Bool {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            log.notice("Event tap disabled (\(type.rawValue)), enabling again")
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }

        case .keyDown, .keyUp:
            guard keyCode == Self.tabKeyCode else { break }
            let optionOnly = flags.contains(.maskAlternate)
                && !flags.contains(.maskCommand)
                && !flags.contains(.maskControl)
            guard optionOnly else { break }
            if type == .keyDown {
                sessionOpen = true
                log.debug("Option+Tab")
                onTab()
            }
            return true

        case .flagsChanged:
            if sessionOpen && !flags.contains(.maskAlternate) {
                sessionOpen = false
                log.debug("Option released")
                onOptionReleased()
            }

        default:
            break
        }
        return false
    }
}

private func hotkeyTapCallback(
    proxy: CGEventTapProxy,
    type: CGEventType,
    event: CGEvent,
    refcon: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let refcon else { return Unmanaged.passUnretained(event) }
    let tap = Unmanaged<HotkeyTap>.fromOpaque(refcon).takeUnretainedValue()
    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    let flags = event.flags
    // The run loop source is on the main run loop, so the callback runs on the main thread.
    let consume = MainActor.assumeIsolated {
        tap.handle(type: type, keyCode: keyCode, flags: flags)
    }
    return consume ? nil : Unmanaged.passUnretained(event)
}
