import MessageKit

class ChatManagmentTypeCollectionViewCell: TextMessageCell {
    
    open override func setupSubviews() {
        super.setupSubviews()
        avatarView.backgroundColor = .clear
    }
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let chatMessage = message as? ChatMessage else { return }
        super.configure(with: ConcreteMessageType(chatMessage: chatMessage), at: indexPath, and: messagesCollectionView)
    }
}

open class ChatManagmentTypeCollectionViewSizeCalculator: TextMessageSizeCalculator {
   
    open override func messageContainerSize(for message: MessageType) -> CGSize {
        guard let chatMessage = message as? ChatMessage else { return .zero }
        return super.messageContainerSize(for: ConcreteMessageType(chatMessage: chatMessage))
    }
}
