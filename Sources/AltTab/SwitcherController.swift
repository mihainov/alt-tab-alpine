import AppKit
import SwitcherCore

@MainActor
final class SwitcherController {
    private static let panelDelay: TimeInterval = 0.15

    private let panel = SwitcherPanel()
    private var state = SwitcherState()
    private var windows: [WindowItem] = []
    private var panelTimer: Timer?

    func onTab() {
        if state.isActive {
            state.next()
            if panel.isVisible, let index = state.selectedIndex { panel.select(index) }
            return
        }
        windows = WindowList.current()
        guard !windows.isEmpty else { return }
        state.start(count: windows.count)
        panelTimer = Timer.scheduledTimer(withTimeInterval: Self.panelDelay, repeats: false) { _ in
            MainActor.assumeIsolated { self.showPanel() }
        }
    }

    func onOptionReleased() {
        panelTimer?.invalidate()
        panelTimer = nil
        panel.hide()
        guard let index = state.commit(), windows.indices.contains(index) else { return }
        let target = windows[index]
        windows = []
        WindowList.focus(target)
    }

    private func showPanel() {
        panelTimer = nil
        guard let index = state.selectedIndex else { return }
        panel.show(windows: windows, selected: index)
    }
}
