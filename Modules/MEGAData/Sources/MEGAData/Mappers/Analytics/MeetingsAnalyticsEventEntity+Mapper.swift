import MEGADomain

extension MeetingsAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        get {
            var value: Int
            switch self {
            case .endCallForAll: value = 99309
            case .endCallInNoParticipantsPopup: value = 99311
            case .stayOnCallInNoParticipantsPopup: value = 99313
            case .enableCallSoundNotifications: value = 99312
            case .disableCallSoundNotifications: value = 99314
            case .endCallWhenEmptyCallTimeout: value = 99315
            }
            return value
        }
    }
    
    var description: String {
        get {
            var value: String
            switch self {
            case .endCallForAll: value = "Meeting End Call For All Tapped"
            case .endCallInNoParticipantsPopup: value = "Meeting End Call In No Empty Participants Popup"
            case .stayOnCallInNoParticipantsPopup: value = "Meeting End Call When Empty Call Scenario"
            case .enableCallSoundNotifications: value = "Meeting Enable Sound Notification"
            case .disableCallSoundNotifications: value = "Meeting Disable Sound Notification"
            case .endCallWhenEmptyCallTimeout: value = "Meeting Ended when Empty Call Timeout"
            }
            return value
        }
    }
}
