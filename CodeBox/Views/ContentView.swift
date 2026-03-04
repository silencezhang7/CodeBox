import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("app_theme") private var themeRaw: String = AppTheme.system.rawValue
    @AppStorage("isLoggedIn") private var isLoggedIn: Bool = false
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var allItems: [ClipboardItem]
    @State private var screenshotMonitor = ScreenshotMonitor()
    @State private var showingVideoDownload = false

    var body: some View {
        if isLoggedIn {
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
                StatisticsView()
                    .tabItem {
                        Label("统计", systemImage: "chart.bar.fill")
                    }
                ProfileView()
                    .tabItem {
                        Label("我的", systemImage: "person.fill")
                    }
            }
            .onTapGesture(count: 2) {
                showingVideoDownload = true
            }
            .sheet(isPresented: $showingVideoDownload) {
                NavigationStack {
                    VideoDownloadView()
                        .navigationBarItems(trailing: Button("关闭") {
                            showingVideoDownload = false
                        })
                }
            }
            .preferredColorScheme(AppTheme(rawValue: themeRaw)?.colorScheme)
            .onAppear { screenshotMonitor.start(context: modelContext) }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active {
                    for item in allItems {
                        if !item.isUsed && item.type == .pickupCode {
                            ReminderManager.shared.updateLiveActivity(for: item)
                        }
                    }
                }
            }
        } else {
            LoginView()
                .preferredColorScheme(AppTheme(rawValue: themeRaw)?.colorScheme)
        }
    }
}
#Preview {
    ContentView()
}
