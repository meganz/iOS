import MessageKit

class ChatMediaCollectionViewCell: MessageContentCell {

    open var imageView: YYAnimatedImageView = {
        let imageView = YYAnimatedImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        imageView.autoPinEdgesToSuperviewEdges()
    }

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(imageView)
        setupConstraints()
    }
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)
        
        guard let chatMessage = message as? ChatMessage else {
            return
        }

        let megaMessage = chatMessage.message
        let node = megaMessage.nodeList.node(at: 0)!
        
        self.imageView.mnz_setPreview(by: node) { (request) in
            messagesCollectionView.reloadItems(at: [indexPath])
        }
  
    }
}

open class ChatMediaCollectionViewSizeCalculator: MessageSizeCalculator {
   
    let cell = ChatMediaCollectionViewCell()

    public override init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
    }
    
    open override func messageContainerSize(for message: MessageType) -> CGSize {
        switch message.kind {
        case .custom:
            let maxWidth = messageContainerMaxWidth(for: message)
            let maxHeight = UIDevice.current.mnz_maxSideForChatBubble(withMedia: true)
            guard let chatMessage = message as? ChatMessage else {
                return .zero
            }
           
            let megaMessage = chatMessage.message
            let node = megaMessage.nodeList.node(at: 0)!
            let previewFilePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "previewsV3")
         
            if FileManager.default.fileExists(atPath: previewFilePath) {
                let previewImage = YYImage(contentsOfFile: previewFilePath)
                let ratio = previewImage!.size.width / previewImage!.size.height
                var width, height : CGFloat
                if ratio > 1 {
                    width = min(maxWidth, previewImage!.size.width)
                    height = width / ratio
                } else {
                    height = min(maxHeight, previewImage!.size.height)
                    width = height * ratio
                }
            
                return CGSize(width: width, height: height)
            }
            if node.hasPreview() &&
                node.height > 0 &&
                node.width > 0 {
                return CGSize(width: min(node.width, Int(maxWidth)), height: node.height)
            }
            return CGSize(width: 200, height: 200)

        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}
