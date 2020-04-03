import MessageKit

class ChatViewAttachmentCell: UICollectionViewCell {
      
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    func configure(with message: MessageType,
                     at indexPath: IndexPath,
                     and messagesCollectionView: MessagesCollectionView) {
          guard let chatMessage = message as? ChatMessage else {
              return
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
