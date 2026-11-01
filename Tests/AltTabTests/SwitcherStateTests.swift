import Testing
@testable import SwitcherCore

@Suite struct SwitcherStateTests {
    @Test func idleByDefault() {
        let state = SwitcherState()
        #expect(!state.isActive)
        #expect(state.selectedIndex == nil)
    }

    @Test func startSelectsPreviousWindow() {
        var state = SwitcherState()
        state.start(count: 3)
        #expect(state.isActive)
        #expect(state.selectedIndex == 1)
    }

    @Test func startWithOneWindowSelectsIt() {
        var state = SwitcherState()
        state.start(count: 1)
        #expect(state.selectedIndex == 0)
    }

    @Test func startWithNoWindowsStaysIdle() {
        var state = SwitcherState()
        state.start(count: 0)
        #expect(!state.isActive)
        #expect(state.commit() == nil)
    }

    @Test func nextWrapsAround() {
        var state = SwitcherState()
        state.start(count: 3)
        state.next()
        #expect(state.selectedIndex == 2)
        state.next()
        #expect(state.selectedIndex == 0)
        state.next()
        #expect(state.selectedIndex == 1)
    }

    @Test func nextWithOneWindowStaysOnIt() {
        var state = SwitcherState()
        state.start(count: 1)
        state.next()
        #expect(state.selectedIndex == 0)
    }

    @Test func nextWhenIdleDoesNothing() {
        var state = SwitcherState()
        state.next()
        #expect(state == SwitcherState())
    }

    @Test func commitReturnsSelectionAndResets() {
        var state = SwitcherState()
        state.start(count: 4)
        state.next()
        state.next()
        #expect(state.commit() == 3)
        #expect(!state.isActive)
        #expect(state.commit() == nil)
    }
}
