import MEGADomain
import MessageKit

struct User: SenderType {
    var senderId: String
    var displayName: String
}

struct ChatMessage {
    let message: MEGAChatMessage
    let chatRoom: ChatRoomEntity
    var transfer: MEGATransfer?
    init(message: MEGAChatMessage, chatRoom: ChatRoomEntity) {
        self.message = message
        self.chatRoom = chatRoom
    }
    
    init(transfer: MEGATransfer, chatRoom: ChatRoomEntity) {
        self.message = MEGAChatMessage()
        self.transfer = transfer
        self.chatRoom = chatRoom
    }
    
}

extension ChatMessage: MessageType {
    var sender: any SenderType {
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
        
        message.generateAttributedString(chatRoom.isMeeting)
        
        switch message.type {
        case .callEnded, .callStarted, .attachment, .containsMeta, .contact, .voiceClip, .normal:
            return .custom(message)
        default:
            break
        }
        
        if message.isManagementMessage {
            return .custom(message)
        }
        
        if transfer?.transferChatMessageType() == .voiceClip || transfer?.transferChatMessageType() == .attachment {
            return .custom(message)
        }
        
        return .text("")
    }
}

extension ChatMessage: SenderType {
    var senderId: String {
        if message.isManagementMessage {
            return "-1"
        }
        
        if transfer?.type == .upload {
            return String(format: "%llu", MEGAChatSdk.shared.myUserHandle)
        }
        
        return String(format: "%llu", message.userHandle)
    }

    var displayName: String {
        let userEmail = MEGAChatSdk.shared.userEmailFromCache(byUserHandle: message.userHandle) ?? ""
        let userName = userDisplayName(forUserHandle: message.userHandle) ?? userEmail
        return userName
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
