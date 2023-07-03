import Foundation

public struct DeviceEntity: Sendable, Identifiable {
    public let id: String
    public let name: String
    
    public init(
        id: String,
        name: String
    ) {
        self.id = id
        self.name = name
    }
}
