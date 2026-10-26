import SwiftUI
import Photos
import UIKit

struct SlideshowView: View {
    @EnvironmentObject private var gallery: GalleryStore
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("autoplaySeconds") private var autoplaySeconds = 0
    @AppStorage("loopSlides") private var loopSlides = true
    @AppStorage("pencilFourTapBack") private var pencilFourTapBack = true
    @AppStorage("pencilTapWindow") private var pencilTapWindow = 0.95
    @StateObject private var pencilSequence = PencilGestureInterpreter()
    @State private var controlsVisible = false
    @State private var autoplayPaused = false
    @State private var photoReady = false
    @State private var clock = SlideshowClock()
    @State private var appActive = true
    @State private var settingsPresented = false
    private let ticker = Timer.publish(every: 0.25, on: .main, in: .common).autoconnect()
    private var currentAsset: PHAsset? {
        guard gallery.playbackAssets.indices.contains(gallery.currentIndex) else { return nil }
        return gallery.playbackAssets[gallery.currentIndex]
    }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                photoSurface(size: geometry.size)
                if controlsVisible { controls }
                if pencilSequence.waitingForSecondPair {
                    VStack {
                        Spacer()
                        Label("한 번 더 더블탭 → 이전 사진", systemImage: "arrow.uturn.backward")
                            .font(.system(size: 12, weight: .medium)).foregroundStyle(.white)
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(.black.opacity(0.75), in: Capsule())
                            .padding(.bottom, controlsVisible ? 88 : 28)
                    }.allowsHitTesting(false)
                }
            }
            .background(PencilDoubleTapBridge {
                guard appActive, scenePhase == .active, !settingsPresented else { return }
                clock.reset()
                pencilSequence.acceptDoubleTap(fourTapEnabled: pencilFourTapBack, window: pencilTapWindow,
                                               onNext: advanceNext, onPrevious: advancePrevious)
            })
            .onReceive(ticker) { _ in
                let allowed = appActive && scenePhase == .active && photoReady && !autoplayPaused && !settingsPresented && !pencilSequence.waitingForSecondPair
                if clock.tick(at: ProcessInfo.processInfo.systemUptime, interval: autoplaySeconds, allowed: allowed) {
                    advanceNext()
                }
            }
        }
        .ignoresSafeArea().background(.black)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear {
            cancelInput()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: autoplaySeconds) { _ in clock.reset(); autoplayPaused = false }
        .sheet(isPresented: $settingsPresented) { SlideshowSettingsView() }
        .onChange(of: settingsPresented) { _ in cancelInput() }
        .onChange(of: loopSlides) { _ in clock.reset() }
        .onChange(of: pencilFourTapBack) { _ in cancelInput() }
        .onChange(of: pencilTapWindow) { _ in cancelInput() }
        .onChange(of: scenePhase) { phase in
            if phase != .active { cancelInput() }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            appActive = false
            cancelInput()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            appActive = true
            clock.reset()
            UIApplication.shared.isIdleTimerDisabled = true
        }
    }
    private func photoSurface(size: CGSize) -> some View {
        ZStack {
            Color.black
            if let asset = currentAsset {
                AssetImage(asset: asset, contentMode: .aspectFit,
                           targetPixels: max(size.width, size.height) * UIScreen.main.scale,
                           onReadinessChanged: { ready in
                               guard currentAsset?.localIdentifier == asset.localIdentifier else { return }
                               photoReady = ready
                               clock.reset()
                           })
                    .id(asset.localIdentifier)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { controlsVisible.toggle() }
        .gesture(DragGesture(minimumDistance: 55).onEnded { value in
            guard abs(value.translation.width) > abs(value.translation.height) else { return }
            if value.translation.width < -60 { changeNext() }
            else if value.translation.width > 60 { changePrevious() }
        })
    }
    private var controls: some View {
        VStack {
            HStack(spacing: 14) {
                Button { cancelInput(); gallery.stopSlideshow() } label: {
                    Image(systemName: "xmark").frame(width: 46, height: 46)
                }.accessibilityLabel("슬라이드쇼 닫기")
                Spacer()
                Text("\(gallery.currentIndex + 1) / \(gallery.playbackAssets.count)")
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                Spacer()
                Button {
                    cancelInput()
                    if autoplaySeconds == 0 { autoplaySeconds = 5; autoplayPaused = false }
                    else { autoplayPaused.toggle() }
                } label: {
                    Image(systemName: autoplaySeconds > 0 && !autoplayPaused ? "pause.fill" : "play.fill")
                        .frame(width: 46, height: 46)
                }.accessibilityLabel(autoplaySeconds > 0 && !autoplayPaused ? "자동 재생 일시 정지" : "자동 재생 시작")
                options
            }
            .padding(12).background(.black.opacity(0.45))
            Spacer()
            HStack {
                Text(pencilFourTapBack ? "펜슬 ×2 다음 · ×4 이전" : "펜슬 ×2 다음")
                    .font(.caption).foregroundStyle(.white.opacity(0.65))
                Spacer()
                controlButton("이전 사진", symbol: "chevron.left", action: changePrevious)
                controlButton("다음 사진", symbol: "chevron.right", action: changeNext)
            }.padding(24).background(.black.opacity(0.35))
        }.foregroundStyle(.white)
    }
    private var options: some View {
        Button { cancelInput(); settingsPresented = true } label: {
            Image(systemName: "ellipsis").frame(width: 46, height: 46)
        }.accessibilityLabel("슬라이드쇼 옵션")
    }
    private func controlButton(_ title: String, symbol: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: 19, weight: .semibold))
                .frame(width: 50, height: 50).background(.white.opacity(0.14), in: Circle())
        }.accessibilityLabel(title)
    }
    private func cancelInput() { pencilSequence.cancelPending(); clock.reset() }
    private func changeNext() { cancelInput(); advanceNext() }
    private func changePrevious() { cancelInput(); advancePrevious() }
    private func advanceNext() {
        clock.reset()
        if !loopSlides && gallery.currentIndex == gallery.playbackAssets.count - 1 {
            autoplayPaused = true
            return
        }
        let old = gallery.currentIndex
        gallery.next(loop: loopSlides)
        if old != gallery.currentIndex { photoReady = false }
    }
    private func advancePrevious() {
        clock.reset()
        let old = gallery.currentIndex
        gallery.previous(loop: loopSlides)
        if old != gallery.currentIndex { photoReady = false }
    }
}

struct SlideshowSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("autoplaySeconds") private var autoplaySeconds = 0
    @AppStorage("loopSlides") private var loopSlides = true
    @AppStorage("pencilFourTapBack") private var pencilFourTapBack = true
    @AppStorage("pencilTapWindow") private var pencilTapWindow = 0.95
    var body: some View {
        NavigationStack {
            Form {
                Section("슬라이드쇼") {
                    Picker("자동 넘김", selection: $autoplaySeconds) {
                        Text("수동").tag(0)
                        Text("3초").tag(3)
                        Text("5초").tag(5)
                        Text("10초").tag(10)
                        Text("15초").tag(15)
                    }
                    Toggle("반복 재생", isOn: $loopSlides)
                }
                Section("Apple Pencil 2") {
                    Toggle("4회 탭으로 이전 사진", isOn: $pencilFourTapBack)
                    if pencilFourTapBack {
                        Picker("연속 더블탭 간격", selection: $pencilTapWindow) {
                            Text("0.7초").tag(0.7)
                            Text("0.95초 · 기본").tag(0.95)
                            Text("1.25초").tag(1.25)
                        }
                        Text("첫 더블탭 후 설정 시간만큼 기다립니다. 그 안에 한 번 더 더블탭하면 이전 사진만 표시합니다.")
                            .font(.footnote).foregroundStyle(.secondary)
                    } else {
                        Text("더블탭 즉시 다음 사진으로 이동합니다.").font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("슬라이드쇼 옵션")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
        }
        .preferredColorScheme(.dark).tint(Theme.accent).statusBarHidden(true)
    }
}
