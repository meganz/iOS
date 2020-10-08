import MessageKit

class ChatViewCallCollectionCell: MessageContentCell {
    
    open var iconImageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    open var reasonTextLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        return label
    }()
    
    open var containerView = UIView()
    // MARK: - Methods
    
    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        containerView.autoCenterInSuperview()
        containerView.autoSetDimension(.height, toSize: 36)
        containerView.autoPinEdge(toSuperviewSafeArea: .leading, withInset: 10, relation: .greaterThanOrEqual)
        containerView.autoPinEdge(toSuperviewSafeArea: .trailing, withInset: 10, relation: .greaterThanOrEqual)

        iconImageView.autoSetDimensions(to: CGSize(width: 36, height: 36))
        iconImageView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .trailing)
        iconImageView.autoPinEdge(.trailing, to: .leading, of: reasonTextLabel, withOffset: -8)
        reasonTextLabel.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .leading)
    }

    override open func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(reasonTextLabel)

        setupConstraints()
    }

    override func configure(with message: MessageType,
                   at indexPath: IndexPath,
                   and messagesCollectionView: MessagesCollectionView) {
        
        super.configure(with: message, at: indexPath, and: messagesCollectionView)

        guard let chatMessage = message as? ChatMessage else {
            return
        }
        
        var icon: UIImage?
        var reason: String?
        
        if case .callEnded = chatMessage.message.type {
            icon = UIImage.mnz_image(by: chatMessage.message.termCode, userHandle: chatMessage.message.userHandle)
            reason = NSString.mnz_string(by: chatMessage.message.termCode,
                                             userHandle: chatMessage.message.userHandle,
                                             duration: NSNumber(value: chatMessage.message.duration),
                                             isGroup: chatMessage.chatRoom.isGroup)
        } else {
            icon = UIImage(named: "callWithXIncoming")
            reason = AMLocalizedString("Call Started", "Text to inform the user there is an active call and is participating")
        }
        
        iconImageView.image = icon
        reasonTextLabel.text = reason
    }

}

class ChatViewCallCollectionCellCalculator: MessageSizeCalculator {
    
    override public init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        incomingAvatarSize = .zero
        incomingMessagePadding = .zero
    }
    
    override func messageContainerSize(for message: MessageType) -> CGSize {
        guard let layout = layout else { return .zero }

        let collectionViewWidth = layout.collectionView?.bounds.width ?? 0
        let contentInset = layout.collectionView?.contentInset ?? .zero
        let inset = layout.sectionInset.left + layout.sectionInset.right + contentInset.left + contentInset.right
        return CGSize(width: collectionViewWidth - inset, height: 30)
    }
}
