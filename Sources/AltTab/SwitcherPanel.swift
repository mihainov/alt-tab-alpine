import AppKit

@MainActor
final class SwitcherPanel {
    private static let maxRowHeight: CGFloat = 40
    private static let minRowHeight: CGFloat = 22
    private static let rowSpacing: CGFloat = 2
    private static let rowPadding: CGFloat = 8
    private static let margin: CGFloat = 10
    private static let width: CGFloat = 520

    private let panel: NSPanel
    private let background = NSVisualEffectView()
    private var rows: [NSView] = []

    init() {
        panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        panel.level = .popUpMenu
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.ignoresMouseEvents = true

        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 14
        background.layer?.masksToBounds = true
        panel.contentView = background
    }

    var isVisible: Bool { panel.isVisible }

    func show(windows: [WindowItem], selected: Int) {
        let visible = screenWithMouse().visibleFrame
        let count = CGFloat(windows.count)
        let available = (visible.height * 0.9 - 2 * Self.margin - (count - 1) * Self.rowSpacing) / count
        let rowHeight = max(Self.minRowHeight, min(Self.maxRowHeight, available))
        let width = min(Self.width, visible.width * 0.9)
        let height = 2 * Self.margin + count * rowHeight + (count - 1) * Self.rowSpacing

        rows.forEach { $0.removeFromSuperview() }
        rows = windows.enumerated().map { index, window in
            // AppKit y grows upward, so the first window is at the top.
            let y = height - Self.margin - CGFloat(index + 1) * rowHeight - CGFloat(index) * Self.rowSpacing
            let frame = NSRect(x: Self.margin, y: y, width: width - 2 * Self.margin, height: rowHeight)
            return makeRow(window: window, frame: frame)
        }
        rows.forEach { background.addSubview($0) }

        let origin = NSPoint(x: visible.midX - width / 2, y: visible.midY - height / 2)
        panel.setFrame(NSRect(origin: origin, size: NSSize(width: width, height: height)), display: false)
        select(selected)
        panel.orderFrontRegardless()
    }

    func select(_ index: Int) {
        for (i, row) in rows.enumerated() {
            row.layer?.backgroundColor = i == index
                ? NSColor.white.withAlphaComponent(0.25).cgColor
                : NSColor.clear.cgColor
        }
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func makeRow(window: WindowItem, frame: NSRect) -> NSView {
        let row = NSView(frame: frame)
        row.wantsLayer = true
        row.layer?.cornerRadius = 8

        let iconSize = frame.height - 8
        let icon = NSImageView(frame: NSRect(x: Self.rowPadding, y: 4, width: iconSize, height: iconSize))
        icon.image = window.app.icon
        icon.imageScaling = .scaleProportionallyUpOrDown
        row.addSubview(icon)

        let appName = window.app.localizedName ?? ""
        let appLabel = NSTextField(labelWithString: window.title == appName ? "" : appName)
        appLabel.font = .systemFont(ofSize: 12)
        appLabel.textColor = .secondaryLabelColor
        appLabel.alignment = .right
        appLabel.sizeToFit()
        let appWidth = min(appLabel.frame.width, frame.width * 0.3)

        let textX = icon.frame.maxX + Self.rowPadding
        let appX = frame.width - Self.rowPadding - appWidth
        let fontSize: CGFloat = frame.height >= 32 ? 14 : 12

        let titleLabel = NSTextField(labelWithString: window.title)
        titleLabel.font = .systemFont(ofSize: fontSize, weight: .medium)
        titleLabel.textColor = .labelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.sizeToFit()
        let titleHeight = titleLabel.frame.height
        titleLabel.frame = NSRect(x: textX, y: (frame.height - titleHeight) / 2,
                                  width: appX - Self.rowPadding - textX, height: titleHeight)
        row.addSubview(titleLabel)

        appLabel.lineBreakMode = .byTruncatingTail
        let appHeight = appLabel.frame.height
        appLabel.frame = NSRect(x: appX, y: (frame.height - appHeight) / 2, width: appWidth, height: appHeight)
        row.addSubview(appLabel)

        return row
    }

    private func screenWithMouse() -> NSScreen {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }
}
