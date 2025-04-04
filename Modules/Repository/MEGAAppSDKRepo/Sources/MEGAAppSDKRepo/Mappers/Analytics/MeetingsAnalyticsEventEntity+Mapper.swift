import MEGADomain

extension MeetingsAnalyticsEventEntity: AnalyticsEventProtocol {
    var code: Int {
        switch self {
        case .endCallForAll: return 99309
        case .endCallInNoParticipantsPopup: return 99311
        case .stayOnCallInNoParticipantsPopup: return 99313
        case .enableCallSoundNotifications: return 99312
        case .disableCallSoundNotifications: return 99314
        case .endCallWhenEmptyCallTimeout: return 99315
        }
    }
    
    var description: String {
        switch self {
        case .endCallForAll:
            return "Meeting End Call For All Tapped"
        case .endCallInNoParticipantsPopup:
            return "Meeting End Call Tapped In No Participants Popup"
        case .stayOnCallInNoParticipantsPopup:
            return "Meeting Stay On Call Tapped In No Participants Popup"
        case .enableCallSoundNotifications:
            return "Meeting Enable Sound Notification"
        case .disableCallSoundNotifications:
            return "Meeting Disable Sound Notification"
        case .endCallWhenEmptyCallTimeout:
            return "Meeting Ended when Empty Call Timeout"
        }
    }
}
