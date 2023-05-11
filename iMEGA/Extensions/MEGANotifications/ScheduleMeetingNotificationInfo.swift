
struct ScheduleMeetingNotificationInfo {
    enum StartTime {
        case now
        case inFifteenMinutes
    }
    
    let chatId: String
    let startTime: StartTime
    let title: String
    
    init?(dictionary: [AnyHashable: Any]) {
        guard let chatIdBase64 = dictionary["chatid"] as? String else {
            MEGALogError("chatid key not found in the user info")
            return nil
        }
        
        guard let fValue = dictionary["f"] as? Int else {
            MEGALogError("f key not found in the user info")
            return nil
        }
        
        guard let encodedTitle = dictionary["t"] as? String, let title = encodedTitle.base64Decoded else {
            MEGALogError("could not decode the title")
            return nil
        }
        
        self.chatId = chatIdBase64
        self.startTime = fValue == 0 ? .now : .inFifteenMinutes
        self.title = title
    }
}
