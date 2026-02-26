import AppIntents
import SwiftData

struct AddItemIntent: AppIntent {
    static let title: LocalizedStringResource = "添加剪贴板内容"
    static let description = IntentDescription("识别文本类型（取件码/验证码）并保存到 CodeBox")

    @Parameter(title: "文本内容", description: "要识别的短信或文本")
    var text: String

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try Self.makeContainer()
        let context = ModelContext(container)

        // 有勾选的 AI 模型则优先走 AI
        let activeId = UserDefaults.standard.string(forKey: "active_model_id") ?? ""
        if !activeId.isEmpty,
           let aiModel = try? context.fetch(FetchDescriptor<AIModel>()).first(where: { $0.id.uuidString == activeId }) {
            let result = try await AIRecognitionService.recognize(text: text, model: aiModel)
            let code = result.code.isEmpty ? text : result.code
            let item = ClipboardItem(
                content: code, originalContent: text, typeRaw: result.type.rawValue,
                sourcePlatform: result.platform, stationName: result.stationName, stationAddress: result.stationAddress
            )
            context.insert(item)
            try context.save()
            return .result(dialog: "已保存\(result.type.rawValue)：\(code)")
        }

        // 无勾选模型，走正则
        if let result = RecognitionEngine.shared.recognize(text: text) {
            let item = ClipboardItem(
                content: result.extractedContent, originalContent: text, typeRaw: result.type.rawValue,
                sourcePlatform: result.platform, stationName: result.stationName, stationAddress: result.stationAddress
            )
            context.insert(item)
            try context.save()
            return .result(dialog: "已保存\(result.type.rawValue)：\(result.extractedContent)")
        }

        // 兜底保存为「其他」
        let item = ClipboardItem(content: text, originalContent: text, typeRaw: ItemType.other.rawValue)
        context.insert(item)
        try context.save()
        return .result(dialog: "已保存到「其他」")
    }

    private static func makeContainer() throws -> ModelContainer {
        let schema = Schema([ClipboardItem.self, AIModel.self])
        if let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.jiezhang.CodeBox"
        ) {
            let config = ModelConfiguration(schema: schema, url: groupURL.appendingPathComponent("CodeBox.store"))
            return try ModelContainer(for: schema, configurations: [config])
        }
        // App Group 不可用时降级到沙盒默认路径
        return try ModelContainer(for: schema)
    }
}
