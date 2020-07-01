import AlignedCollectionViewFlowLayout
import MessageKit

protocol MessageReactionReusableViewDelegate: class {
    func emojiTapped(_ emoji: String, chatMessage: ChatMessage)
    func emojiLongPressed(_ emoji: String, chatMessage: ChatMessage)
}

class MessageReactionReusableView: MessageReusableView, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet var reactionCollectionView: UICollectionView!
    var emojis = [String]()
    var indexPath: IndexPath?
    
    var chatMessage: ChatMessage? {
        didSet {
            emojis.removeAll()
            let megaMessage = chatMessage?.message
            let list = MEGASdkManager.sharedMEGAChatSdk()?.getMessageReactions(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0)
            for index in 0 ..< list!.size {
                emojis.append((list?.string(at: index))!)
            }
            guard let flowLayout = reactionCollectionView.collectionViewLayout as? AlignedCollectionViewFlowLayout else {
                return
            }
            if isFromCurrentSender(message: chatMessage!) {
                //                flowLayout.horizontalAlignment = .right
                
                reactionCollectionView.transform = CGAffineTransform(scaleX: -1, y: 1)
                
            } else {
                reactionCollectionView.transform = CGAffineTransform(scaleX: 1, y: 1)
                
                //                flowLayout.horizontalAlignment = .left
            }
            flowLayout.invalidateLayout()
            
            configureDisplaying()
            reactionCollectionView.reloadData()
        }
    }
    
    weak var delegate: MessageReactionReusableViewDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        reactionCollectionView.delegate = self
        reactionCollectionView.dataSource = self
        reactionCollectionView.register(ReactionAddButtonCell.nib, forCellWithReuseIdentifier: ReactionAddButtonCell.reuseIdentifier)
        
        reactionCollectionView.register(ReactionCollectionViewCell.nib, forCellWithReuseIdentifier: ReactionCollectionViewCell.reuseIdentifier)
        // Initialization code
        
        guard let flowLayout = reactionCollectionView.collectionViewLayout as? AlignedCollectionViewFlowLayout else {
            return
        }
        flowLayout.estimatedItemSize = CGSize(width: 1, height: 1)
        flowLayout.minimumInteritemSpacing = 4
        
    }
    
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int {
        return emojis.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        var cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: ReactionCollectionViewCell.reuseIdentifier, for: indexPath)
        var emoji = ""
        
        
        
        if indexPath.row == emojis.count {
            cell = collectionView
                .dequeueReusableCell(withReuseIdentifier: ReactionAddButtonCell.reuseIdentifier, for: indexPath)
            cell.contentView.transform = CGAffineTransform(scaleX: -1, y: 1)
            
            return cell
        } else {
            
            emoji = emojis[indexPath.row]
            
            
            
            
            
            let megaMessage = chatMessage?.message
            
            let count = MEGASdkManager.sharedMEGAChatSdk()?.getMessageReactionCount(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: emoji) ?? 0
            
            if let reactionCell = cell as? ReactionCollectionViewCell {
                reactionCell.configureCell(emoji, count)
                reactionCell.delegate = self
            }
            
        }
        
        if isFromCurrentSender(message: chatMessage!) {
            cell.contentView.transform = CGAffineTransform(scaleX: -1, y: 1)
        } else {
            cell.contentView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        return cell
    }
    
    func isFromCurrentSender(message: MessageType) -> Bool {
        return UInt64(message.sender.senderId) == MEGASdkManager.sharedMEGAChatSdk()?.myUserHandle
    }
    
    func configureDisplaying() {
        // Get the collectionView
        if let collectionView = self.superview as? UICollectionView {
            // Get indexPath
            guard  let indexPath = indexPath,
                let cell = collectionView.cellForItem(at: indexPath) as? MessageContentCell else {
                    return
            }
            let messageContainerView = cell.messageContainerView
            reactionCollectionView.frame = messageContainerView.frame
            reactionCollectionView.isHidden = emojis.count == 0
        }
    }
}

extension MessageReactionReusableView: ReactionCollectionViewCellDelegate {
    func emojiTapped(_ emoji: String) {
        guard let delegate = delegate, let chatMessage = chatMessage else {
            return
        }
        
        delegate.emojiTapped(emoji, chatMessage: chatMessage)
    }
    
    func emojiLongPressed(_ emoji: String) {
        guard let delegate = delegate, let chatMessage = chatMessage else {
            return
        }
        
        delegate.emojiLongPressed(emoji, chatMessage: chatMessage)
    }
}

//
//
//extension MessageReactionReusableView: MEGAChatRoomDelegate {
//
//    func onReactionUpdate(_ api: MEGAChatSdk!, messageId: UInt64, reaction: String!, count: Int) {
//        print(reaction)
//    }
//}
