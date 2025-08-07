import Foundation

public struct LocalNotificationEntity: Sendable {
    public let date: Date
    public let id: String
    public let title: String
    public let body: String
    public let repeats: Bool
    public let userInfo: [String: any Sendable]
    
    public init(
        date: Date,
        id: String,
        title: String,
        body: String,
        repeats: Bool = false,
        userInfo: [String: any Sendable] = [:]
    ) {
        self.date = date
        self.id = id
        self.title = title
        self.body = body
        self.repeats = repeats
        self.userInfo = userInfo
    }
}
