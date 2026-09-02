import SwiftUI
import UIKit

/// 图集资源加载（bundle 内 Gallery/thumb、Gallery/full 两个 folder reference）
enum GalleryStore {
    static let photoCount = 86

    /// 首页横幅展示位
    static let heroNumber = 53

    /// 账号行圆形头像池（30 张，按 slot 分配，主体居中适合方形裁剪）
    static let avatarPool: [Int] = [
        53, 25, 42, 8, 24, 43, 15, 20, 21, 22,
        23, 26, 27, 30, 31, 32, 33, 34, 36, 44,
        46, 49, 50, 51, 52, 54, 55, 60, 63, 64,
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

// MARK: - 圆形头像

struct AvatarView: View {
    let number: Int
    var size: CGFloat = 44

    var body: some View {
        Group {
            if let im = GalleryStore.thumb(number) {
                Image(uiImage: im)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color(.systemGray4)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: size * 0.45))
                            .foregroundStyle(.white.opacity(0.7))
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay(Circle().strokeBorder(Color(.separator), lineWidth: 0.5))
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
