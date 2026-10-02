import MEGAL10n
import MessageKit

class ChatUnreadMessagesLabelCollectionCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!

    var unreadMessageCount: Int = 0 {
        didSet {
            label.text = unreadMessageCount > 0 ? Strings.Localizable.Chat.Message.unreadMessage(unreadMessageCount) : ""
        }
    }
}

class ChatUnreadMessagesLabelCollectionCellSizeCalculator: MessageSizeCalculator {
    let verticalSpacing: CGFloat = 20 // Label's top and bottom spacing
    private var fitSize: CGSize {
        let width = layout?.collectionView?.bounds.width ?? UIApplication.mnz_keyWindow()?.bounds.width ?? 0
        return CGSize(width: width, height: .greatestFiniteMagnitude)
    }
   
    lazy var calculateTitleLabel: MEGALabel = {
        let titleLabel = MEGALabel(frame: .zero)
        titleLabel.apply(style: .body)
        titleLabel.text = Strings.Localizable.Chat.Message.unreadMessage(1)
        return titleLabel
    }()
    
    override func messageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        // MessageKit asks for this from both sizeForItem and configure(attributes:); the layout
        // keeps one measurement per message so the second ask is a lookup.
        guard let layout = layout as? ChatViewMessagesFlowLayout else {
            return measuredMessageContainerSize(for: message, at: indexPath)
        }

        return layout.cachedMessageContainerSize(for: message, at: indexPath) {
            measuredMessageContainerSize(for: message, at: indexPath)
        }
    }

    private func measuredMessageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        guard let notificationMessage = message as? ChatNotificationMessage, case .unreadMessage(let count) = notificationMessage.type, count > 0 else {
            return .zero
        }
        let size = calculateDynamicSize()
        return size.positiveWidth
    }
    
    private func calculateDynamicSize() -> CGSize {
        CGSize(width: fitSize.width, height: calculateTitleLabel.sizeThatFits(fitSize).height + verticalSpacing)
    }
}
