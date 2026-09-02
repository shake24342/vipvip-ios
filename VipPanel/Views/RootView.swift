import SwiftUI

struct RootView: View {
    @EnvironmentObject var vm: PanelViewModel

    var body: some View {
        TabView {
            OverviewView()
                .tabItem { Label("总览", systemImage: "chart.bar") }
            AccountListView()
                .tabItem { Label("账号", systemImage: "person.3") }
            GalleryView()
                .tabItem { Label("图集", systemImage: "photo.on.rectangle.angled") }
            DomainView()
                .tabItem { Label("域名", systemImage: "globe") }
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
        }
        .tint(Theme.accent)
        .safeAreaInset(edge: .top) {
            if let b = vm.banner {
                HStack(spacing: 8) {
                    Image(systemName: b.isError ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: 14))
                    Text(b.text)
                        .font(.system(size: 13))
                        .lineLimit(2)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    Capsule(style: .continuous)
                        .fill(b.isError ? Theme.danger : Theme.ok)
                )
                .padding(.horizontal, 16)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: vm.banner?.id)
        .task(id: vm.banner?.id) {
            guard vm.banner != nil else { return }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            await MainActor.run { vm.banner = nil }
        }
    }
}
