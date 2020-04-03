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
       
        return CGSize(width: 320, height: 120)
    }
}
