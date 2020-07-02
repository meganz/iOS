import MessageKit

struct ConcreteMessageType: MessageType {
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
        richPreviewContentView.isHidden = true
        richPreviewContentView.message = megaMessage

        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content))
        super.configure(with: dummyMssage, at: indexPath, and: messagesCollectionView)

        if megaMessage.type == .containsMeta {
            richPreviewContentView.isHidden = false
            return
        }

       
        
        let megaLink = megaMessage.megaLink as NSURL
        switch megaLink.mnz_type() {
        case .fileLink:
            if megaMessage.richNumber == nil {
                
                MEGASdkManager.sharedMEGASdk()?.publicNode(forMegaFileLink: megaLink.mnz_MEGAURL(), delegate: MEGAGetPublicNodeRequestDelegate(completion: { (request, error) in
                    let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
                    guard visibleIndexPaths.contains(indexPath) else {
                        return
                    }
                    
                    messagesCollectionView.reloadItems(at: [indexPath])
                }))
                
                return
            }
            richPreviewContentView.isHidden = false
        case .folderLink:
            if megaMessage.richNumber == nil {
                
                MEGASdkManager.sharedMEGASdk()?.getPublicLinkInformation(withFolderLink: megaLink.mnz_MEGAURL(), delegate: MEGAGenericRequestDelegate(completion: { (request, error) in
                    let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
                    guard visibleIndexPaths.contains(indexPath) else {
                        return
                    }
                    
                    messagesCollectionView.reloadItems(at: [indexPath])
                    
                }))
                return
            }
            richPreviewContentView.isHidden = false
        case .publicChatLink:
            if megaMessage.richNumber == nil {
                
                MEGASdkManager.sharedMEGAChatSdk()?.checkChatLink(megaMessage.megaLink, delegate: MEGAChatGenericRequestDelegate(completion: { (request, error) in
                    let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
                    guard visibleIndexPaths.contains(indexPath) else {
                        return
                    }
                    
                    messagesCollectionView.reloadItems(at: [indexPath])
                    
                }))
                return
            }
            richPreviewContentView.isHidden = false
            
        default:
            break
        }
        
        
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
        guard let chatMessage = message as? ChatMessage else {
            return .zero
        }
        
        let megaMessage = chatMessage.message
        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content))

        let maxWidth = super.messageContainerMaxWidth(for: dummyMssage)

        let containerSize = super.messageContainerSize(for: dummyMssage)
        switch message.kind {
        case .custom:
            if megaMessage.richNumber == nil && megaMessage.containsMeta?.type != .richPreview {
                return containerSize
            }
            
            return CGSize(width: max(maxWidth, containerSize.width), height: containerSize.height + 104)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}

