import MEGAL10n
import MessageKit

class ChatLocationCollectionViewCell: MessageContentCell {

    open var locationView: GeoLocationView = {
        let view = GeoLocationView.instanceFromNib
        return view
    }()
    
    // MARK: - Methods
    
    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        NSLayoutConstraint.activate([
            locationView.topAnchor.constraint(equalTo: messageContainerView.topAnchor),
            locationView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor),
            locationView.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor),
            locationView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor)
        ])
    }
    
    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(locationView)

        setupConstraints()
    }
    
    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        guard let chatMessage = message as? ChatMessage else {
            return
        }
        
        let megaMessage = chatMessage.message
        if let image = megaMessage.containsMeta?.geolocation?.image,
            let imageData = Data(base64Encoded: image, options: .ignoreUnknownCharacters) {
            locationView.imageView.image = UIImage(data: imageData)
        }
        locationView.titleLabel.text = Strings.Localizable.pinnedLocation
        
        guard let containsMeta = megaMessage.containsMeta, 
              let latitude = containsMeta.geolocation?.latitude,
              let longitude = containsMeta.geolocation?.longitude else {
            return
        }
        locationView.subtitleLabel.text = NSString.mnz_convertCoordinatesLatitude(latitude, longitude: longitude)
    }
}

open class ChatlocationCollectionViewSizeCalculator: MessageSizeCalculator {
    let locationImageViewHeight: CGFloat = 129
    let verticalPadding: CGFloat = 27 // Label's stackview spacing, padding top, bottom and container view top padding
    
    lazy var calculateTitleLabel: UILabel = {
        let titleLabel = UILabel()
        return titleLabel
    }()
    
    lazy var calculateSubtitleLabel: UILabel = {
        let subtitleLabel = UILabel()
        return subtitleLabel
    }()
   
    public override init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        configureAccessoryView()
    }
    
    open override func messageContainerMaxWidth(for message: any MessageType, at indexPath: IndexPath) -> CGFloat {
        min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), 260)
    }
    
    open override func messageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        switch message.kind {
        case .custom:
            let fitSize = CGSize(width: messageContainerMaxWidth(for: message, at: indexPath), height: .greatestFiniteMagnitude)
            return calculateDynamicSize(for: message, fitSize: fitSize)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
    
    private func calculateDynamicSize(for message: any MessageType, fitSize: CGSize) -> CGSize {
        calculateTitleLabel.font = UIFont.preferredFont(style: .subheadline, weight: .medium)
        calculateTitleLabel.text = Strings.Localizable.pinnedLocation
        calculateSubtitleLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
        calculateSubtitleLabel.text = Strings.Localizable.pinnedLocation
        
        let titleLabelHeight = calculateTitleLabel.sizeThatFits(fitSize).height
        let subtitleLabelHeight = calculateSubtitleLabel.sizeThatFits(fitSize).height
        
        return CGSize(width: fitSize.width, height: locationImageViewHeight + titleLabelHeight + subtitleLabelHeight + verticalPadding)
    }
}
