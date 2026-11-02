import AppKit
import ApplicationServices

struct WindowItem {
    let pid: pid_t
    let element: AXUIElement
    let title: String
    let app: NSRunningApplication
}

@MainActor
enum WindowList {
    /// Windows of the current Space, front to back.
    static func current() -> [WindowItem] {
        let ownPid = ProcessInfo.processInfo.processIdentifier
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !$0.isHidden && $0.processIdentifier != ownPid
        }
        var appsByPid: [pid_t: NSRunningApplication] = [:]
        for app in apps { appsByPid[app.processIdentifier] = app }

        var pending: [pid_t: [(element: AXUIElement, frame: CGRect)]] = [:]
        for pid in appsByPid.keys {
            pending[pid] = axWindows(pid: pid)
        }

        var result: [WindowItem] = []
        var emittedPids: [pid_t] = []
        for (pid, bounds) in cgWindowsFrontToBack() {
            guard let app = appsByPid[pid], var candidates = pending[pid], !candidates.isEmpty else { continue }
            guard let index = candidates.firstIndex(where: { framesMatch($0.frame, bounds) }) else { continue }
            let match = candidates.remove(at: index)
            pending[pid] = candidates
            result.append(makeItem(pid: pid, element: match.element, app: app))
            if !emittedPids.contains(pid) { emittedPids.append(pid) }
        }

        // AX windows without a CG match go to the end of their app group.
        for pid in emittedPids {
            guard let app = appsByPid[pid], let rest = pending[pid], !rest.isEmpty else { continue }
            let lastIndex = result.lastIndex(where: { $0.pid == pid }) ?? result.count - 1
            let items = rest.map { makeItem(pid: pid, element: $0.element, app: app) }
            result.insert(contentsOf: items, at: lastIndex + 1)
            pending[pid] = []
        }
        return result
    }

    static func focus(_ item: WindowItem) {
        AXUIElementPerformAction(item.element, kAXRaiseAction as CFString)
        AXUIElementSetAttributeValue(item.element, kAXMainAttribute as CFString, kCFBooleanTrue)
        let appElement = AXUIElementCreateApplication(item.pid)
        let error = AXUIElementSetAttributeValue(appElement, kAXFrontmostAttribute as CFString, kCFBooleanTrue)
        if error != .success || !item.app.isActive {
            item.app.activate()
        }
    }

    // MARK: - CoreGraphics

    /// Only pid and bounds are read: these keys do not need Screen Recording.
    private static func cgWindowsFrontToBack() -> [(pid: pid_t, bounds: CGRect)] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let info = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }
        return info.compactMap { entry in
            guard (entry[kCGWindowLayer as String] as? Int) == 0,
                  let pid = entry[kCGWindowOwnerPID as String] as? pid_t,
                  let boundsDict = entry[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
            else { return nil }
            return (pid, bounds)
        }
    }

    // MARK: - Accessibility

    private static func axWindows(pid: pid_t) -> [(element: AXUIElement, frame: CGRect)] {
        let appElement = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(appElement, 0.2)
        guard let windows: [AXUIElement] = attribute(appElement, kAXWindowsAttribute) else { return [] }
        return windows.compactMap { window in
            let subrole: String? = attribute(window, kAXSubroleAttribute)
            guard subrole == kAXStandardWindowSubrole || subrole == kAXDialogSubrole else { return nil }
            if let minimized: Bool = attribute(window, kAXMinimizedAttribute), minimized { return nil }
            return (window, frame(of: window))
        }
    }

    private static func makeItem(pid: pid_t, element: AXUIElement, app: NSRunningApplication) -> WindowItem {
        let title: String? = attribute(element, kAXTitleAttribute)
        let name = (title?.isEmpty == false ? title : nil) ?? app.localizedName ?? ""
        return WindowItem(pid: pid, element: element, title: name, app: app)
    }

    private static func frame(of window: AXUIElement) -> CGRect {
        var origin = CGPoint.zero
        var size = CGSize.zero
        if let value: AXValue = attribute(window, kAXPositionAttribute) {
            AXValueGetValue(value, .cgPoint, &origin)
        }
        if let value: AXValue = attribute(window, kAXSizeAttribute) {
            AXValueGetValue(value, .cgSize, &size)
        }
        return CGRect(origin: origin, size: size)
    }

    private static func framesMatch(_ a: CGRect, _ b: CGRect) -> Bool {
        abs(a.minX - b.minX) < 2 && abs(a.minY - b.minY) < 2
            && abs(a.width - b.width) < 2 && abs(a.height - b.height) < 2
    }

    private static func attribute<T>(_ element: AXUIElement, _ name: String) -> T? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value as? T
    }
}
