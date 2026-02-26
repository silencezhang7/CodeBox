import SwiftData
import Foundation

@Model
final class AIModel: Identifiable {
    var id: UUID = UUID()
    var displayName: String = ""
    var provider: String = ""
    var modelId: String = ""
    var apiKey: String = ""
    var baseURL: String = ""
    var createdAt: Date = Date()

    init(displayName: String, provider: String, modelId: String, apiKey: String = "", baseURL: String = "") {
        self.id = UUID()
        self.displayName = displayName
        self.provider = provider
        self.modelId = modelId
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.createdAt = Date()
    }
}
