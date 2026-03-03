import SwiftData
import Foundation

enum ItemType: String, Codable, CaseIterable {
    case pickupCode = "取件码"
    case verificationCode = "验证码"
    case other = "其他"
}

enum ReminderType: String, Codable, CaseIterable {
    case default18 = "默认(18点)"
    case halfHour = "每半小时"
    case oneHour = "每1小时"
    case daily = "每天1次"
    case exactTime = "准确时间"
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
    var latitude: Double?
    var longitude: Double?
    var createdAt: Date = Date()
    var expiresAt: Date?
    var isUsed: Bool = false
    var usedAt: Date?
    
    var reminderTypeRaw: String = ReminderType.default18.rawValue
    var reminderTime: Date? = nil
    var liveActivityId: String? = nil
    var lastRemindedAt: Date? = nil

    init(content: String, originalContent: String? = nil, typeRaw: String, sourcePlatform: String? = nil,
         stationName: String? = nil, stationAddress: String? = nil,
         expiresAt: Date? = nil, isUsed: Bool = false, usedAt: Date? = nil) {
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
        self.usedAt = usedAt
        self.reminderTypeRaw = ReminderType.default18.rawValue
    }

    @Transient
    var type: ItemType {
        get { ItemType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
    
    @Transient
    var reminderType: ReminderType {
        get { ReminderType(rawValue: reminderTypeRaw) ?? .default18 }
        set { reminderTypeRaw = newValue.rawValue }
    }
    
    @Transient
    var reminderText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd HH:mm"
        
        if let lastReminded = lastRemindedAt {
            return "已在 \(formatter.string(from: lastReminded)) 提醒"
        }
        
        let now = Date()
        
        switch reminderType {
        case .default18:
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day], from: createdAt)
            components.hour = 18
            components.minute = 0
            if let reminderDate = calendar.date(from: components), now >= reminderDate {
                return "已在 18:00 提醒"
            }
            return "将在 18:00 提醒"
        case .halfHour:
            return "每半小时提醒"
        case .oneHour:
            return "每小时提醒"
        case .daily:
            return "每天提醒"
        case .exactTime:
            if let date = reminderTime {
                if date < now {
                    return "已在 \(formatter.string(from: date)) 提醒"
                }
                return "将在 \(formatter.string(from: date)) 提醒"
            }
            return "自定义时间提醒"
        }
    }
}
