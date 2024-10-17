import MEGAL10n
import MessageKit

class ChatViewCallCollectionCell: MessageContentCell {
    let defaultIconSize: CGFloat = 36
    
    open var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    open var reasonTextLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()
    
    open var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 8
        stack.distribution = .fill
        return stack
    }()
   
    // MARK: - Methods
    
    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: messageContainerView.safeAreaLayoutGuide.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: messageContainerView.safeAreaLayoutGuide.bottomAnchor),
            stackView.centerXAnchor.constraint(equalTo: messageContainerView.safeAreaLayoutGuide.centerXAnchor),
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: messageContainerView.safeAreaLayoutGuide.leadingAnchor, constant: 5.0),

            iconImageView.heightAnchor.constraint(equalToConstant: defaultIconSize),
            iconImageView.widthAnchor.constraint(equalToConstant: defaultIconSize)
        ])
    }

    override open func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(stackView)
        stackView.addArrangedSubview(iconImageView)
        stackView.addArrangedSubview(reasonTextLabel)

        setupConstraints()
    }

    override func configure(
        with message: any MessageType,
        at indexPath: IndexPath,
        and messagesCollectionView: MessagesCollectionView
    ) {
        
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
            icon = UIImage(resource: .callWithXIncoming) 
            reason = Strings.Localizable.callStarted
        }
        
        iconImageView.image = icon
        reasonTextLabel.text = reason
        reasonTextLabel.font = UIFont.preferredFont(style: .subheadline, weight: .medium)
        reasonTextLabel.adjustsFontForContentSizeCategory = true
    }

}

class ChatViewCallCollectionCellCalculator: MessageSizeCalculator {
    
    lazy var layoutCell = ChatViewCallCollectionCell()
    
    override public init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        incomingAvatarSize = .zero
        incomingMessagePadding = .zero
    }
    
    override func messageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        guard let layout = layout else { return .zero }

        let collectionViewWidth = layout.collectionView?.bounds.width ?? .zero
        let contentInset = layout.collectionView?.contentInset ?? .zero
        let inset = layout.sectionInset.left + layout.sectionInset.right + contentInset.left + contentInset.right
        
        layoutCell.configure(with: message, at: IndexPath(row: 0, section: 0), and: messagesLayout.messagesCollectionView)
        
        let height = layoutCell.reasonTextLabel.text?.height(withConstrainedWidth: collectionViewWidth - inset, font: layoutCell.reasonTextLabel.font) ?? .zero
        
        return CGSize(width: collectionViewWidth - inset, height: max(height, layoutCell.defaultIconSize))
    }
}
