import SwiftData
import Foundation

@Model
final class User {
    @Attribute(.unique) var username: String
    var passwordHash: String
    @Attribute(.externalStorage) var avatarData: Data?
    var createdAt: Date = Date()
    
    init(username: String, passwordHash: String, avatarData: Data? = nil) {
        self.username = username
        self.passwordHash = passwordHash
        self.avatarData = avatarData
    }
}
