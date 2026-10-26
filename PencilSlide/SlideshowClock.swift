import Foundation

// An unresolved gesture, loading, inactivity, or manual input resets the clock.
struct SlideshowClock {
    private(set) var deadline: TimeInterval?
    mutating func reset() { deadline = nil }
    mutating func tick(at now: TimeInterval, interval: Int, allowed: Bool) -> Bool {
        guard allowed, [3, 5, 10, 15].contains(interval) else { reset(); return false }
        guard let deadline else { self.deadline = now + Double(interval); return false }
        guard now >= deadline else { return false }
        self.deadline = now + Double(interval)
        return true
    }
}
