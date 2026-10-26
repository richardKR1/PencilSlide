import SwiftUI
import Photos
import UIKit

// MARK: - Visual system
enum Theme {
    static let background = Color(red: 0.050, green: 0.063, blue: 0.079)
    static let surface = Color(red: 0.093, green: 0.112, blue: 0.135)
    static let raised = Color(red: 0.135, green: 0.155, blue: 0.180)
    static let muted = Color(red: 0.61, green: 0.65, blue: 0.69)
    static let accent = Color(red: 0.56, green: 0.95, blue: 0.83)
    static let border = Color.white.opacity(0.085)
}

@main
struct PencilSlideApp: App {
    @StateObject private var gallery = GalleryStore()

    var body: some Scene {
        WindowGroup {
            AppRootView()
                .environmentObject(gallery)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
                .statusBarHidden(true)
                .persistentSystemOverlays(.hidden)
        }
    }
}

// MARK: - Photo library / slideshow data
struct PhotoAlbum: Identifiable {
    let id: String
    let title: String
    let collection: PHAssetCollection?
    let count: Int
    let cover: PHAsset?
    let typeLabel: String
}

@MainActor
final class GalleryStore: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    @Published var authorization: PHAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
    @Published var albums: [PhotoAlbum] = []
    @Published var activeAlbum: PhotoAlbum?
    @Published var assets: [PHAsset] = []
    @Published var chosenIdentifiers: [String] = []
    @Published var playbackAssets: [PHAsset] = []
    @Published var currentIndex = 0
    @Published var isPresenting = false
    @Published var sortNewestFirst: Bool = UserDefaults.standard.bool(forKey: "sortNewestFirst")

    override init() {
        super.init()
        PHPhotoLibrary.shared().register(self)
        if hasPhotoAccess { refreshAlbums() }
    }

    deinit { PHPhotoLibrary.shared().unregisterChangeObserver(self) }

    nonisolated func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async { [weak self] in self?.refreshLibraryState() }
    }

    func refreshLibraryState() {
        authorization = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        guard hasPhotoAccess else {
            isPresenting = false
            playbackAssets = []
            albums = []
            assets = []
            activeAlbum = nil
            chosenIdentifiers = []
            return
        }
        refreshAlbums()
        if let album = activeAlbum {
            if let updated = albums.first(where: { $0.id == album.id }) { open(updated) }
            else { activeAlbum = nil; assets = []; chosenIdentifiers = [] }
        }
        if isPresenting {
            let currentID = playbackAssets.indices.contains(currentIndex) ? playbackAssets[currentIndex].localIdentifier : nil
            let ids = playbackAssets.map(\.localIdentifier)
            let result = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
            var lookup: [String: PHAsset] = [:]
            result.enumerateObjects { asset, _, _ in lookup[asset.localIdentifier] = asset }
            playbackAssets = ids.compactMap { lookup[$0] }
            if playbackAssets.isEmpty { isPresenting = false; currentIndex = 0 }
            else { currentIndex = currentID.flatMap { id in playbackAssets.firstIndex(where: { $0.localIdentifier == id }) } ?? min(currentIndex, playbackAssets.count - 1) }
        }
    }

    func manageLimitedAccess() {
        guard authorization == .limited,
              let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first(where: { $0.activationState == .foregroundActive }),
              var controller = scene.windows.first(where: \.isKeyWindow)?.rootViewController else { return }
        while let presented = controller.presentedViewController { controller = presented }
        PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: controller)
    }

    func openSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func moveSelection(from offsets: IndexSet, to destination: Int) {
        chosenIdentifiers.move(fromOffsets: offsets, toOffset: destination)
        saveSelection()
    }

    func removeSelection(at offsets: IndexSet) {
        chosenIdentifiers.remove(atOffsets: offsets)
        saveSelection()
    }

    var hasPhotoAccess: Bool {
        authorization == .authorized || authorization == .limited
    }

    func requestPhotoAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
            DispatchQueue.main.async {
                self?.authorization = status
                if status == .authorized || status == .limited {
                    self?.refreshAlbums()
                }
            }
        }
    }

    private func fetchPhotos(in collection: PHAssetCollection? = nil) -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: !sortNewestFirst)]
        if let collection = collection {
            return PHAsset.fetchAssets(in: collection, options: options)
        }
        return PHAsset.fetchAssets(with: options)
    }

    func refreshAlbums() {
        guard hasPhotoAccess else { return }
        var items: [PhotoAlbum] = []
        let all = fetchPhotos()
        items.append(PhotoAlbum(id: "__all__", title: "모든 사진", collection: nil,
                                count: all.count, cover: all.firstObject,
                                typeLabel: "라이브러리"))

        let smartAlbums = PHAssetCollection.fetchAssetCollections(
            with: .smartAlbum, subtype: .any, options: nil)
        smartAlbums.enumerateObjects { collection, _, _ in
            let photos = self.fetchPhotos(in: collection)
            if photos.count > 0 && collection.assetCollectionSubtype != .smartAlbumUserLibrary {
                items.append(PhotoAlbum(id: collection.localIdentifier,
                                        title: collection.localizedTitle ?? "스마트 앨범",
                                        collection: collection, count: photos.count,
                                        cover: photos.firstObject, typeLabel: "스마트 앨범"))
            }
        }

        let userAlbums = PHAssetCollection.fetchAssetCollections(
            with: .album, subtype: .any, options: nil)
        var custom: [PhotoAlbum] = []
        userAlbums.enumerateObjects { collection, _, _ in
            let photos = self.fetchPhotos(in: collection)
            if photos.count > 0 {
                custom.append(PhotoAlbum(id: collection.localIdentifier,
                                         title: collection.localizedTitle ?? "이름 없는 앨범",
                                         collection: collection, count: photos.count,
                                         cover: photos.firstObject, typeLabel: "나의 앨범"))
            }
        }
        items.append(contentsOf: custom.sorted {
            $0.title.localizedStandardCompare($1.title) == .orderedAscending
        })
        albums = items
    }

    func open(_ album: PhotoAlbum) {
        activeAlbum = album
        let result = fetchPhotos(in: album.collection)
        var newAssets: [PHAsset] = []
        newAssets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in newAssets.append(asset) }
        assets = newAssets

        let existing = Set(newAssets.map(\.localIdentifier))
        let stored = UserDefaults.standard.stringArray(forKey: selectionKey(album.id)) ?? []
        chosenIdentifiers = stored.filter { existing.contains($0) }
    }

    func returnToAlbums() {
        activeAlbum = nil
        assets = []
        chosenIdentifiers = []
        refreshAlbums()
    }

    func changeSortOrder() {
        sortNewestFirst.toggle()
        UserDefaults.standard.set(sortNewestFirst, forKey: "sortNewestFirst")
        if let album = activeAlbum {
            open(album)
        } else {
            refreshAlbums()
        }
    }

    func toggleSelection(_ identifier: String) {
        if let index = chosenIdentifiers.firstIndex(of: identifier) {
            chosenIdentifiers.remove(at: index)
        } else {
            chosenIdentifiers.append(identifier)
        }
        saveSelection()
    }

    func selectAll() {
        chosenIdentifiers = assets.map(\.localIdentifier)
        saveSelection()
    }

    func clearSelection() {
        chosenIdentifiers = []
        saveSelection()
    }

    private func selectionKey(_ albumID: String) -> String {
        "PencilSlide.selection.\(albumID)"
    }

    private func saveSelection() {
        guard let album = activeAlbum else { return }
        UserDefaults.standard.set(chosenIdentifiers, forKey: selectionKey(album.id))
    }

    func startSlideshow() {
        guard !assets.isEmpty else { return }
        // Selection order is presentation order; if none are selected, play the whole album.
        if chosenIdentifiers.isEmpty {
            playbackAssets = assets
        } else {
            let lookup = Dictionary(uniqueKeysWithValues: assets.map { ($0.localIdentifier, $0) })
            playbackAssets = chosenIdentifiers.compactMap { lookup[$0] }
        }
        guard !playbackAssets.isEmpty else { return }
        currentIndex = 0
        isPresenting = true
    }

    func stopSlideshow() { isPresenting = false }

    func next(loop: Bool) {
        guard !playbackAssets.isEmpty else { return }
        if currentIndex + 1 < playbackAssets.count {
            currentIndex += 1
        } else if loop {
            currentIndex = 0
        }
    }

    func previous(loop: Bool) {
        guard !playbackAssets.isEmpty else { return }
        if currentIndex > 0 {
            currentIndex -= 1
        } else if loop {
            currentIndex = playbackAssets.count - 1
        }
    }
}

// MARK: - Root / permissions
struct AppRootView: View {
    @EnvironmentObject private var gallery: GalleryStore

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            if gallery.isPresenting {
                SlideshowView()
            } else if !gallery.hasPhotoAccess {
                PhotoPermissionView()
            } else if gallery.activeAlbum != nil {
                PhotoSelectionView()
            } else {
                AlbumBrowserView()
            }
        }
        .animation(.easeInOut(duration: 0.19), value: gallery.isPresenting)
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            gallery.refreshLibraryState()
        }
    }
}

struct BrandHeading: View {
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "rectangle.on.rectangle.angled")
                    .font(.system(size: 25, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                Text("PencilSlide")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .tracking(-1.25)
            }
            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Theme.muted)
        }
    }
}

struct PhotoPermissionView: View {
    @EnvironmentObject private var gallery: GalleryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 25) {
            BrandHeading(subtitle: "애플펜슬로 사진을 넘기는 가장 간결한 방법")
            Spacer()
            Image(systemName: "photo.stack.fill")
                .font(.system(size: 76, weight: .ultraLight))
                .foregroundStyle(Theme.accent)
                .frame(width: 120, height: 120)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: 30))
            Text("사진은 그대로.\n넘기는 방법만 새롭게.")
                .font(.system(size: 43, weight: .bold, design: .rounded))
                .tracking(-1.5)
                .fixedSize(horizontal: false, vertical: true)
            Text("아이패드 사진 보관함의 앨범을 선택하세요. 사진을 별도 파일로 변환하지 않고, 애플펜슬 측면 더블탭으로 다음 사진을 보여줍니다.")
                .font(.system(size: 17))
                .foregroundStyle(Theme.muted)
                .fixedSize(horizontal: false, vertical: true)
            Button(action: gallery.requestPhotoAccess) {
                HStack(spacing: 10) {
                    Text("사진 보관함 연결")
                    Image(systemName: "arrow.right")
                }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.background)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: 16))
            }
            Text("사진은 이 기기에서만 표시됩니다. 별도 서버에 업로드하지 않습니다.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.muted)
            if gallery.authorization == .denied || gallery.authorization == .restricted {
                Button("설정에서 사진 접근 허용", action: gallery.openSettings)
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
            Spacer()
        }
        .frame(maxWidth: 560, alignment: .leading)
        .padding(32)
    }
}

// MARK: - Album browser
struct AlbumBrowserView: View {
    @EnvironmentObject private var gallery: GalleryStore
    private let columns = [GridItem(.adaptive(minimum: 210, maximum: 310), spacing: 18)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 35) {
                HStack(alignment: .top) {
                    BrandHeading(subtitle: "보관함에서 앨범을 선택하면 바로 시작할 수 있어요")
                    Spacer()
                    Text("01 / 앨범 선택")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                }
                if gallery.authorization == .limited {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("일부 사진만 허용되어 있습니다. 앨범 전체를 보려면 설정에서 전체 접근을 허용하세요.")
                        HStack {
                            Button("허용할 사진 관리", action: gallery.manageLimitedAccess)
                            Button("사진 접근 설정", action: gallery.openSettings)
                        }
                    }.font(.footnote).foregroundStyle(Theme.muted)
                }
                VStack(alignment: .leading, spacing: 16) {
                    Text("내 사진 라이브러리")
                        .font(.system(size: 22, weight: .semibold))
                    Text("원본을 사용합니다. PDF 변환이나 사진 복사는 필요하지 않습니다.")
                        .font(.system(size: 14))
                        .foregroundStyle(Theme.muted)
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(gallery.albums) { album in
                            Button { gallery.open(album) } label: {
                                AlbumCard(album: album)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                if gallery.albums.isEmpty {
                    HStack(spacing: 10) {
                        Image(systemName: "photo.on.rectangle.angled")
                        Text("표시할 사진이 없습니다. 사진 보관함에 사진을 추가해 주세요.")
                    }
                    .font(.subheadline)
                    .foregroundStyle(Theme.muted)
                    .padding(22)
                }
                HStack(spacing: 8) {
                    Image(systemName: "pencil.tip.crop.circle")
                        .foregroundStyle(Theme.accent)
                    Text("APPLE PENCIL 2 · 더블탭 다음 · 연속 더블탭 이전")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundStyle(Theme.muted)
                }
                .padding(.top, 14)
            }
            .padding(32)
        }
        .background(Theme.background)
    }
}

struct AlbumCard: View {
    let album: PhotoAlbum

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 17).fill(Theme.raised)
                if let cover = album.cover {
                    AssetImage(asset: cover, contentMode: .aspectFill, targetPixels: 540)
                        .frame(height: 185)
                        .frame(maxWidth: .infinity)
                        .clipped()
                } else {
                    Image(systemName: "photo")
                        .foregroundStyle(Theme.muted)
                }
                LinearGradient(colors: [.clear, .black.opacity(0.35)],
                               startPoint: .center, endPoint: .bottom)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.black.opacity(0.35), in: Circle())
                    .padding(12)
            }
            .frame(height: 185)
            .clipShape(RoundedRectangle(cornerRadius: 17))
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(album.title)
                        .foregroundStyle(.white)
                        .font(.system(size: 17, weight: .semibold))
                        .lineLimit(1)
                    Text("\(album.count.formatted())장 · \(album.typeLabel)")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.muted)
                    .font(.system(size: 13, weight: .semibold))
            }
        }
        .padding(12)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 23))
        .overlay(RoundedRectangle(cornerRadius: 23).stroke(Theme.border, lineWidth: 1))
    }
}

