import AppKit

@MainActor
final class SwitcherPanel {
    private static let maxIconSize: CGFloat = 64
    private static let itemPadding: CGFloat = 10
    private static let spacing: CGFloat = 8
    private static let margin: CGFloat = 20
    private static let titleHeight: CGFloat = 22

    private let panel: NSPanel
    private let background = NSVisualEffectView()
    private let row = NSStackView()
    private let titleLabel = NSTextField(labelWithString: "")
    private var items: [NSView] = []
    private var titles: [String] = []

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
        background.layer?.cornerRadius = 16
        background.layer?.masksToBounds = true

        row.orientation = .horizontal
        row.spacing = Self.spacing

        titleLabel.alignment = .center
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = .labelColor

        background.addSubview(row)
        background.addSubview(titleLabel)
        panel.contentView = background
    }

    var isVisible: Bool { panel.isVisible }

    func show(windows: [WindowItem], selected: Int) {
        let screen = screenWithMouse()
        let visible = screen.visibleFrame
        let count = CGFloat(windows.count)
        let available = visible.width * 0.9 - 2 * Self.margin - (count - 1) * Self.spacing
        let itemSize = min(Self.maxIconSize + 2 * Self.itemPadding, available / count)
        let iconSize = max(16, itemSize - 2 * Self.itemPadding)

        items.forEach { $0.removeFromSuperview() }
        items = windows.map { makeItem(icon: $0.app.icon, size: itemSize, iconSize: iconSize) }
        items.forEach { row.addArrangedSubview($0) }
        titles = windows.map(\.title)

        let rowWidth = count * itemSize + (count - 1) * Self.spacing
        let width = max(rowWidth + 2 * Self.margin, 240)
        let height = Self.margin + itemSize + Self.spacing + Self.titleHeight + Self.margin
        row.frame = NSRect(x: (width - rowWidth) / 2, y: Self.margin + Self.titleHeight + Self.spacing,
                           width: rowWidth, height: itemSize)
        titleLabel.frame = NSRect(x: Self.margin, y: Self.margin,
                                  width: width - 2 * Self.margin, height: Self.titleHeight)

        let origin = NSPoint(x: visible.midX - width / 2, y: visible.midY - height / 2)
        panel.setFrame(NSRect(origin: origin, size: NSSize(width: width, height: height)), display: false)
        select(selected)
        panel.orderFrontRegardless()
    }

    func select(_ index: Int) {
        for (i, item) in items.enumerated() {
            item.layer?.backgroundColor = i == index
                ? NSColor.white.withAlphaComponent(0.25).cgColor
                : NSColor.clear.cgColor
        }
        titleLabel.stringValue = titles.indices.contains(index) ? titles[index] : ""
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func makeItem(icon: NSImage?, size: CGFloat, iconSize: CGFloat) -> NSView {
        let container = NSView()
        container.wantsLayer = true
        container.layer?.cornerRadius = 10
        container.translatesAutoresizingMaskIntoConstraints = false
        let imageView = NSImageView()
        imageView.image = icon
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(imageView)
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: size),
            container.heightAnchor.constraint(equalToConstant: size),
            imageView.widthAnchor.constraint(equalToConstant: iconSize),
            imageView.heightAnchor.constraint(equalToConstant: iconSize),
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])
        return container
    }

    private func screenWithMouse() -> NSScreen {
        let mouse = NSEvent.mouseLocation
        return NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) }
            ?? NSScreen.main
            ?? NSScreen.screens[0]
    }
}
