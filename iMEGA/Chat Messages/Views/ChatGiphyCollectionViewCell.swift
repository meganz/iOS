import CoreGraphics
import MessageKit

class ChatGiphyCollectionViewCell: MessageContentCell {
    open var imageView: UIImageView = {
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.backgroundColor = .clear
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    open var loadingIndicator: UIActivityIndicatorView = {
        let loadingIndicator = UIActivityIndicatorView(style: .medium)
        loadingIndicator.startAnimating()
        loadingIndicator.hidesWhenStopped = true
        return loadingIndicator
    }()

    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        imageView.autoPinEdgesToSuperviewEdges()

        loadingIndicator.autoCenterInSuperview()
        loadingIndicator.autoSetDimensions(to: CGSize(width: 20, height: 20))
    }

    override open func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(imageView)
        messageContainerView.addSubview(loadingIndicator)

        setupConstraints()
    }

    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        guard let chatMessage = message as? ChatMessage else {
            return
        }

        let megaMessage = chatMessage.message
        guard let giphy = megaMessage.containsMeta?.giphy, let webpSrc = giphy.webpSrc else {
            return
        }
        loadingIndicator.startAnimating()
        let url = webpSrc.replacingOccurrences(of: ServiceManager.shared.GIPHY_URL, with: ServiceManager.shared.BASE_URL)
        
        imageView.sd_setImage(with: URL(string: url)) { (_, _, _, _) in
            self.loadingIndicator.stopAnimating()
        }
    }
}

open class ChatGiphyCollectionViewSizeCalculator: MessageSizeCalculator {
    override public init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        configureAccessoryView()
    }

    override open func messageContainerSize(for message: MessageType) -> CGSize {
        switch message.kind {
        case .custom:
            return size(for: message)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
    
    private func size(for message: MessageType) -> CGSize {
        let maxHeight = UIDevice.current.mnz_maxSideForChatBubble(withMedia: true)
        let maxWidth = min(maxHeight, messageContainerMaxWidth(for: message))
        
        guard let chatMessage = message as? ChatMessage,
                case let megaMessage = chatMessage.message,
                let giphy = megaMessage.containsMeta?.giphy else {
            return .zero
        }
        
        return size(for: giphy, maxSize: CGSize(width: maxWidth, height: maxHeight))
    }
    
    private func size(for giphy: MEGAChatGiphy, maxSize: CGSize) -> CGSize {
        var width = giphy.floatWidth
        var height = giphy.floatHeight
        let ratio = giphy.sizeRatio
        
        if ratio > CGFloat(1) {
            width = min(maxSize.width, width)
            height = width / ratio
        } else {
            height = min(maxSize.height, height)
            width = height * ratio
        }

        return CGSize(width: width, height: height)
    }
}

private extension MEGAChatGiphy {
    var floatWidth: CGFloat {
        CGFloat(width)
    }
    
    var floatHeight: CGFloat {
        CGFloat(height)
    }
    
    var sizeRatio: CGFloat {
        floatWidth / floatHeight
    }
}
