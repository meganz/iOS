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
        
        let totalNodes = megaMessage.nodeList.size.uintValue
        if totalNodes == 1 {
            let node = megaMessage.nodeList.node(at: 0)!
            titleLabel.text = node.name;
            detailLabel.text = Helper.memoryStyleString(fromByteCount: node.size.int64Value)
            attachmentImageView.mnz_setThumbnail(by: node)
        }
                  
        if megaMessage.userHandle == MEGASdkManager.sharedMEGAChatSdk().myUserHandle {
            avatarImageView.isHidden = true
            messageTimeLabel.textAlignment = .right
            leftForward.isHidden = false
            rightForward.isHidden = true
            containerView.autoPinEdge(toSuperviewEdge: .right)
            containerView.layer.borderColor = #colorLiteral(red: 0, green: 0.5803921569, blue: 0.462745098, alpha: 1).cgColor

        } else {
            avatarImageView.image = chatMessage.avatarImage
            messageTimeLabel.textAlignment = .left
            leftForward.isHidden = true
             rightForward.isHidden = false
            containerView.autoPinEdge(toSuperviewEdge: .left)
            containerView.layer.borderColor = #colorLiteral(red: 0.8941176471, green: 0.9215686275, blue: 0.9176470588, alpha: 1).cgColor

        }
        containerView.autoPinEdge(toSuperviewEdge: .top)
        containerView.autoPinEdge(toSuperviewEdge: .bottom)

        let size: CGSize = titleLabel.text!.size(withAttributes: [.font: UIFont.systemFont(ofSize:14)])
        let width = min(280, size.width + 80)
        containerView.autoSetDimension(.width, toSize: CGFloat(width))

        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        containerView.layer.borderWidth = 1
        
      
        
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
