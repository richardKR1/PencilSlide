import Foundation

var checks = 0
func expect(_ condition: @autoclosure () -> Bool, _ label: String) {
    checks += 1
    guard condition() else { fatalError("FAILED: \(label)") }
}
for interval in [0.7, 0.95, 1.25] {
    var pattern = PencilTapPattern()
    expect(pattern.receiveDoubleTap(at: 10, fourTapEnabled: true, window: interval) == .waitForAnother, "first pair waits")
    expect(!pattern.commitPendingNext(at: 10 + interval - 0.001), "no premature next")
    expect(pattern.receiveDoubleTap(at: 10 + interval - 0.001, fourTapEnabled: true, window: interval) == .previous, "four physical taps = previous only")
    expect(!pattern.commitPendingNext(at: 100), "no next after previous")
    expect(pattern.receiveDoubleTap(at: 20, fourTapEnabled: true, window: interval) == .waitForAnother, "new sequence")
    expect(pattern.commitPendingNext(at: 20 + interval), "single pair expires once")
    expect(!pattern.commitPendingNext(at: 100), "cannot expire twice")
    expect(pattern.receiveDoubleTap(at: 30, fourTapEnabled: true, window: interval) == .waitForAnother, "first late pair")
    expect(pattern.receiveDoubleTap(at: 30 + interval, fourTapEnabled: true, window: interval) == .nextThenWait, "deadline is exclusive for second pair")
    expect(pattern.commitPendingNext(at: 30 + 2 * interval + 0.01), "late pair gets its own next")
    expect(!pattern.commitPendingNext(at: 100), "late pair cannot double commit")
    _ = pattern.receiveDoubleTap(at: 100, fourTapEnabled: true, window: interval)
    pattern.clear()
    expect(!pattern.commitPendingNext(at: 200), "cancelled input never advances")
}
var pattern = PencilTapPattern()
expect(pattern.receiveDoubleTap(at: 0, fourTapEnabled: false, window: 0.95) == .next, "disabled mode is immediate")
expect(pattern.receiveDoubleTap(at: 0.1, fourTapEnabled: false, window: 0.95) == .next, "disabled mode never reverses")
_ = pattern.receiveDoubleTap(at: 1, fourTapEnabled: true, window: 0.95)
expect(pattern.receiveDoubleTap(at: 1.2, fourTapEnabled: false, window: 0.95) == .next, "disable during pending clears pair")
expect(!pattern.commitPendingNext(at: 3), "no ghost expiry after disable")
expect(PencilTapPattern.validWindow(.nan) == 0.95, "invalid setting defaults safely")
expect(PencilTapPattern.validWindow(9) == 0.95, "unsupported setting defaults safely")
var sixTaps = PencilTapPattern()
expect(sixTaps.receiveDoubleTap(at: 0, fourTapEnabled: true, window: 0.95) == .waitForAnother, "six taps first pair")
expect(sixTaps.receiveDoubleTap(at: 0.3, fourTapEnabled: true, window: 0.95) == .previous, "six taps first two pairs")
expect(sixTaps.receiveDoubleTap(at: 0.6, fourTapEnabled: true, window: 0.95) == .waitForAnother, "six taps third pair is new sequence")
expect(sixTaps.commitPendingNext(at: 1.55), "six taps end with one next")
for seconds in [3, 5, 10, 15] {
    var clock = SlideshowClock()
    expect(!clock.tick(at: 0, interval: seconds, allowed: true), "clock starts without advancing")
    expect(!clock.tick(at: Double(seconds) - 0.01, interval: seconds, allowed: true), "full viewing interval")
    expect(clock.tick(at: Double(seconds), interval: seconds, allowed: true), "advance on deadline")
    expect(!clock.tick(at: 100, interval: seconds, allowed: false), "pending gesture/loading/inactive blocks autoplay")
    expect(!clock.tick(at: 101, interval: seconds, allowed: true), "resume starts a full interval")
    expect(!clock.tick(at: 101.1, interval: seconds, allowed: true), "no catchup after block")
    clock.reset()
    expect(!clock.tick(at: 102, interval: seconds, allowed: true), "manual input resets deadline")
}
var clock = SlideshowClock()
expect(!clock.tick(at: 1, interval: 0, allowed: true), "manual mode")
expect(!clock.tick(at: 100, interval: 0, allowed: true), "manual mode never advances")
print("PASS: \(checks) deterministic production-core checks")
