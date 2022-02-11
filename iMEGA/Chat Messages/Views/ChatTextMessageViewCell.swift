import MessageKit
import CoreGraphics

class ChatTextMessageViewCell: TextMessageCell {
    override open func setupSubviews() {
        super.setupSubviews()
    }

    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let chatMessage = message as? ChatMessage, chatMessage.message.content != nil else {
            return
        }
        
        let megaMessage = chatMessage.message
        
        guard let attributedText = megaMessage.attributedText else {
            let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(chatMessage.message.content))
            super.configure(with: dummyMssage, at: indexPath, and: messagesCollectionView)
            return
        }
        
        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .attributedText(attributedText))
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
        let maxWidth: CGFloat = messageContainerMaxWidth(for: message)
        
        let attributedText = megaMessage.attributedText
        calculateLabel.attributedText = attributedText
        let fitSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        var messageContainerSize: CGSize = calculateLabel.sizeThatFits(fitSize)
        
        let messageInsets = outgoingMessageLabelInsets
        let horizontalInset: CGFloat = messageInsets.left + messageInsets.right
        messageContainerSize.width += horizontalInset
        let verticalInset: CGFloat = messageInsets.top + messageInsets.bottom
        messageContainerSize.height += verticalInset
        
        return messageContainerSize
    }
}
