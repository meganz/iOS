import MessageKit

class ChatLocationCollectionViewCell: MessageContentCell {

    open var locationView: GeoLocationView = {
        let view = GeoLocationView.instanceFromNib
        return view
    }()
    
    // MARK: - Methods
    
    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        locationView.autoPinEdgesToSuperviewEdges()
    }
    
    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(locationView)

        setupConstraints()
    }
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)

    }
}

open class ChatlocationCollectionViewSizeCalculator: MessageSizeCalculator {
   
    public override init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        configureAccessoryView()
    }
    
    open override func messageContainerSize(for message: MessageType) -> CGSize {
        switch message.kind {
        case .custom:
            return CGSize(width: 260, height: 190)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}
