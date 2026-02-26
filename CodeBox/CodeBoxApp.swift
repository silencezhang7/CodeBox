import SwiftUI
import SwiftData

@main
struct CodeBoxApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ClipboardItem.self, AIModel.self])
        // 与 AddItemIntent 共享同一个 App Group 存储，确保 Intent 写入的数据主 App 可见
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.jiezhang.CodeBox"
        ) else {
            fatalError("App Group 未配置，请在 Xcode → Signing & Capabilities 中添加 App Group")
        }
        let storeURL = groupURL.appendingPathComponent("CodeBox.store")
        let config = ModelConfiguration(schema: schema, url: storeURL)
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
