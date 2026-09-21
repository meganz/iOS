import MessageKit

class ChatManagmentTypeCollectionViewCell: TextMessageCell {
    
    open override func setupSubviews() {
        super.setupSubviews()
        avatarView.backgroundColor = .clear
    }
    
    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let chatMessage = message as? ChatMessage else { return }
        super.configure(with: ConcreteMessageType(chatMessage: chatMessage), at: indexPath, and: messagesCollectionView)
    }
}

open class ChatManagementTypeCollectionViewSizeCalculator: TextMessageSizeCalculator {
   
    open override func messageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        // MessageKit asks for this from both sizeForItem and configure(attributes:); the layout
        // keeps one measurement per message so the second ask is a lookup.
        guard let layout = layout as? ChatViewMessagesFlowLayout else {
            return measuredMessageContainerSize(for: message, at: indexPath)
        }

        return layout.cachedMessageContainerSize(for: message, at: indexPath) {
            measuredMessageContainerSize(for: message, at: indexPath)
        }
    }

    private func measuredMessageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        guard let chatMessage = message as? ChatMessage else { return .zero }
        let size = super.messageContainerSize(for: ConcreteMessageType(chatMessage: chatMessage), at: indexPath)
        return size.positiveWidth
    }
}
