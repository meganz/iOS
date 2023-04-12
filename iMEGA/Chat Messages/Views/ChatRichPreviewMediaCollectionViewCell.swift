import MessageKit
import Foundation

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
        self.kind = .attributedText(chatMessage.message.attributedText ?? NSAttributedString(string: ""))
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

        let dummyMssage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content ?? ""))
        super.configure(with: dummyMssage, at: indexPath, and: messagesCollectionView)

        if megaMessage.type == .containsMeta {
            richPreviewContentView.isHidden = false
            return
        }
        
        guard let megaLinkURL = megaMessage.megaLink else { return }
        let megaLink = megaLinkURL as NSURL
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
                
                MEGASdkManager.sharedMEGAChatSdk().checkChatLink(megaLinkURL, delegate: MEGAChatGenericRequestDelegate(completion: { (request, error) in
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
    
    let chatRichPreviewMediaCollectionViewCell = ChatRichPreviewMediaCollectionViewCell()
    let defaultPreviewSize: CGSize = CGSize(width: 100.0, height: 104.0)
    let elementSpacing: CGFloat = 10.0
    
    lazy var calculateTitleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 1
        return titleLabel
    }()
    
    lazy var calculateDescriptionLabel: UILabel = {
        let descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 2
        return descriptionLabel
    }()
    
    lazy var calculateLinkLabel: UILabel = {
        let linkLabel = UILabel()
        linkLabel.numberOfLines = 1
        return linkLabel
    }()
    
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
        let messageKind: MessageKind = .text(megaMessage.content ?? "")
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
            
            let messageInfo = messageInfo(for: chatMessage)
            calculateTitleLabel.text = messageInfo.0
            calculateTitleLabel.font = UIFont.preferredFont(style: .subheadline, weight: .medium)
            calculateDescriptionLabel.text = messageInfo.1
            calculateDescriptionLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            calculateLinkLabel.text = messageInfo.2
            calculateLinkLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            
            let maxWidth = max(maxWidth, containerSize.width)
            let maxSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
            let previewSize = calculatePreviewSize(for: chatMessage)
            let labelsContainerSize = CGSize(width: maxSize.width - elementSpacing - previewSize.width - elementSpacing, height: maxSize.height)
            let titleLabelSize = calculateTitleLabel.sizeThatFits(labelsContainerSize)
            let descriptionLabelSize = calculateDescriptionLabel.sizeThatFits(labelsContainerSize)
            let linkLabelSize = calculateTitleLabel.sizeThatFits(CGSize(width: labelsContainerSize.width - 2 * elementSpacing, height: labelsContainerSize.height))
            
            return CGSize(width: maxSize.width,
                          height: containerSize.height
                                    + max(defaultPreviewSize.height,
                                          elementSpacing
                                          + titleLabelSize.height
                                          + elementSpacing
                                          + descriptionLabelSize.height
                                          + elementSpacing
                                          + linkLabelSize.height)
                                          + elementSpacing)
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
    
    private func calculatePreviewSize(for chatMessage: ChatMessage) -> CGSize {
        guard chatMessage.message.containsMeta?.type == .richPreview,
                let richPreview = chatMessage.message.containsMeta?.richPreview else {
            return defaultPreviewSize
        }
    
        if richPreview.image != nil,
           Data(base64Encoded: richPreview.image, options: .ignoreUnknownCharacters) != nil {
            return defaultPreviewSize
        }
        
        if richPreview.icon != nil,
           Data(base64Encoded: richPreview.icon, options: .ignoreUnknownCharacters) != nil {
            return defaultPreviewSize
        }
        
        return .zero
    }
    
    private func messageInfo(for chatMessage: ChatMessage) -> (String, String, String) {
        if chatMessage.message.containsMeta?.type == .richPreview {
            guard let richPreview = chatMessage.message.containsMeta?.richPreview else {
                return  ("", "", "")
            }
            return (richPreview.title, richPreview.previewDescription, URL(string: richPreview.url)?.host ?? "")
            
        } else {
            guard let megaLink = chatMessage.message.megaLink else {
                return ("", "", "")
            }
            switch (megaLink as NSURL).mnz_type() {
            case .fileLink:
                return (chatMessage.message.node?.name ?? "",
                        String.memoryStyleString(fromByteCount: Int64(truncating: chatMessage.message.node?.size ?? 0)),
                        "mega.nz")
                
            case .folderLink:
                return (chatMessage.message.richTitle ?? "",
                        String(format: "%@\n%@", chatMessage.message.richString ?? "", String.memoryStyleString(fromByteCount: max(chatMessage.message.richNumber?.int64Value ?? 0, 0))),
                        "mega.nz")
                
            case .publicChatLink:
                return (chatMessage.message.richString ?? "",
                        "\(chatMessage.message.richNumber?.int64Value ?? 0) \(Strings.Localizable.participants)",
                        "mega.nz")
                
            default:
                return ("", "", "")
            }
        }
    }
}
