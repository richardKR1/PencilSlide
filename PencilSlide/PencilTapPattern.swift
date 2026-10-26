import Foundation

// Each UIKit callback represents two physical taps. Time is monotonic.
struct PencilTapPattern {
    enum Decision: Equatable { case next, previous, waitForAnother, nextThenWait }
    private(set) var pendingDeadline: TimeInterval?
    mutating func receiveDoubleTap(at now: TimeInterval, fourTapEnabled: Bool, window: TimeInterval) -> Decision {
        guard fourTapEnabled else { clear(); return .next }
        let interval = Self.validWindow(window)
        if let deadline = pendingDeadline {
            if now < deadline { clear(); return .previous }
            pendingDeadline = now + interval
            return .nextThenWait
        }
        pendingDeadline = now + interval
        return .waitForAnother
    }
    mutating func commitPendingNext(at now: TimeInterval) -> Bool {
        guard let deadline = pendingDeadline, now >= deadline else { return false }
        clear()
        return true
    }
    mutating func clear() { pendingDeadline = nil }
    static func validWindow(_ value: TimeInterval) -> TimeInterval {
        [0.7, 0.95, 1.25].contains(value) ? value : 0.95
    }
}
