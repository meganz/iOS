import Foundation

public struct FavouriteItemEntity: Equatable, Sendable {
    public let base64Handle: String
    public let name: String
    public let timestamp: Date
    
    public init(base64Handle: String, name: String, timestamp: Date) {
        self.base64Handle = base64Handle
        self.name = name
        self.timestamp = timestamp
    }
}
