import MessageKit

class ChatUnreadMessagesLabelCollectionCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!

    var unreadMessageCount: Int = 0 {
        didSet {
            if unreadMessageCount <= 0 {
                label.text = ""
            } else if unreadMessageCount == 1 {
                label.text = Strings.Localizable.unreadMessage(unreadMessageCount).localizedUppercase
            } else {
                label.text = Strings.Localizable.unreadMessages(unreadMessageCount).localizedUppercase
            }
        }
    }
}

class ChatUnreadMessagesLabelCollectionCellSizeCalculator: MessageSizeCalculator {
    let verticalSpacing: CGFloat = 20 // Label's top and bottom spacing
    let fitSize = CGSize(width: UIScreen.main.bounds.width, height: .greatestFiniteMagnitude)
   
    lazy var calculateTitleLabel: MEGALabel = {
        let titleLabel = MEGALabel(frame: .zero)
        titleLabel.apply(style: .body)
        titleLabel.text = Strings.Localizable.unreadMessage(1).localizedUppercase
        return titleLabel
    }()
    
    override func messageContainerSize(for message: MessageType) -> CGSize {
        guard let notificationMessage = message as? ChatNotificationMessage, case .unreadMessage(let count) = notificationMessage.type, count > 0 else {
            return .zero
        }
        return calculateDynamicSize()
    }
    
    private func calculateDynamicSize() -> CGSize {
        CGSize(width: fitSize.width, height: calculateTitleLabel.sizeThatFits(fitSize).height + verticalSpacing)
    }
}
