import Foundation

public struct RecentItemEntity: Equatable, Sendable {

    public let base64Handle: String
    public let name: String
    public let timestamp: Date
    public let isUpdate: Bool
    
    public init(base64Handle: String, name: String, timestamp: Date, isUpdate: Bool) {
        self.base64Handle = base64Handle
        self.name = name
        self.timestamp = timestamp
        self.isUpdate = isUpdate
    }
}
