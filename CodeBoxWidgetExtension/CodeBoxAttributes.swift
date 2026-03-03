import ActivityKit
import Foundation

public struct CodeBoxAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var pickupCode: String
        public var stationName: String
        public var platform: String
        public var reminderText: String
        
        public init(pickupCode: String, stationName: String, platform: String, reminderText: String) {
            self.pickupCode = pickupCode
            self.stationName = stationName
            self.platform = platform
            self.reminderText = reminderText
        }
    }

    public var itemId: String
    
    public init(itemId: String) {
        self.itemId = itemId
    }
}