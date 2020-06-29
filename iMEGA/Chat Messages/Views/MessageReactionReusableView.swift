import MessageKit
import AlignedCollectionViewFlowLayout

class MessageReactionReusableView: MessageReusableView, UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView
            .dequeueReusableCell(withReuseIdentifier: ReactionCollectionViewCell.reuseIdentifier, for: indexPath)
        
        if indexPath.section == 1 {
            
        }
        
        
        return cell
    }
    
    @IBOutlet weak var reactionCollectionView: UICollectionView!
    var emojis = [String]()
    
    var chatMessage: ChatMessage? {
        didSet {
            emojis.removeAll()
            let megaMessage = chatMessage?.message
            let list = MEGASdkManager.sharedMEGAChatSdk()?.getMessageReactions(forChat: chatMessage?.chatRoom.chatId ?? 0, messageId: megaMessage?.messageId ?? 0)
            for index in 0..<list!.size {
                emojis.append((list?.string(at: index))!)
            }
            print(emojis)
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        reactionCollectionView.delegate = self
        reactionCollectionView.dataSource = self
        
        reactionCollectionView.register(ReactionCollectionViewCell.nib, forCellWithReuseIdentifier: ReactionCollectionViewCell.reuseIdentifier)
        // Initialization code
        
        guard let flowLayout = reactionCollectionView.collectionViewLayout as? AlignedCollectionViewFlowLayout else {
            return
        }
        flowLayout.horizontalAlignment = .trailing
        flowLayout.estimatedItemSize = CGSize(width: 1, height: 1)
    }
    
}


//
//extension MessageReactionReusableView: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        return CGSize(width: 100, height: 30)
//    }
//}
