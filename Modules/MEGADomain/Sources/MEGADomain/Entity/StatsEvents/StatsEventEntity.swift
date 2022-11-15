import Foundation

public enum StatsEventEntity {
    case delayBetweenChatdAndApi
    case delayBetweenApiAndPushserver
    case delayBetweenPushserverAndNSE
    case nseWillExpireAndMessageNotFound
    case clickMediaDiscovery
    case stayOnMediaDiscoveryOver10s
    case stayOnMediaDiscoveryOver30s
    case stayOnMediaDiscoveryOver60s
    case stayOnMediaDiscoveryOver180s
    case clickMeetingEndCallForAll
    case clickMeetingEndCallInNoParticipantsPopup
    case clickMeetingStayOnCallInNoParticipantsPopup
    case meetingEnableCallSoundNotifications
    case meetingDisableCallSoundNotifications
    case meetingEndCallWhenEmptyCallTimeout
    
    public var message: String {
        let value: String
        
        switch self {
        case .delayBetweenChatdAndApi: value = "Delay between chatd and api"
        case .delayBetweenApiAndPushserver: value = "Delay between api and pushserver"
        case .delayBetweenPushserverAndNSE:value = "Delay between pushserver and Apple/device/NSE"
        case .nseWillExpireAndMessageNotFound: value = "NSE will expire and message not found"
        case .clickMediaDiscovery: value = "Media Discovery Option Tapped"
        case .stayOnMediaDiscoveryOver10s: value = "Stay on Media Discovery over 10s"
        case .stayOnMediaDiscoveryOver30s: value = "Stay on Media Discovery over 30s"
        case .stayOnMediaDiscoveryOver60s: value = "Stay on Media Discovery over 60s"
        case .stayOnMediaDiscoveryOver180s: value = "Stay on Media Discovery over 180s"
        case .clickMeetingEndCallForAll: value = "Meeting End Call For All Tapped"
        case .clickMeetingEndCallInNoParticipantsPopup: value = "Meeting End Call In No Empty Participants Popup"
        case .clickMeetingStayOnCallInNoParticipantsPopup: value = "Meeting End Call When Empty Call Scenario"
        case .meetingEnableCallSoundNotifications: value = "Meeting Enable Sound Notification"
        case .meetingDisableCallSoundNotifications: value = "Meeting Disable Sound Notification"
        case .meetingEndCallWhenEmptyCallTimeout: value = "Meeting Ended when Empty Call Timeout"
        }
        
        return value
    }
}
