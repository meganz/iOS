import MessageKit
import UIKit

class ChatRichPreviewDialogCollectionViewCell: TextMessageCell {
    open var richPreviewDialogView: RichPreviewDialogView = RichPreviewDialogView()
    var megaMessage: MEGAChatMessage?
    var indexPath: IndexPath?
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        
        guard let chatMessage = message as? ChatMessage else {
            return
        }
        let megaMessage = chatMessage.message
        richPreviewDialogView.isHidden = false
        richPreviewDialogView.message = megaMessage
        
        self.indexPath = indexPath
        self.megaMessage = megaMessage
        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content ?? ""))
        super.configure(with: dummyMssage, at: indexPath, and: messagesCollectionView)
        
        if megaMessage.type == .containsMeta {
            richPreviewDialogView.isHidden = false
            return
        }
                
    }
    
    open override func handleTapGesture(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: richPreviewDialogView)

        guard richPreviewDialogView.frame.contains(touchLocation) else {
            super.handleTapGesture(gesture)
            return
        }
        
        if let collectionView = self.superview as? UICollectionView, let chatVC = collectionView.delegate as? ChatViewController, let megaMessage = megaMessage {
            // Trigger action
            if richPreviewDialogView.alwaysAllowButton.frame.contains(touchLocation) {
                if megaMessage.warningDialog == .confirmation {
                    MEGASdkManager.sharedMEGASdk().enableRichPreviews(false)
                } else {
                    MEGASdkManager.sharedMEGASdk().enableRichPreviews(true)
                }
                megaMessage.warningDialog = .none
            } else if richPreviewDialogView.notNowButton.frame.contains(touchLocation) {
                megaMessage.warningDialog = .dismiss
                chatVC.richLinkWarningCounterValue += 1
                MEGASdkManager.sharedMEGASdk().setRichLinkWarningCounterValue(chatVC.richLinkWarningCounterValue)
            } else if  richPreviewDialogView.neverButton.frame.contains(touchLocation) {
                megaMessage.warningDialog = .confirmation
            }
            chatVC.chatRoomDelegate.updateMessage(megaMessage)
        }
    }

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(richPreviewDialogView)
    }
}

open class ChatRichPreviewDialogCollectionViewSizeCalculator: TextMessageSizeCalculator {
    var richPreviewDialogView: RichPreviewDialogView = RichPreviewDialogView()

    override open func messageContainerMaxWidth(for message: MessageType) -> CGFloat {
        return min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), super.messageContainerMaxWidth(for: message))
    }

    open override func messageContainerSize(for message: MessageType) -> CGSize {
        guard let chatMessage = message as? ChatMessage else {
            return .zero
        }
        
        let megaMessage = chatMessage.message
        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content ?? ""))
        
        let maxWidth = messageContainerMaxWidth(for: dummyMssage)
        
        let containerSize = super.messageContainerSize(for: dummyMssage)
        switch message.kind {
        case .custom:
            let width = max(maxWidth, containerSize.width)
            richPreviewDialogView.message = megaMessage
            let dialogSize = richPreviewDialogView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            
            switch chatMessage.message.warningDialog {
            case .initial, .standard, .confirmation:
                return CGSize(width: width, height: containerSize.height + dialogSize.height + 4)

            default:
                return CGSize(width: width, height: containerSize.height)

            }
            
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}
