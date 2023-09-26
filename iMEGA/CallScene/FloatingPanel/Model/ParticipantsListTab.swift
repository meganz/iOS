enum ParticipantsListTab: Int {
    case inCall
    case notInCall
    case waitingRoom
}

extension Notification.Name {
    static let seeWaitingRoomListEvent = Notification.Name("seeWaitingRoomListEvent")
}
