import SwiftUI
import UIKit

@MainActor
final class PencilGestureInterpreter: ObservableObject {
    @Published private(set) var waitingForSecondPair = false
    private var pattern = PencilTapPattern()
    private var scheduled: DispatchWorkItem?
    private var generation: UInt64 = 0
    func acceptDoubleTap(fourTapEnabled: Bool, window: Double, onNext: @escaping () -> Void, onPrevious: @escaping () -> Void) {
        invalidateTimer()
        let decision = pattern.receiveDoubleTap(at: ProcessInfo.processInfo.systemUptime, fourTapEnabled: fourTapEnabled, window: window)
        switch decision {
        case .next: waitingForSecondPair = false; onNext()
        case .previous: waitingForSecondPair = false; onPrevious()
        case .waitForAnother: scheduleNext(onNext: onNext)
        case .nextThenWait: onNext(); scheduleNext(onNext: onNext)
        }
    }
    private func scheduleNext(onNext: @escaping () -> Void) {
        guard let deadline = pattern.pendingDeadline else { return }
        waitingForSecondPair = true
        let token = generation
        let delay = max(0.001, deadline - ProcessInfo.processInfo.systemUptime)
        let work = DispatchWorkItem { [weak self] in
            guard let self, self.generation == token else { return }
            self.scheduled = nil
            if self.pattern.commitPendingNext(at: ProcessInfo.processInfo.systemUptime) {
                self.waitingForSecondPair = false
                onNext()
            } else { self.scheduleNext(onNext: onNext) }
        }
        scheduled = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
    private func invalidateTimer() {
        generation &+= 1
        scheduled?.cancel()
        scheduled = nil
    }
    func cancelPending() {
        invalidateTimer()
        pattern.clear()
        waitingForSecondPair = false
    }
}

// Attach to the real window; this view never intercepts touch events.
struct PencilDoubleTapBridge: UIViewRepresentable {
    var onDoubleTap: () -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onDoubleTap: onDoubleTap) }
    func makeUIView(context: Context) -> AttachmentView {
        let view = AttachmentView(frame: .zero)
        view.onWindowChange = { [weak coordinator = context.coordinator] window in coordinator?.mount(on: window) }
        return view
    }
    func updateUIView(_ view: AttachmentView, context: Context) {
        context.coordinator.onDoubleTap = onDoubleTap
        context.coordinator.mount(on: view.window)
    }
    static func dismantleUIView(_ view: AttachmentView, coordinator: Coordinator) {
        coordinator.mount(on: nil)
        view.onWindowChange = nil
    }
    final class AttachmentView: UIView {
        var onWindowChange: ((UIWindow?) -> Void)?
        override func didMoveToWindow() { super.didMoveToWindow(); onWindowChange?(window) }
        override func point(inside point: CGPoint, with event: UIEvent?) -> Bool { false }
    }
    final class Coordinator: NSObject, UIPencilInteractionDelegate {
        var onDoubleTap: () -> Void
        private weak var installedWindow: UIWindow?
        private lazy var interaction: UIPencilInteraction = {
            let value = UIPencilInteraction()
            value.delegate = self
            value.isEnabled = true
            return value
        }()
        init(onDoubleTap: @escaping () -> Void) { self.onDoubleTap = onDoubleTap }
        func mount(on window: UIWindow?) {
            guard installedWindow !== window else { return }
            installedWindow?.removeInteraction(interaction)
            installedWindow = window
            window?.addInteraction(interaction)
        }
        // UIKit calls only the modern method when both are implemented.
        func pencilInteractionDidTap(_ interaction: UIPencilInteraction) { onDoubleTap() }
        @available(iOS 17.5, *)
        func pencilInteraction(_ interaction: UIPencilInteraction, didReceiveTap tap: UIPencilInteraction.Tap) { onDoubleTap() }
    }
}
