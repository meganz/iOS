
import MessageKit

class ChatViewCallCollectionCell: UICollectionViewCell {

    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var reasonTextLabel: UILabel!

    
    func configure(with message: MessageType,
                   at indexPath: IndexPath,
                   and messagesCollectionView: MessagesCollectionView) {
        
        guard let chatMessage = message as? ChatMessage else {
            return
        }
        
        var icon: UIImage?
        var reason: String?
        
        if case .callEnded = chatMessage.message.type {
            icon = UIImage.mnz_image(by: chatMessage.message.termCode, userHandle: chatMessage.message.userHandle)
            reason = NSString.mnz_string(by: chatMessage.message.termCode,
                                             userHandle: chatMessage.message.userHandle,
                                             duration: NSNumber(value: chatMessage.message.duration),
                                             isGroup: chatMessage.chatRoom.isGroup)
        } else {
            icon = UIImage(named: "callWithXIncoming")
            reason = AMLocalizedString("Call Started", "Text to inform the user there is an active call and is participating")
        }
        
        iconImageView.image = icon
        reasonTextLabel.text = reason
    }

}

class ChatViewCallCollectionCellCalculator: MessageSizeCalculator {
    
    override func messageContainerSize(for message: MessageType) -> CGSize {
        guard let layout = layout else { return .zero }

        let collectionViewWidth = layout.collectionView?.bounds.width ?? 0
        let contentInset = layout.collectionView?.contentInset ?? .zero
        let inset = layout.sectionInset.left + layout.sectionInset.right + contentInset.left + contentInset.right
        return CGSize(width: collectionViewWidth - inset, height: 30)
    }
}
