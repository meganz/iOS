import MEGADomain

extension MEGAChatWaitingRoom {
    func toWaitingRoomEntity() -> WaitingRoomEntity {
        WaitingRoomEntity(with: self)
    }
}

extension MEGAChatWaitingRoomStatus {
    func toWaitingRoomStatusEntity() -> WaitingRoomStatus {
        switch self {
        case .unknown:
            return .unknown
        case .notAllowed:
            return .notAllowed
        case .allowed:
            return .allowed
        @unknown default:
            return .unknown
        }
    }
}

fileprivate extension WaitingRoomEntity {
    init(with waitingRoom: MEGAChatWaitingRoom) {
        self.init(sessionClientIds: waitingRoom.peers?.toHandleEntityArray() ?? [])
    }
}
