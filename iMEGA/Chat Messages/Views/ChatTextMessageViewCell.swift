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
    
    open var calculateLabel: MessageLabel = {
        let label = MessageLabel()
        return label
    }()
    
    override public init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)

        incomingMessageLabelInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
        outgoingMessageLabelInsets = UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18)
    }

    override open func messageContainerMaxWidth(for message: MessageType) -> CGFloat {
        return min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), super.messageContainerMaxWidth(for: message))
    }

    open override func messageContainerSize(for message: MessageType) -> CGSize {
        guard let chatMessage = message as? ChatMessage, chatMessage.message.content != nil else {
            return .zero
        }
        
        let megaMessage = chatMessage.message
        let maxWidth = messageContainerMaxWidth(for: message)
        
        var messageContainerSize: CGSize
        let attributedText = megaMessage.attributedText
        
        calculateLabel.attributedText = attributedText
        messageContainerSize = calculateLabel.sizeThatFits(CGSize(width: maxWidth, height: .greatestFiniteMagnitude))
        
        let messageInsets = outgoingMessageLabelInsets
        messageContainerSize.width += (messageInsets.left + messageInsets.right)
        messageContainerSize.height += (messageInsets.top + messageInsets.bottom)
        
        return messageContainerSize
    }
}
