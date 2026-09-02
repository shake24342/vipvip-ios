import SwiftUI

@main
struct VipPanelApp: App {
    @StateObject private var vm = PanelViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(vm)
        }
    }
}
