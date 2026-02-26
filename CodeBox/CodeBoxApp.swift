import SwiftUI
import SwiftData

@main
struct CodeBoxApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([ClipboardItem.self, AIModel.self])
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
