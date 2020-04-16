import MessageKit

internal struct ConcreteMessageType: MessageType {
    let sender: SenderType
    let messageId: String
    let sentDate: Date
    var kind: MessageKind
}

class ChatRichPreviewMediaCollectionViewCell: TextMessageCell {
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        
        guard let chatMessage = message as? ChatMessage else {
            return
        }
        
        let megaMessage = chatMessage.message
        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content))
        super.configure(with: dummyMssage, at: indexPath, and: messagesCollectionView)
        
        
        
    }
    
    
}



open class ChatRichPreviewMediaCollectionViewSizeCalculator: TextMessageSizeCalculator {
    
    open override func messageContainerSize(for message: MessageType) -> CGSize {
        let maxWidth = messageContainerMaxWidth(for: message)
        guard let chatMessage = message as? ChatMessage else {
            return .zero
        }
        
        let megaMessage = chatMessage.message
        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content))

        let containerSize = super.messageContainerSize(for: dummyMssage)
        
        switch message.kind {
        case .custom:
        
            
            return CGSize(width: min(maxWidth, 360), height: containerSize.height + 140 )
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}

