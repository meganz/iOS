import UIKit
import MessageKit

class ChatRichPreviewDialogCollectionViewCell: TextMessageCell {
    open var richPreviewDialogView: RichPreviewDialogView = RichPreviewDialogView()
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        
        guard let chatMessage = message as? ChatMessage else {
            return
        }
        
        let megaMessage = chatMessage.message
        richPreviewDialogView.isHidden = false
        richPreviewDialogView.message = megaMessage
        
        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content))
        super.configure(with: dummyMssage, at: indexPath, and: messagesCollectionView)
        
        if megaMessage.type == .containsMeta {
            richPreviewDialogView.isHidden = false
            return
        }
        
        
        
//        let megaLink = megaMessage.megaLink as NSURL
        
        
    }
    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(richPreviewDialogView)
        setupConstraints()
    }
    
    // MARK: - Methods
    
    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        richPreviewDialogView.autoSetDimension(.height, toSize: 200)
        richPreviewDialogView.autoPinEdge(toSuperviewEdge: .leading)
        richPreviewDialogView.autoPinEdge(toSuperviewEdge: .trailing)
        richPreviewDialogView.autoPinEdge(toSuperviewEdge: .bottom)
    }
}

open class ChatRichPreviewDialogCollectionViewSizeCalculator: TextMessageSizeCalculator {
    
    override open func messageContainerMaxWidth(for message: MessageType) -> CGFloat {
        return min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), super.messageContainerMaxWidth(for: message))
    }

    open override func messageContainerSize(for message: MessageType) -> CGSize {
        guard let chatMessage = message as? ChatMessage else {
            return .zero
        }
        
        let megaMessage = chatMessage.message
        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content))

        let maxWidth = messageContainerMaxWidth(for: dummyMssage)

        let containerSize = super.messageContainerSize(for: dummyMssage)
        switch message.kind {
        case .custom:
//            if megaMessage.richNumber == nil && megaMessage.containsMeta?.type != .richPreview {
//                return containerSize
//            }
            
            return CGSize(width: max(maxWidth, containerSize.width), height: containerSize.height + 200)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}

