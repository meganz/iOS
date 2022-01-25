import MessageKit

class ChatViewAttachmentCell: MessageContentCell {
    
    private let imageWidth: CGFloat = 40.0
    private let defaultSpacing: CGFloat = 10.0

    public lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: imageWidth, height: imageWidth))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    public lazy var titleLabel: MEGALabel = {
        let titleLabel = MEGALabel(frame: .zero)
        titleLabel.apply(style: .footnote, weight: .medium)
        titleLabel.textColor = UIColor.mnz_label()
        titleLabel.lineBreakMode = .byTruncatingMiddle
        return titleLabel
    }()

    public lazy var detailLabel: MEGALabel = {
        let detailLabel = MEGALabel(frame: .zero)
        detailLabel.apply(style: .caption1)
        detailLabel.textColor = UIColor.mnz_subtitles(for: UIScreen.main.traitCollection)
        detailLabel.lineBreakMode = .byTruncatingMiddle
        return detailLabel
    }()
    
    public lazy var labelsStackView: UIStackView = {
        let labelsStackView = UIStackView()
        labelsStackView.axis = .vertical
        labelsStackView.distribution  = .fill
        labelsStackView.alignment = .fill
        labelsStackView.spacing = 3.0
        return labelsStackView
    }()

    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        imageView.autoSetDimensions(to: CGSize(width: imageWidth, height: imageWidth))
        imageView.autoAlignAxis(toSuperviewAxis: .horizontal)
        imageView.autoPinEdge(toSuperviewEdge: .leading, withInset: defaultSpacing)
        
        labelsStackView.autoPinEdge(.leading, to: .trailing, of: imageView, withOffset: defaultSpacing)
        labelsStackView.autoPinEdge(toSuperviewEdge: .trailing, withInset: defaultSpacing)
        labelsStackView.autoPinEdge(toSuperviewEdge: .top, withInset: defaultSpacing)
        labelsStackView.autoPinEdge(toSuperviewEdge: .bottom, withInset: defaultSpacing)
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
    }
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        guard let chatMessage = message as? ChatMessage else {
            return
        }
        
        self.attachmentViewModel = ChatViewAttachmentCellViewModel(chatMessage: chatMessage)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        titleLabel.textColor = UIColor.mnz_label()
        detailLabel.textColor = UIColor.mnz_subtitles(for: UIScreen.main.traitCollection)
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

    open override func messageContainerSize(for message: MessageType) -> CGSize {
       guard let chatMessage = message as? ChatMessage else {
            fatalError("ChatViewAttachmentCellCalculator: wrong type message passed.")
        }
        
        let maxWidth = messageContainerMaxWidth(for: message)
        
        chatViewAttachmentCell.attachmentViewModel = ChatViewAttachmentCellViewModel(chatMessage: chatMessage)
        let size = chatViewAttachmentCell.sizeThatFits()
        
        return CGSize(width: min(size.width, maxWidth), height: size.height)
    }
}
