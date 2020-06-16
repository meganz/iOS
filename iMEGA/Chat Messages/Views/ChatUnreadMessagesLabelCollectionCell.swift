import MessageKit

class ChatUnreadMessagesLabelCollectionCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!

    var unreadMessageCount: Int = 0 {
        didSet {
            if unreadMessageCount == 1 {
                label.text = String(format: AMLocalizedString("unreadMessage"), unreadMessageCount)
            } else {
                label.text = String(format: AMLocalizedString("unreadMessages"), unreadMessageCount)
            }
        }
    }

}

class ChatUnreadMessagesLabelCollectionCellSizeCalculator: MessageSizeCalculator {
    
    override func messageContainerSize(for message: MessageType) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 30)
    }
}
