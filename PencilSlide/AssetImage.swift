import SwiftUI
import Photos
import UIKit

@MainActor
final class AssetImageLoader: ObservableObject {
    @Published var image: UIImage?
    @Published var message: String?
    private var requestID: PHImageRequestID = PHInvalidImageRequestID
    private var generation = UUID()
    private static let manager = PHCachingImageManager()
    func load(_ asset: PHAsset, contentMode: PHImageContentMode, targetPixels: CGFloat) {
        cancel()
        image = nil
        message = nil
        let token = generation
        let options = PHImageRequestOptions()
        options.deliveryMode = contentMode == .aspectFit ? .highQualityFormat : .opportunistic
        options.resizeMode = .exact
        options.version = .current
        options.isNetworkAccessAllowed = true
        options.isSynchronous = false
        let side = max(targetPixels, 240)
        requestID = Self.manager.requestImage(for: asset, targetSize: CGSize(width: side, height: side), contentMode: contentMode, options: options) { [weak self] result, info in
            let cancelled = (info?[PHImageCancelledKey] as? Bool) == true
            let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) == true
            let failed = info?[PHImageErrorKey] != nil
            DispatchQueue.main.async {
                guard let self, self.generation == token, !cancelled else { return }
                if let result { self.image = result; self.message = nil }
                else if failed || !degraded {
                    self.message = "사진을 불러오지 못했습니다.\niCloud 연결 또는 사진 접근 권한을 확인하세요."
                }
            }
        }
    }
    func cancel() {
        generation = UUID()
        if requestID != PHInvalidImageRequestID { Self.manager.cancelImageRequest(requestID) }
        requestID = PHInvalidImageRequestID
    }
}

struct AssetImage: View {
    let asset: PHAsset
    let contentMode: PHImageContentMode
    let targetPixels: CGFloat
    var onReadinessChanged: ((Bool) -> Void)? = nil
    @StateObject private var loader = AssetImageLoader()
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black
                if let image = loader.image {
                    Image(uiImage: image).resizable()
                        .aspectRatio(contentMode: contentMode == .aspectFill ? .fill : .fit)
                        .frame(width: proxy.size.width, height: proxy.size.height).clipped()
                } else if let message = loader.message {
                    VStack(spacing: 12) {
                        Text(message).font(.footnote).multilineTextAlignment(.center)
                        Button("다시 시도", action: load)
                    }.foregroundStyle(.white.opacity(0.8)).padding()
                } else { ProgressView().tint(.white) }
            }
        }
        .onAppear(perform: load)
        .onChange(of: asset.localIdentifier) { _ in load() }
        .onChange(of: asset.modificationDate) { _ in load() }
        .onChange(of: targetPixels) { _ in load() }
        .onReceive(loader.$image) { image in onReadinessChanged?(image != nil) }
        .onDisappear { loader.cancel(); onReadinessChanged?(false) }
    }
    private func load() {
        onReadinessChanged?(false)
        loader.load(asset, contentMode: contentMode, targetPixels: targetPixels)
    }
}
