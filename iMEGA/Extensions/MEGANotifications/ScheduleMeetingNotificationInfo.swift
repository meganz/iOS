
struct ScheduleMeetingNotificationInfo {
    enum StartTime {
        case now
        case inFifteenMinutes
    }
    
    let chatId: String
    let startTime: StartTime
    
    init?(dictionary: [AnyHashable: Any]) {
        guard let chatIdBase64 = dictionary["chatid"] as? String,
                let fValue = dictionary["f"] as? Int else {
            return nil
        }
        
        self.chatId = chatIdBase64
        self.startTime = fValue == 0 ? .now : .inFifteenMinutes
    }
}
