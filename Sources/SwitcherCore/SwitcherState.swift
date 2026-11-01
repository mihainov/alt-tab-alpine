/// Selection logic of one Option+Tab session, without UI.
public struct SwitcherState: Equatable {
    public private(set) var count = 0
    public private(set) var selectedIndex: Int?

    public var isActive: Bool { selectedIndex != nil }

    public init() {}

    /// Starts a session. Index 1 is the previous window; with one window it is index 0.
    public mutating func start(count: Int) {
        guard count > 0 else {
            self = SwitcherState()
            return
        }
        self.count = count
        selectedIndex = count > 1 ? 1 : 0
    }

    public mutating func next() {
        guard let index = selectedIndex else { return }
        selectedIndex = (index + 1) % count
    }

    /// Ends the session and returns the selected index.
    public mutating func commit() -> Int? {
        let index = selectedIndex
        self = SwitcherState()
        return index
    }
}
