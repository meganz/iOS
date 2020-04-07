import MessageKit

class ChatViewContactCell: MessageContentCell {

    open var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 20
        imageView.clipsToBounds = true
        return imageView
    }()

    public lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.font = UIFont.mnz_SFUIMedium(withSize: 14)
        titleLabel.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        return titleLabel
    }()

    public lazy var detailLabel: UILabel = {
        let detailLabel = UILabel(frame: CGRect.zero)
        detailLabel.font = UIFont.mnz_SFUIRegular(withSize: 12)
        detailLabel.textColor = #colorLiteral(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        return detailLabel
    }()

    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        imageView.autoSetDimensions(to: CGSize(width: 40, height: 40))
        imageView.autoAlignAxis(toSuperviewAxis: .horizontal)
        imageView.autoPinEdge(toSuperviewEdge: .leading, withInset: 10)

        titleLabel.autoPinEdge(.leading, to: .trailing, of: imageView, withOffset: 10)
        titleLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: 10)
        titleLabel.autoSetDimension(.height, toSize: 18)
        titleLabel.autoAlignAxis(.horizontal, toSameAxisOf: messageContainerView, withOffset: -8)

        detailLabel.autoPinEdge(.leading, to: .trailing, of: imageView, withOffset: 10)
        detailLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: 10)
        detailLabel.autoSetDimension(.height, toSize: 18)
        detailLabel.autoAlignAxis(.horizontal, toSameAxisOf: messageContainerView, withOffset: 8)
    }

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(imageView)
        messageContainerView.addSubview(titleLabel)
        messageContainerView.addSubview(detailLabel)
        setupConstraints()
    }
    
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)

        guard let chatMessage = message as? ChatMessage else {
            return
        }
        let megaMessage = chatMessage.message
        
        var title, detail : String
        if megaMessage.usersCount == 1 {
            imageView.mnz_setImage(forUserHandle: megaMessage.userHandle(at: 0), name: megaMessage.userName(at: 0))
            title = megaMessage.userName(at: 0)
            detail = megaMessage.userEmail(at: 0)
        } else {
            var usersString = NSLocalizedString("XContactsSelected", comment: "")
            usersString = usersString.replacingOccurrences(of: "[X]", with: "\(megaMessage.usersCount)", options: .literal, range: nil)
            title = usersString

            var emails = megaMessage.userEmail(at: 0)
            for index in 2...megaMessage.usersCount {
                emails = "\(emails!) \(megaMessage.userEmail(at: index - 1)!)"
            }
           detail = emails!
        }
        
        titleLabel.text = title
        detailLabel.text = detail
        
    }
}

open class CustomContactMessageSizeCalculator: MessageSizeCalculator {
    public override init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        outgoingAvatarSize = .zero
        outgoingMessageTopLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12))

    }

    open override func messageContainerSize(for message: MessageType) -> CGSize {
        switch message.kind {
        case .custom:
            let maxWidth = messageContainerMaxWidth(for: message)
            guard let chatMessage = message as? ChatMessage else {
                return .zero
            }
            
            let megaMessage = chatMessage.message
            var title, detail : String
            var width = CGFloat()
            if megaMessage.usersCount == 1 {
                title = megaMessage.userName(at: 0)
                detail = megaMessage.userEmail(at: 0)
            } else {
                var usersString = NSLocalizedString("XContactsSelected", comment: "")
                usersString = usersString.replacingOccurrences(of: "[X]", with: "\(megaMessage.usersCount)", options: .literal, range: nil)
                title = usersString
                var emails = megaMessage.userEmail(at: 0)
                for index in 2...megaMessage.usersCount {
                    emails = "\(emails!) \(megaMessage.userEmail(at: index - 1)!)"
                }
                detail = emails!
            }
            let titleSize: CGSize = title.size(withAttributes: [.font: UIFont.mnz_SFUIMedium(withSize: 14)!])
            let detailSize: CGSize = detail.size(withAttributes: [.font: UIFont.mnz_SFUIRegular(withSize: 12)!])
            width = 75 + max(titleSize.width, detailSize.width)
            return CGSize(width: min(width, maxWidth), height: 80)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}
