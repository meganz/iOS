import MessageKit

class ChatTextMessageViewCell: TextMessageCell {
    override open func setupSubviews() {
        super.setupSubviews()
    }

    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let chatMessage = message as? ChatMessage, chatMessage.message.content != nil else {
            return
        }

        let megaMessage = chatMessage.message

        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .attributedText(megaMessage.attributedText))
        super.configure(with: dummyMssage, at: indexPath, and: messagesCollectionView)
    }
}

class ChatTextMessageSizeCalculator: TextMessageSizeCalculator {
    override public init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)

        incomingMessageLabelInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
        outgoingMessageLabelInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
    }

    override open func messageContainerMaxWidth(for message: MessageType) -> CGFloat {
        return min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), super.messageContainerMaxWidth(for: message))
    }

    override func messageContainerSize(for message: MessageType) -> CGSize {
        guard let chatMessage = message as? ChatMessage, chatMessage.message.content != nil else {
            return .zero
        }

        let megaMessage = chatMessage.message

        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .attributedText(megaMessage.attributedText))
        let size = super.messageContainerSize(for: dummyMssage)
        return CGSize(width: size.width, height: size.height)
    }
}
