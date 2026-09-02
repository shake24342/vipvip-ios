import SwiftUI

struct GalleryView: View {
    @State private var viewing: Int?

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 4),
                    GridItem(.flexible(), spacing: 4),
                    GridItem(.flexible(), spacing: 4),
                ], spacing: 4) {
                    ForEach(1...GalleryStore.photoCount, id: \.self) { n in
                        Button {
                            viewing = n
                        } label: {
                            GalleryThumb(number: n)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(4)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("图集 \(GalleryStore.photoCount)")
        }
        .navigationViewStyle(.stack)
        .fullScreenCover(item: Binding(
            get: { viewing.map { GalleryItem(number: $0) } },
            set: { viewing = $0?.number }
        )) { item in
            GalleryViewer(start: item.number)
        }
    }
}

struct GalleryItem: Identifiable {
    let number: Int
    var id: Int { number }
}

// MARK: - 网格缩略

struct GalleryThumb: View {
    let number: Int

    var body: some View {
        Group {
            if let im = GalleryStore.thumb(number) {
                Image(uiImage: im)
                    .resizable()
                    .aspectRatio(2 / 3, contentMode: .fill)
            } else {
                ZStack {
                    Rectangle().fill(Color(.tertiarySystemFill))
                    Image(systemName: "photo")
                        .foregroundStyle(.tertiary)
                }
                .aspectRatio(2 / 3, contentMode: .fill)
            }
        }
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

// MARK: - 全屏查看（整张显示 + 双指缩放 + 双击放大）

struct GalleryViewer: View {
    let start: Int
    @Environment(\.dismiss) private var dismiss
    @State private var index: Int = 1

    var body: some View {
        ZStack(alignment: .top) {
            Color.black.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(1...GalleryStore.photoCount, id: \.self) { n in
                    ZoomablePhoto(number: n)
                        .tag(n)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(9)
                        .background(Circle().fill(.white.opacity(0.18)))
                }
                Spacer()
                Text("\(index) / \(GalleryStore.photoCount)")
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.horizontal, 11)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(.white.opacity(0.18)))
            }
            .padding(.horizontal, 16)
        }
        .onAppear { index = start }
    }
}

struct ZoomablePhoto: View {
    let number: Int
    @State private var scale: CGFloat = 1
    @GestureState private var pinch: CGFloat = 1

    var body: some View {
        Group {
            if let im = GalleryStore.full(number) {
                Image(uiImage: im)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "photo")
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)
            }
        }
        .scaleEffect(scale * pinch)
        .gesture(
            MagnificationGesture()
                .updating($pinch) { v, s, _ in s = v }
                .onEnded { v in
                    scale = min(max(scale * v, 1), 4)
                }
        )
        .onTapGesture(count: 2) {
            withAnimation(.easeOut(duration: 0.2)) {
                scale = scale > 1.01 ? 1 : 2.5
            }
        }
        .animation(.easeOut(duration: 0.15), value: scale)
    }
}
