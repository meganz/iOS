public struct WaitingRoomEntity: Sendable {
    public let userIds: [HandleEntity]
    
    public init(sessionClientIds: [HandleEntity]) {
        self.userIds = sessionClientIds
    }
}

public enum WaitingRoomStatus: Sendable {
    case unknown
    case notAllowed
    case allowed
}
