import SwiftUI

enum Theme {
    static let accent = Color(red: 0.14, green: 0.39, blue: 0.92)
    static let ink = Color.primary
    static let ink2 = Color.secondary
    static let ok = Color(red: 0.13, green: 0.62, blue: 0.35)
    static let warn = Color(red: 0.85, green: 0.55, blue: 0.05)
    static let danger = Color(red: 0.85, green: 0.24, blue: 0.24)
    static let neutral = Color.secondary

    /// 天数进度配色：蓝 → 紫 → 粉，15 天转金色（与网页面板同一套取色逻辑）
    static func progressColor(days: Int) -> Color {
        if days >= 15 { return Color(hue: 0.105, saturation: 0.85, brightness: 0.95) }
        let d = min(max(Double(days), 0), 14)
        let hueDeg: Double
        if d <= 7 {
            hueDeg = 220 - (d / 7) * (220 - 265)
        } else {
            hueDeg = 265 - ((d - 7) / 7) * (265 - 330)
        }
        return Color(hue: hueDeg / 360.0, saturation: 0.85, brightness: 0.98)
    }

    static func statusColor(_ a: Account) -> Color {
        if a.dead { return danger }
        if a.hasVip24 { return Color(hue: 0.105, saturation: 0.85, brightness: 0.95) }
        if a.hasVip12 { return Color(hue: 0.75, saturation: 0.7, brightness: 0.85) }
        if a.delay > 0 { return neutral }
        return accent
    }
}

// MARK: - 卡片容器

struct CardBox<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - 统计格

struct StatCell: View {
    var title: String
    var value: Int
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(tint)
            Text(title)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - 空状态

struct EmptyBox: View {
    var title: String
    var hint: String
    var photo: Int? = nil

    var body: some View {
        VStack(spacing: 12) {
            if let n = photo, let im = GalleryStore.full(n) {
                Image(uiImage: im)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal, 36)
                    .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
            } else {
                Image(systemName: "tray")
                    .font(.system(size: 34))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 12)
            }
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.secondary)
            Text(hint)
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}
