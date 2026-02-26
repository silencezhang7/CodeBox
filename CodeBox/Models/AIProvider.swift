import Foundation

enum AIProvider: String, CaseIterable {
    case openAI = "OpenAI"
    case anthropic = "Anthropic"
    case custom = "自定义"

    var defaultModel: String {
        switch self {
        case .openAI: return "gpt-4o"
        case .anthropic: return "claude-opus-4-6"
        case .custom: return ""
        }
    }

    var defaultBaseURL: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1"
        case .anthropic: return "https://api.anthropic.com"
        case .custom: return ""
        }
    }
}
