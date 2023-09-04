public struct WaitingRoomEntity: Sendable {
    public let sessionClientIds: [HandleEntity]
    
    public init(sessionClientIds: [HandleEntity]) {
        self.sessionClientIds = sessionClientIds
    }
}

public enum WaitingRoomStatus: Sendable {
    case unknown
    case notAllowed
    case allowed
}
