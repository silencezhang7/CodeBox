import AppIntents
import SwiftData

struct AddItemIntent: AppIntent {
    static let title: LocalizedStringResource = "添加剪贴板内容"
    static let description = IntentDescription("识别文本类型（取件码/验证码）并保存到 CodeBox")

    @Parameter(title: "文本内容", description: "要识别的短信或文本")
    var text: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try Self.makeContainer()
        let context = ModelContext(container)

        if let result = RecognitionEngine.shared.recognize(text: text) {
            let item = ClipboardItem(
                content: result.extractedContent,
                originalContent: text,
                typeRaw: result.type.rawValue,
                sourcePlatform: result.platform,
                stationName: result.stationName,
                stationAddress: result.stationAddress
            )
            context.insert(item)
            try context.save()
            return .result(dialog: "已保存\(result.type.rawValue)：\(result.extractedContent)")
        }

        // 正则未命中，保存为「其他」
        let item = ClipboardItem(content: text, originalContent: text, typeRaw: ItemType.other.rawValue)
        context.insert(item)
        try context.save()
        return .result(dialog: "已保存到「其他」")
    }

    private static func makeContainer() throws -> ModelContainer {
        guard let groupURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.yourteam.codebox"
        ) else {
            throw IntentError.appGroupUnavailable
        }
        let schema = Schema([ClipboardItem.self, AIModel.self])
        let config = ModelConfiguration(schema: schema, url: groupURL.appendingPathComponent("CodeBox.store"))
        return try ModelContainer(for: schema, configurations: [config])
    }
}

private enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case appGroupUnavailable
    var localizedStringResource: LocalizedStringResource { "App Group 未配置" }
}
