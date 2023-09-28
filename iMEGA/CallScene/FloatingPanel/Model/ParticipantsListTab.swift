import MEGAL10n

enum ParticipantsListTab {
    case inCall
    case notInCall
    case waitingRoom
    
    var title: String {
        switch self {
        case .inCall:
            return Strings.Localizable.Meetings.Panel.ListSelector.inCall
        case .notInCall:
            return Strings.Localizable.Meetings.Panel.ListSelector.notInCall
        case .waitingRoom:
            return Strings.Localizable.Meetings.Panel.ListSelector.inWaitingRoom
        }
    }
}

extension Notification.Name {
    static let seeWaitingRoomListEvent = Notification.Name("seeWaitingRoomListEvent")
}
