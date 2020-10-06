import MessageKit

class ChatManagmentTypeCollectionViewCell: TextMessageCell {
    
    open override func setupSubviews() {
        super.setupSubviews()
        avatarView.backgroundColor = .clear
    }
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)

        guard let chatMessage = message as? ChatMessage else {
            return
        }

        let megaMessage = chatMessage.message
        megaMessage.generateAttributedString()
        
        messageLabel.attributedText = megaMessage.attributedText

    }
}


open class ChatManagmentTypeCollectionViewSizeCalculator: TextMessageSizeCalculator {
   
    open override func messageContainerSize(for message: MessageType) -> CGSize {
        
        guard let chatMessage = message as? ChatMessage else {
            return .zero
        }
        
        let megaMessage = chatMessage.message
        megaMessage.generateAttributedString()
        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .attributedText(megaMessage.attributedText))
        return super.messageContainerSize(for: dummyMssage)
    }
}
