import AppIntents

struct CodeBoxShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddItemIntent(),
            phrases: ["添加内容到\(.applicationName)", "保存短信到 \(.applicationName)"],
            shortTitle: "添加剪贴板内容",
            systemImageName: "doc.on.clipboard"
        )
    }
}
