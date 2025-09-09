import CoreGraphics
import MessageKit

class ChatTextMessageViewCell: TextMessageCell {
    override open func setupSubviews() {
        super.setupSubviews()
    }

    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let chatMessage = message as? ChatMessage, chatMessage.message.content != nil else {
            return
        }
        
        let megaMessage = chatMessage.message
        
        guard let attributedText = megaMessage.attributedText else {
            let dummyMessage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(chatMessage.message.content ?? ""))
            super.configure(with: dummyMessage, at: indexPath, and: messagesCollectionView)
            return
        }
        
        let dummyMessage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .attributedText(attributedText))
        super.configure(with: dummyMessage, at: indexPath, and: messagesCollectionView)
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

    open override func messageContainerMaxWidth(for message: any MessageType, at indexPath: IndexPath) -> CGFloat {
       min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), super.messageContainerMaxWidth(for: message, at: indexPath))
    }

    open override func messageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        guard let chatMessage = message as? ChatMessage, chatMessage.message.content != nil else {
            return .zero
        }
        
        let megaMessage = chatMessage.message
        let maxWidth: CGFloat = messageContainerMaxWidth(for: message, at: indexPath)
        
        let attributedText = megaMessage.attributedText
        calculateLabel.attributedText = attributedText
        let fitSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        var messageContainerSize: CGSize = calculateLabel.sizeThatFits(fitSize)
        
        let messageInsets = outgoingMessageLabelInsets
        let horizontalInset: CGFloat = messageInsets.left + messageInsets.right
        messageContainerSize.width += horizontalInset
        let verticalInset: CGFloat = messageInsets.top + messageInsets.bottom
        messageContainerSize.height += verticalInset
        
        return CGSize(width: max(messageContainerSize.width, 0), height: messageContainerSize.height)
    }
}
