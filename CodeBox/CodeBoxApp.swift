import SwiftUI
import SwiftData

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        ReminderManager.shared.requestPermissions()
        return true
    }
}

@main
struct CodeBoxApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ClipboardItem.self, AIModel.self, User.self])
        // 优先使用 App Group 共享存储，不可用时降级到沙盒默认路径
        let config: ModelConfiguration
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.jiezhang.CodeBox"
        ) {
            config = ModelConfiguration(schema: schema, url: groupURL.appendingPathComponent("CodeBox.store"))
        } else {
            config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
