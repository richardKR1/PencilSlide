import SwiftUI
import Photos

struct PhotoSelectionView: View {
    @EnvironmentObject private var gallery: GalleryStore
    @AppStorage("autoplaySeconds") private var autoplaySeconds = 0
    @AppStorage("loopSlides") private var loopSlides = true
    @State private var editingOrder = false
    private let columns = [GridItem(.adaptive(minimum: 125, maximum: 190), spacing: 12)]
    private var countToPlay: Int { gallery.chosenIdentifiers.isEmpty ? gallery.assets.count : gallery.chosenIdentifiers.count }
    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                Button { gallery.returnToAlbums() } label: { Label("앨범 목록", systemImage: "arrow.left") }
                Text(gallery.activeAlbum?.title ?? "사진")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                Text("사진을 원하는 순서대로 선택하세요. 미선택 시 앨범 전체를 재생합니다.")
                    .font(.footnote).foregroundStyle(Theme.muted)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Button("모두 선택", action: gallery.selectAll)
                        Button("선택 해제", action: gallery.clearSelection)
                        Button(gallery.sortNewestFirst ? "최신순" : "오래된순", action: gallery.changeSortOrder)
                        Button("선택 순서 편집") { editingOrder = true }
                            .disabled(gallery.chosenIdentifiers.isEmpty)
                    }.buttonStyle(.bordered)
                }
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(gallery.assets, id: \.localIdentifier) { asset in
                        let position = gallery.chosenIdentifiers.firstIndex(of: asset.localIdentifier)
                        Button { gallery.toggleSelection(asset.localIdentifier) } label: {
                            ZStack(alignment: .topTrailing) {
                                AssetImage(asset: asset, contentMode: .aspectFill, targetPixels: 390)
                                    .frame(height: 165).clipped()
                                Text(position.map { String($0 + 1) } ?? "")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Theme.background)
                                    .frame(width: 30, height: 30)
                                    .background(position == nil ? Color.white.opacity(0.4) : Theme.accent, in: Circle())
                                    .padding(10)
                            }.frame(height: 165).clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(position == nil ? Theme.border : Theme.accent, lineWidth: 2))
                        }.buttonStyle(.plain)
                    }
                }.padding(.horizontal, 24).padding(.bottom, 16)
            }
            VStack(spacing: 14) {
                HStack {
                    Text("\(countToPlay)장 · \(gallery.chosenIdentifiers.isEmpty ? "앨범 순서" : "선택 순서")")
                        .font(.headline)
                    Spacer()
                    Menu {
                        Picker("자동 넘김", selection: $autoplaySeconds) {
                            Text("수동").tag(0)
                            Text("3초").tag(3)
                            Text("5초").tag(5)
                            Text("10초").tag(10)
                            Text("15초").tag(15)
                        }
                    } label: { Label(autoplaySeconds == 0 ? "수동" : "\(autoplaySeconds)초 자동", systemImage: "timer") }
                    Toggle("반복", isOn: $loopSlides).fixedSize()
                }
                Button(action: gallery.startSlideshow) {
                    Label("슬라이드쇼 시작", systemImage: "play.fill")
                        .font(.headline).foregroundStyle(Theme.background)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: 13))
                }.disabled(gallery.assets.isEmpty)
            }.padding(24).background(Theme.surface)
        }
        .background(Theme.background)
        .sheet(isPresented: $editingOrder) { SelectionOrderView().environmentObject(gallery) }
    }
}

struct SelectionOrderView: View {
    @EnvironmentObject private var gallery: GalleryStore
    @Environment(\.dismiss) private var dismiss
    private var chosenAssets: [PHAsset] {
        let lookup = Dictionary(uniqueKeysWithValues: gallery.assets.map { ($0.localIdentifier, $0) })
        return gallery.chosenIdentifiers.compactMap { lookup[$0] }
    }
    var body: some View {
        NavigationStack {
            List {
                Section("오른쪽 손잡이를 끌어 순서를 바꾸세요. 변경은 바로 저장됩니다.") {
                    ForEach(chosenAssets, id: \.localIdentifier) { asset in
                        HStack(spacing: 16) {
                            AssetImage(asset: asset, contentMode: .aspectFill, targetPixels: 180)
                                .frame(width: 72, height: 64).clipped().cornerRadius(8)
                            let number = (gallery.chosenIdentifiers.firstIndex(of: asset.localIdentifier) ?? 0) + 1
                            Text("\(number)번째 사진")
                            Spacer()
                        }
                    }
                    .onMove(perform: gallery.moveSelection)
                    .onDelete(perform: gallery.removeSelection)
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("사진 순서")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } } }
        }.preferredColorScheme(.dark).tint(Theme.accent).statusBarHidden(true)
    }
}
