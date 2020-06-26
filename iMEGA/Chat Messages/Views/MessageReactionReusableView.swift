import MessageKit

class MessageReactionReusableView: MessageReusableView, UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView
             .dequeueReusableCell(withReuseIdentifier: ReactionCollectionViewCell.reuseIdentifier, for: indexPath)
//           cell.backgroundColor = .black
           // Configure the cell
           return cell
    }
   
    @IBOutlet weak var reactionCollectionView: UICollectionView!
    
    
    var chatMessage: ChatMessage? {
        didSet {
            let megaMessage = chatMessage?.message
            MEGASdkManager.sharedMEGAChatSdk()?.addReaction(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0, reaction: "😃")
            MEGASdkManager.sharedMEGAChatSdk()?.getMessageReactions(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        reactionCollectionView.delegate = self
        reactionCollectionView.dataSource = self
        
        reactionCollectionView.register(ReactionCollectionViewCell.nib, forCellWithReuseIdentifier: ReactionCollectionViewCell.reuseIdentifier)
        // Initialization code
        
        guard let flowLayout = reactionCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
            return
        }
        
        flowLayout.estimatedItemSize = CGSize(width: 1, height: 1)
    }
    
}


//
//extension MessageReactionReusableView: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: 100, height: 30)
//    }
//}
