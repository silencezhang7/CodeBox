import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("app_theme") private var themeRaw: String = AppTheme.system.rawValue
    @Environment(\.modelContext) private var modelContext
    @State private var screenshotMonitor = ScreenshotMonitor()

    var body: some View {
        TabView {
            ItemListView(filterType: .pickupCode)
                .tabItem {
                    Label("取件码", systemImage: "shippingbox.fill")
                }
            ItemListView(filterType: .verificationCode)
                .tabItem {
                    Label("验证码", systemImage: "lock.shield.fill")
                }
            ItemListView(filterType: .other)
                .tabItem {
                    Label("其他", systemImage: "tray.fill")
                }
            ProfileView()
                .tabItem {
                    Label("我的", systemImage: "person.fill")
                }
        }
        .preferredColorScheme(AppTheme(rawValue: themeRaw)?.colorScheme)
        .onAppear { screenshotMonitor.start(context: modelContext) }
    }
}

#Preview {
    ContentView()
}
