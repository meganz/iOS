import MessageKit

internal struct ConcreteMessageType: MessageType {
    let sender: SenderType
    let messageId: String
    let sentDate: Date
    var kind: MessageKind
}

class ChatRichPreviewMediaCollectionViewCell: TextMessageCell, MEGARequestDelegate {

    open var richPreviewContentView: RichPreviewContentView = {
        let view = RichPreviewContentView.instanceFromNib
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        MEGASdkManager.sharedMEGASdk()?.add(self)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        MEGASdkManager.sharedMEGASdk()?.add(self)
    }
    
    override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        
        guard let chatMessage = message as? ChatMessage else {
            return
        }
        
        let megaMessage = chatMessage.message
        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content))
        super.configure(with: dummyMssage, at: indexPath, and: messagesCollectionView)

        guard let node = megaMessage.node else {
            
            MEGASdkManager.sharedMEGASdk()?.publicNode(forMegaFileLink: (megaMessage.megaLink as NSURL).mnz_MEGAURL(), delegate: MEGAGetPublicNodeRequestDelegate(completion: { (request, error) in
                messagesCollectionView.reloadItems(at: [indexPath])
            }))
            
            richPreviewContentView.isHidden = true
            return
        }
        richPreviewContentView.isHidden = false
        richPreviewContentView.node = node
        
    }
    
    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(richPreviewContentView)
        setupConstraints()
    }
    
    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        richPreviewContentView.autoPinEdge(toSuperviewEdge: .leading)
        richPreviewContentView.autoPinEdge(toSuperviewEdge: .trailing)
        richPreviewContentView.autoPinEdge(toSuperviewEdge: .bottom)
    }
}



open class ChatRichPreviewMediaCollectionViewSizeCalculator: TextMessageSizeCalculator {
    
    open override func messageContainerSize(for message: MessageType) -> CGSize {
        let maxWidth = messageContainerMaxWidth(for: message)
        guard let chatMessage = message as? ChatMessage else {
            return .zero
        }
        
        let megaMessage = chatMessage.message
        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content))

        let containerSize = super.messageContainerSize(for: dummyMssage)
        
        switch message.kind {
        case .custom:
            if megaMessage.node == nil {
                return containerSize
            }
            
            return CGSize(width: maxWidth, height: containerSize.height + 104)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}

