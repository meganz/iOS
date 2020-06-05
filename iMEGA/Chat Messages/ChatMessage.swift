import MessageKit

struct User: SenderType {
    var senderId: String
    var displayName: String
}

struct ChatMessage {
    let message: MEGAChatMessage
    let chatRoom: MEGAChatRoom
    var transfer: MEGATransfer?
    
    init(message: MEGAChatMessage, chatRoom: MEGAChatRoom) {
        self.message = message
        self.chatRoom = chatRoom
    }
    
    init(transfer: MEGATransfer, chatRoom: MEGAChatRoom) {
        self.message = MEGAChatMessage()
        self.transfer = transfer
        self.chatRoom = chatRoom
    }
    
    var avatarImage: UIImage? {
        guard let peerEmail = chatRoom.peerEmail(byHandle: message.userHandle),
            let user = MEGASdkManager.sharedMEGASdk()?.contact(forEmail: peerEmail) else {
                return nil
        }

        return user.avatarImage(withDelegate: nil)
    }
}

extension ChatMessage: MessageType {
    var sender: SenderType {
        return self
    }

    var messageId: String {
        return String(format: "%llu", message.messageId)
    }

    var sentDate: Date {
        guard let timestamp = message.timestamp else {
            return Date()
        }
        return timestamp
    }
    
    var kind: MessageKind {
        
        message.text()

        if case .callEnded = message.type {
            return .custom(message)
        } else if case .callStarted = message.type {
            return .custom(message)
        } else if case .attachment = message.type {
            return .custom(message)
        } else if case .contact = message.type {
            return .custom(message)
        } else if case .containsMeta = message.type {
            return .custom(message)
        } else if case .normal = message.type {
            return .custom(message)
            
        } else if case .voiceClip = message.type {
            return .custom(message)
        } else if message.isManagementMessage {
            return .custom(message)
        }
        
        if transfer?.transferChatMessageType() == .voiceClip || transfer?.transferChatMessageType() == .attachment {
            return .custom(message)
        }
        
        
        return .text(message.type.description)
    }
}

extension ChatMessage: SenderType {
    var senderId: String {
        if message.isManagementMessage {
            return "0"
        }
        if transfer != nil {
            return String(format: "%llu", MEGASdkManager.sharedMEGAChatSdk()!.myUserHandle)
        }
        
        return String(format: "%llu", message.userHandle)
    }

    var displayName: String {
        return chatRoom.userDisplayName(forUserHandle: message.userHandle) ?? chatRoom.peerEmail(byHandle: message.userHandle)
    }
}

extension ChatMessage: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(message.messageId)
    }
}

extension ChatMessage: Comparable {
    static func < (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.message.messageIndex < rhs.message.messageIndex
    }
}

extension MEGAChatMessageType: CustomStringConvertible {
    public var description: String {
        switch self {
        case .unknown:
            return "This is unknown type message"
        case .invalid:
            return "This is invalid type message"
        case .normal:
            return "This is normal type message"
        case .alterParticipants:
            return "This is alterParticipants type message"
        case .truncate:
            return "This is truncate type message"
        case .privilegeChange:
            return "This is privilegeChange type message"
        case .chatTitle:
            return "This is chatTitle type message"
        case .callEnded:
            return "This is callEnded type message"
        case .callStarted:
            return "This is callStarted type message"
        case .publicHandleCreate:
            return "This is publicHandleCreate type message"
        case .publicHandleDelete:
            return "This is publicHandleDelete type message"
        case .setPrivateMode:
            return "This is setPrivateMode type message"
        case .highestManagement:
            return "This is highestManagement type message"
        case .attachment:
            return "This is attachment type message"
        case .revokeAttachment:
            return "This is revokeAttachment type message"
        case .contact:
            return "This is contact type message"
        case .containsMeta:
            return "This is containsMeta type message"
        case .voiceClip:
            return "This is voiceClip type message"
        @unknown default:
            return "default case executed"
        }
    }
}
