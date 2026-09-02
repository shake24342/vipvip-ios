import SwiftUI
import UIKit

/// 图集资源加载（bundle 内 Gallery/thumb、Gallery/full 两个 folder reference）
enum GalleryStore {
    static let photoCount = 86

    /// 首页横幅展示位
    static let heroNumber = 53

    /// 账号行整图预览池（30 张姿态差异大的，按 slot 分配）
    static let avatarPool: [Int] = [
        3, 8, 24, 27, 33, 37, 51, 55, 64, 10,
        5, 22, 42, 43, 53, 60, 63, 66, 15, 25,
        26, 30, 34, 46, 6, 12, 35, 48, 49, 52,
    ]

    static func avatarNumber(for slot: Int) -> Int {
        guard !avatarPool.isEmpty else { return 1 }
        return avatarPool[abs(slot) % avatarPool.count]
    }

    private static let thumbCache = NSCache<NSNumber, UIImage>()
    private static let fullCache = NSCache<NSNumber, UIImage>()

    static func thumb(_ n: Int) -> UIImage? { image(n, full: false) }
    static func full(_ n: Int) -> UIImage? { image(n, full: true) }

    private static func image(_ n: Int, full: Bool) -> UIImage? {
        guard (1...photoCount).contains(n) else { return nil }
        let key = NSNumber(value: n)
        let cache = full ? fullCache : thumbCache
        if let im = cache.object(forKey: key) { return im }
        let name = String(format: "photo_%02d", n)
        let sub = "Gallery/\(full ? "full" : "thumb")"
        guard let url = Bundle.main.url(forResource: name, withExtension: "jpg", subdirectory: sub),
              let data = try? Data(contentsOf: url),
              let im = UIImage(data: data) else { return nil }
        cache.setObject(im, forKey: key)
        return im
    }
}

// MARK: - 账号行整图预览（2:3 与原图同比例,整张显示不裁脸）

struct CoverPhoto: View {
    let number: Int
    var width: CGFloat = 50

    var body: some View {
        Group {
            if let im = GalleryStore.thumb(number) {
                Image(uiImage: im)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color(.systemGray4)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 18))
                            .foregroundStyle(.white.opacity(0.6))
                    )
            }
        }
        .frame(width: width, height: width * 1.5)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color(.separator), lineWidth: 0.5)
        )
    }
}

// MARK: - 总览横幅

struct HeroPhotoCard: View {
    let number: Int
    var height: CGFloat = 170
    var overlayText: String? = nil

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let im = GalleryStore.full(number) {
                Image(uiImage: im)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity)
                    .frame(height: height, alignment: .top)
                    .clipped()
            } else {
                Theme.accent
                    .frame(height: height)
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.05), .black.opacity(0.55)],
                startPoint: .top, endPoint: .bottom
            )
            .frame(height: height)

            if let text = overlayText {
                Text(text)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(16)
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
