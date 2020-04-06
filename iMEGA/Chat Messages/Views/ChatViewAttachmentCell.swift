import MessageKit

class ChatViewAttachmentCell: UICollectionViewCell {
      
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var messageTimeLabel: UILabel!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var attachmentImageView: UIImageView!
    @IBOutlet weak var leftForward: UIImageView!
    @IBOutlet weak var rightForward: UIImageView!
    func configure(with message: MessageType,
                     at indexPath: IndexPath,
                     and messagesCollectionView: MessagesCollectionView) {
          guard let chatMessage = message as? ChatMessage else {
              return
          }
        
        let megaMessage = chatMessage.message
        if megaMessage.userHandle == MEGASdkManager.sharedMEGAChatSdk().myUserHandle {
            avatarImageView.isHidden = true
            messageTimeLabel.textAlignment = .left
        } else {
            avatarImageView.image = chatMessage.avatarImage
            messageTimeLabel.textAlignment = .right

            
        }
        
      }
}




class ChatViewAttachmentCellCalculator: MessageSizeCalculator {

    override func messageContainerSize(for message: MessageType) -> CGSize {
        guard let layout = layout else { return .zero }

        let collectionViewWidth = layout.collectionView?.bounds.width ?? 0
        let contentInset = layout.collectionView?.contentInset ?? .zero
        let inset = layout.sectionInset.left + layout.sectionInset.right + contentInset.left + contentInset.right
        return CGSize(width: collectionViewWidth - inset, height: 120)
    }
}
