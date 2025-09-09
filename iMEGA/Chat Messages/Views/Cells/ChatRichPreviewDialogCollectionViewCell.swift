import MessageKit
import UIKit

class ChatRichPreviewDialogCollectionViewCell: TextMessageCell {
    open var richPreviewDialogView: RichPreviewDialogView = RichPreviewDialogView()
    var megaMessage: MEGAChatMessage?
    var indexPath: IndexPath?
    
    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        
        guard let chatMessage = message as? ChatMessage else {
            return
        }
        let megaMessage = chatMessage.message
        richPreviewDialogView.isHidden = false
        richPreviewDialogView.message = megaMessage
        
        self.indexPath = indexPath
        self.megaMessage = megaMessage
        let dummyMessage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content ?? ""))
        super.configure(with: dummyMessage, at: indexPath, and: messagesCollectionView)
        
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
                    MEGASdk.shared.enableRichPreviews(false)
                } else {
                    MEGASdk.shared.enableRichPreviews(true)
                }
                megaMessage.warningDialog = .none
            } else if richPreviewDialogView.notNowButton.frame.contains(touchLocation) {
                megaMessage.warningDialog = .dismiss
                chatVC.richLinkWarningCounterValue += 1
                MEGASdk.shared.setRichLinkWarningCounterValue(UInt(chatVC.richLinkWarningCounterValue))
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

    open override func messageContainerMaxWidth(for message: any MessageType, at indexPath: IndexPath) -> CGFloat {
       min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), super.messageContainerMaxWidth(for: message, at: indexPath))
    }

    open override func messageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        guard let chatMessage = message as? ChatMessage else {
            return .zero
        }
        
        let megaMessage = chatMessage.message
        let dummyMessage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content ?? ""))
        
        let maxWidth = messageContainerMaxWidth(for: dummyMessage, at: indexPath)
        
        let containerSize = super.messageContainerSize(for: dummyMessage, at: indexPath)
        switch message.kind {
        case .custom:
            let width = max(maxWidth, containerSize.width)
            richPreviewDialogView.message = megaMessage
            let dialogSize = richPreviewDialogView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            
            switch chatMessage.message.warningDialog {
            case .initial, .standard, .confirmation:
                return CGSize(width: max(width, 0), height: containerSize.height + dialogSize.height + 4)

            default:
                return CGSize(width: max(width, 0), height: containerSize.height)

            }
            
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}
