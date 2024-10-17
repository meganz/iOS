import MEGADesignToken
import MessageKit

class ChatViewAttachmentCell: MessageContentCell {
    
    private let imageWidth: CGFloat = 40.0
    private let defaultSpacing: CGFloat = 10.0

    public lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageWidth, height: imageWidth))
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    public lazy var titleLabel: MEGALabel = {
        let titleLabel = MEGALabel(frame: .zero)
        titleLabel.apply(style: .footnote, weight: .medium)
        titleLabel.textColor = UIColor.label
        titleLabel.lineBreakMode = .byTruncatingMiddle
        return titleLabel
    }()

    public lazy var detailLabel: MEGALabel = {
        let detailLabel = MEGALabel(frame: .zero)
        detailLabel.apply(style: .caption1)
        detailLabel.textColor = UIColor.mnz_subtitles()
        detailLabel.lineBreakMode = .byTruncatingMiddle
        return detailLabel
    }()
    
    public lazy var labelsStackView: UIStackView = {
        let labelsStackView = UIStackView()
        labelsStackView.translatesAutoresizingMaskIntoConstraints = false
        labelsStackView.axis = .vertical
        labelsStackView.distribution  = .fill
        labelsStackView.alignment = .fill
        labelsStackView.spacing = 3.0
        return labelsStackView
    }()

    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: imageWidth),
            imageView.heightAnchor.constraint(equalToConstant: imageWidth),
            imageView.centerYAnchor.constraint(equalTo: messageContainerView.centerYAnchor),
            imageView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor, constant: defaultSpacing)
        ])
        
        NSLayoutConstraint.activate([
            labelsStackView.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: defaultSpacing),
            labelsStackView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor, constant: -defaultSpacing),
            labelsStackView.topAnchor.constraint(equalTo: messageContainerView.topAnchor, constant: defaultSpacing),
            labelsStackView.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor, constant: -defaultSpacing)
        ])
    }

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(imageView)
        labelsStackView.addArrangedSubview(titleLabel)
        labelsStackView.addArrangedSubview(detailLabel)
        messageContainerView.addSubview(labelsStackView)
        setupConstraints()
    }
    
    var attachmentViewModel: ChatViewAttachmentCellViewModel! {
        didSet {
            configureUI()
        }
    }
    
    private func configureUI() {
        titleLabel.text = attachmentViewModel.title
        detailLabel.text = attachmentViewModel.subtitle
        attachmentViewModel.set(imageView: imageView)
        titleLabel.textColor = attachmentViewModel.isFromCurrentSender ? TokenColors.Text.inverseAccent : TokenColors.Text.primary
        titleLabel.apply(style: .footnote, weight: .bold)
        detailLabel.textColor = attachmentViewModel.isFromCurrentSender ? TokenColors.Text.inverseAccent : TokenColors.Text.primary
    }
    
    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        guard let chatMessage = message as? ChatMessage else {
            return
        }
        
        self.attachmentViewModel = ChatViewAttachmentCellViewModel(chatMessage: chatMessage)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        titleLabel.textColor = attachmentViewModel.isFromCurrentSender ? TokenColors.Text.inverseAccent : TokenColors.Text.primary
        titleLabel.apply(style: .footnote, weight: .bold)
        detailLabel.textColor = attachmentViewModel.isFromCurrentSender ? TokenColors.Text.inverseAccent : TokenColors.Text.primary
    }
    
    func sizeThatFits() -> CGSize {
        titleLabel.sizeToFit()
        detailLabel.sizeToFit()
        
        let width = defaultSpacing
            + imageWidth
            + defaultSpacing
            + max(titleLabel.bounds.width, detailLabel.bounds.width)
            + defaultSpacing
        
        let height = defaultSpacing
            + titleLabel.bounds.height
            + labelsStackView.spacing
            + detailLabel.bounds.height
            + defaultSpacing
        
        return CGSize(width: width, height: height)
    }
}

open class ChatViewAttachmentCellCalculator: MessageSizeCalculator {
    
    let chatViewAttachmentCell = ChatViewAttachmentCell()
    
    public override init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        configureAccessoryView()
    }

    open override func messageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
       guard let chatMessage = message as? ChatMessage else {
            fatalError("ChatViewAttachmentCellCalculator: wrong type message passed.")
        }
        
        let maxWidth = messageContainerMaxWidth(for: message, at: indexPath)
        
        chatViewAttachmentCell.attachmentViewModel = ChatViewAttachmentCellViewModel(chatMessage: chatMessage)
        let size = chatViewAttachmentCell.sizeThatFits()
        
        return CGSize(width: min(size.width, maxWidth), height: size.height)
    }
}
