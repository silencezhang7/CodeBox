import SwiftData
import Foundation

enum ItemType: String, Codable, CaseIterable {
    case pickupCode = "取件码"
    case verificationCode = "验证码"
    case other = "其他"
}

@Model
final class ClipboardItem {
    var id: UUID = UUID()
    var content: String = ""
    var originalContent: String?
    var typeRaw: String = ""
    var sourcePlatform: String?
    var stationName: String?
    var stationAddress: String?
    var createdAt: Date = Date()
    var expiresAt: Date?
    var isUsed: Bool = false

    init(content: String, originalContent: String? = nil, typeRaw: String, sourcePlatform: String? = nil,
         stationName: String? = nil, stationAddress: String? = nil,
         expiresAt: Date? = nil, isUsed: Bool = false) {
        self.id = UUID()
        self.content = content
        self.originalContent = originalContent
        self.typeRaw = typeRaw
        self.sourcePlatform = sourcePlatform
        self.stationName = stationName
        self.stationAddress = stationAddress
        self.createdAt = Date()
        self.expiresAt = expiresAt
        self.isUsed = isUsed
    }

    @Transient
    var type: ItemType {
        get { ItemType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
}
