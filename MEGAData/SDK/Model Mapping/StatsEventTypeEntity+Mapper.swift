import MEGADomain

extension StatsEventEntity {
    func toMEGAEventCode() -> Int {
        let code: Int
        
        switch self {
        case .clickMediaDiscovery: code = 99304
        case .stayOnMediaDiscoveryOver10s: code = 99305
        case .stayOnMediaDiscoveryOver30s: code = 99306
        case .stayOnMediaDiscoveryOver60s: code = 99307
        case .stayOnMediaDiscoveryOver180s: code = 99308
        case .clickMeetingEndCallForAll: code = 99309
        case .clickMeetingEndCallInNoParticipantsPopup: code = 99311
        case .clickMeetingStayOnCallInNoParticipantsPopup: code = 99313
        case .meetingEnableCallSoundNotifications: code = 99312
        case .meetingDisableCallSoundNotifications: code = 99314
        case .meetingEndCallWhenEmptyCallTimeout: code = 99315
        }
        
        return code
    }
}
