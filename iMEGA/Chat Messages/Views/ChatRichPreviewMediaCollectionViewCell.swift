import MessageKit

struct ConcreteMessageType: MessageType {
    let sender: SenderType
    let messageId: String
    let sentDate: Date
    var kind: MessageKind
}

extension ConcreteMessageType {
    init(chatMessage: ChatMessage) {
        self.sender = chatMessage.sender
        self.messageId = chatMessage.messageId
        self.sentDate = chatMessage.sentDate
        chatMessage.message.generateAttributedString()
        self.kind = .attributedText(chatMessage.message.attributedText)
    }
}

class ChatRichPreviewMediaCollectionViewCell: TextMessageCell, MEGARequestDelegate {

    open var richPreviewContentView: RichPreviewContentView = {
        let view = RichPreviewContentView.instanceFromNib
        return view
    }()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        MEGASdkManager.sharedMEGASdk().add(self)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        MEGASdkManager.sharedMEGASdk().add(self)
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
                
                MEGASdkManager.sharedMEGASdk().publicNode(forMegaFileLink: megaLink.mnz_MEGAURL(), delegate: MEGAGetPublicNodeRequestDelegate(completion: { (request, error) in
                    let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
                    guard visibleIndexPaths.contains(indexPath), error?.type == .apiOk else {
                        return
                    }
                    megaMessage.richNumber = request?.publicNode.size
                    megaMessage.node = request?.publicNode
                    
                    if self.isLastSectionVisible(collectionView: messagesCollectionView) {
                        messagesCollectionView.reloadDataAndKeepOffset()
                    } else {
                        messagesCollectionView.reloadItems(at: [indexPath])
                    }
                }))
                
                return
            }
            richPreviewContentView.isHidden = false
        case .folderLink:
            if megaMessage.richNumber == nil {
                
                MEGASdkManager.sharedMEGASdk().getPublicLinkInformation(withFolderLink: megaLink.mnz_MEGAURL(), delegate: MEGAGenericRequestDelegate(completion: { (request, error) in
                    let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
                    guard visibleIndexPaths.contains(indexPath), error.type == .apiOk else {
                        return
                    }
                    let totalNumberOfFiles = request.megaFolderInfo.files;
                    let numOfVersionedFiles = request.megaFolderInfo.versions;
                    let totalFileSize = request.megaFolderInfo.currentSize;
                    let versionsSize = request.megaFolderInfo.versionsSize;
                    let sizeWithoutIncludingVersionsSize = totalFileSize - versionsSize
                    
                    megaMessage.richString = NSString.mnz_string(byFiles: totalNumberOfFiles - numOfVersionedFiles, andFolders: request.megaFolderInfo.folders)
                    megaMessage.richNumber = NSNumber(floatLiteral: Double(sizeWithoutIncludingVersionsSize > 0 ? sizeWithoutIncludingVersionsSize : -1))
                    megaMessage.richTitle = request.text
                    
                    if self.isLastSectionVisible(collectionView: messagesCollectionView) {
                        messagesCollectionView.reloadDataAndKeepOffset()
                    } else {
                        messagesCollectionView.reloadItems(at: [indexPath])
                    }
                }))
                return
            }
            richPreviewContentView.isHidden = false
        case .publicChatLink:
            if megaMessage.richNumber == nil {
                
                MEGASdkManager.sharedMEGAChatSdk().checkChatLink(megaMessage.megaLink, delegate: MEGAChatGenericRequestDelegate(completion: { (request, error) in
                    let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
                    guard visibleIndexPaths.contains(indexPath), (error.type == .MEGAChatErrorTypeOk || error.type == .MegaChatErrorTypeExist) else {
                        return
                    }
                    megaMessage.richString = request.text
                    megaMessage.richNumber = NSNumber(floatLiteral: Double(request.number))
                    
                    if self.isLastSectionVisible(collectionView: messagesCollectionView) {
                        messagesCollectionView.reloadDataAndKeepOffset()
                    } else {
                        messagesCollectionView.reloadItems(at: [indexPath])
                    }
                }))
                return
            }
            richPreviewContentView.isHidden = false
            
        default:
            richPreviewContentView.isHidden = true
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
    override public init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init(layout: layout)
        configureAccessoryView()
    }
    
    override open func messageContainerMaxWidth(for message: MessageType) -> CGFloat {
        return min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), super.messageContainerMaxWidth(for: message))
    }

    open override func messageContainerSize(for message: MessageType) -> CGSize {
        guard let chatMessage = message as? ChatMessage else {
            return .zero
        }
        
        let megaMessage = chatMessage.message
        let messageKind: MessageKind = .text(megaMessage.content)
        let dummyMssage = ConcreteMessageType(sender: message.sender,
                                              messageId: message.messageId,
                                              sentDate: message.sentDate,
                                              kind: messageKind)

        let maxWidth = messageContainerMaxWidth(for: dummyMssage)

        let containerSize = super.messageContainerSize(for: dummyMssage)
        switch message.kind {
        case .custom:
            if megaMessage.richNumber == nil && megaMessage.containsMeta?.type != .richPreview {
                return containerSize
            }
            
            let width = max(maxWidth, containerSize.width)
            return CGSize(width: width, height: containerSize.height + 104)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
}

