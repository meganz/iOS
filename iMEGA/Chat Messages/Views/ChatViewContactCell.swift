import MessageKit

class ChatViewContactCell: MessageContentCell {

    /// The image view display the media content.
    open var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = #imageLiteral(resourceName: "illustrator")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    /// The time duration lable to display on audio messages.
    public lazy var titleLabel: UILabel = {
        let titleLabel = UILabel(frame: CGRect.zero)
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.text = "123"
        return titleLabel
    }()

    /// The time duration lable to display on audio messages.
    public lazy var detailLabel: UILabel = {
        let detailLabel = UILabel(frame: CGRect.zero)
        detailLabel.font = UIFont.systemFont(ofSize: 14)
        detailLabel.text = "456"

        return detailLabel
    }()

    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        imageView.autoSetDimensions(to: CGSize(width: 40, height: 40))
        imageView.autoAlignAxis(toSuperviewAxis: .horizontal)
        imageView.autoPinEdge(toSuperviewEdge: .leading, withInset: CGFloat(10))

        titleLabel.autoPinEdge(.leading, to: .trailing, of: imageView)
        titleLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: CGFloat(-10))
        titleLabel.autoSetDimension(.height, toSize: 18)
        titleLabel.autoAlignAxis(.horizontal, toSameAxisOf: messageContainerView, withOffset: -8)

        detailLabel.autoPinEdge(.leading, to: .trailing, of: imageView)
        detailLabel.autoPinEdge(toSuperviewEdge: .trailing, withInset: CGFloat(-10))
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
}

open class CustomContactMessageSizeCalculator: MessageSizeCalculator {
    public override init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        outgoingAvatarSize = .zero
    }

    open override func messageContainerSize(for message: MessageType) -> CGSize {
        switch message.kind {
        case .custom:
            let maxWidth = messageContainerMaxWidth(for: message)
            return CGSize(width: maxWidth, height: 80)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}
