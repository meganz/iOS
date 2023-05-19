import MessageKit

struct ChatNotificationMessage {
    enum ChatNotificationType {
        case unreadMessage(Int)
    }
    
    let type: ChatNotificationType
    
    init(type: ChatNotificationType) {
        self.type = type
    }
}

extension ChatNotificationMessage: SenderType {
    var senderId: String {
        return "NotificationMessage"
    }
    
    var displayName: String {
        return "NotificationMessage"
    }
}

extension ChatNotificationMessage: MessageType {
    var sender: SenderType {
        return self
    }
    
    var messageId: String {
        return UUID().uuidString
    }
    
    var sentDate: Date {
        return Date()
    }
    
    var kind: MessageKind {
        return .custom(self)
    }
}
