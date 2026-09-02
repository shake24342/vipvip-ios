import UIKit

/// 图集资源加载（bundle 内 Gallery/thumb、Gallery/full 两个 folder reference）
enum GalleryStore {
    static let photoCount = 86

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
