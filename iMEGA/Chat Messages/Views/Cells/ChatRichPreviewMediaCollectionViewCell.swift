import ChatRepo
import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MessageKit

struct ConcreteMessageType: MessageType {
    let sender: any SenderType
    let messageId: String
    let sentDate: Date
    var kind: MessageKind
}

extension ConcreteMessageType {
    init(chatMessage: ChatMessage) {
        self.sender = chatMessage.sender
        self.messageId = chatMessage.messageId
        self.sentDate = chatMessage.sentDate
        chatMessage.message.generateAttributedString(chatMessage.chatRoom.isMeeting)
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
        addListenerAsync()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        addListenerAsync()
    }
    
    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let chatMessage = message as? ChatMessage else {
            return
        }
 
        let megaMessage = chatMessage.message
        richPreviewContentView.isHidden = true
        richPreviewContentView.message = megaMessage
        let senderIsMyself = ChatUseCase(chatRepo: ChatRepository.newRepo).myUserHandle() == UInt64(message.sender.senderId)

        let dummyMessage = ConcreteMessageType(
            sender: message.sender,
            messageId: message.messageId,
            sentDate: message.sentDate,
            kind: .attributedText(
                createAttributedContent(
                    from: megaMessage.content ?? "",
                    senderIsMyself: senderIsMyself
                )
            )
        )
        super.configure(with: dummyMessage, at: indexPath, and: messagesCollectionView)

        if megaMessage.type == .containsMeta {
            richPreviewContentView.isHidden = false
            return
        }
        
        guard let megaLinkURL = megaMessage.megaLink else { return }
        let megaLink = megaLinkURL as NSURL
        switch megaLink.mnz_type() {
        case .fileLink:
            if megaMessage.richNumber == nil {
                
                MEGASdk.shared.publicNode(forMegaFileLink: megaLink.mnz_MEGAURL(), delegate: MEGAGetPublicNodeRequestDelegate(completion: { (request, error) in
                    let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
                    guard visibleIndexPaths.contains(indexPath), error?.type == .apiOk,
                          let publicNode = request?.publicNode else {
                        return
                    }
                    megaMessage.richNumber = publicNode.size
                    megaMessage.node = publicNode
                    
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
                
                MEGASdk.shared.getPublicLinkInformation(withFolderLink: megaLink.mnz_MEGAURL(), delegate: RequestDelegate { result in
                    let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
                    
                    guard visibleIndexPaths.contains(indexPath), case let .success(request) = result else {
                        return
                    }
                    
                    let totalNumberOfFiles = request.megaFolderInfo?.files ?? 0
                    let totalNumberOfFolders = request.megaFolderInfo?.folders ?? 0
                    let numOfVersionedFiles = request.megaFolderInfo?.versions ?? 0
                    let totalFileSize = request.megaFolderInfo?.currentSize ?? 0
                    let versionsSize = request.megaFolderInfo?.versionsSize ?? 0
                    let sizeWithoutIncludingVersionsSize = totalFileSize - versionsSize
                    
                    megaMessage.richString = NSString.mnz_string(byFiles: totalNumberOfFiles - numOfVersionedFiles, andFolders: totalNumberOfFolders)
                    megaMessage.richNumber = NSNumber(floatLiteral: Double(sizeWithoutIncludingVersionsSize > 0 ? sizeWithoutIncludingVersionsSize : -1))
                    megaMessage.richTitle = request.text
                    
                    if self.isLastSectionVisible(collectionView: messagesCollectionView) {
                        messagesCollectionView.reloadDataAndKeepOffset()
                    } else {
                        messagesCollectionView.reloadItems(at: [indexPath])
                    }
                })
                return
            }
            richPreviewContentView.isHidden = false
        case .publicChatLink:
            if megaMessage.richNumber == nil {
                MEGAChatSdk.shared.checkChatLink(megaLinkURL, delegate: ChatRequestDelegate(successCodes: [.MEGAChatErrorTypeOk, .MegaChatErrorTypeExist]) { result in
                    let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
                    guard visibleIndexPaths.contains(indexPath), case let .success(request) = result else {
                        return
                    }
                    megaMessage.richString = request.text
                    megaMessage.richNumber = NSNumber(floatLiteral: Double(request.number))
                    
                    if self.isLastSectionVisible(collectionView: messagesCollectionView) {
                        messagesCollectionView.reloadDataAndKeepOffset()
                    } else {
                        messagesCollectionView.reloadItems(at: [indexPath])
                    }
                })
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
        richPreviewContentView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            richPreviewContentView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor),
            richPreviewContentView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor),
            richPreviewContentView.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor)
        ])
    }
    
    // MARK: - Private
    private func addListenerAsync() {
        Task {
            MEGASdk.shared.add(self)
        }
    }
    
    private func createAttributedContent(from text: String, senderIsMyself: Bool) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.font:
                    UIFont.preferredFont(forTextStyle: .subheadline),
                NSAttributedString.Key.foregroundColor:
                    senderIsMyself ? TokenColors.Text.inverse : TokenColors.Text.primary
            ]
        )
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
    
    open override func messageContainerMaxWidth(for message: any MessageType, at indexPath: IndexPath) -> CGFloat {
       min(UIDevice.current.mnz_maxSideForChatBubble(withMedia: true), super.messageContainerMaxWidth(for: message, at: indexPath))
    }

    open override func messageContainerSize(for message: any MessageType, at indexPath: IndexPath) -> CGSize {
        guard let chatMessage = message as? ChatMessage else {
            return .zero
        }
        
        let megaMessage = chatMessage.message
        let messageKind: MessageKind = .attributedText(createAttributedContent(from: megaMessage.content ?? ""))
        let dummyMessage = ConcreteMessageType(sender: message.sender,
                                              messageId: message.messageId,
                                              sentDate: message.sentDate,
                                              kind: messageKind)

        let maxWidth = messageContainerMaxWidth(for: dummyMessage, at: indexPath)

        let containerSize = super.messageContainerSize(for: dummyMessage, at: indexPath)
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
    
    private func createAttributedContent(from text: String) -> NSAttributedString {
        NSAttributedString(
            string: text,
            attributes: [
                NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .subheadline)
            ]
        )
    }
    
    private func calculatePreviewSize(for chatMessage: ChatMessage) -> CGSize {
        guard chatMessage.message.containsMeta?.type == .richPreview,
                let richPreview = chatMessage.message.containsMeta?.richPreview else {
            return defaultPreviewSize
        }
    
        if let image = richPreview.image,
           Data(base64Encoded: image, options: .ignoreUnknownCharacters) != nil {
            return defaultPreviewSize
        }
        
        if let icon = richPreview.icon,
           Data(base64Encoded: icon, options: .ignoreUnknownCharacters) != nil {
            return defaultPreviewSize
        }
        
        return .zero
    }
    
    private func messageInfo(for chatMessage: ChatMessage) -> (String, String, String) {
        if chatMessage.message.containsMeta?.type == .richPreview {
            guard let richPreview = chatMessage.message.containsMeta?.richPreview else {
                return  ("", "", "")
            }
            return (richPreview.title ?? "", richPreview.previewDescription ?? "", URL(string: richPreview.url ?? "")?.host ?? "")
            
        } else {
            guard let megaLink = chatMessage.message.megaLink else {
                return ("", "", "")
            }
            switch (megaLink as NSURL).mnz_type() {
            case .fileLink:
                return (chatMessage.message.node?.name ?? "",
                        String.memoryStyleString(fromByteCount: Int64(truncating: chatMessage.message.node?.size ?? 0)),
                        DIContainer.appDomainUseCase.domainName)

            case .folderLink:
                return (chatMessage.message.richTitle ?? "",
                        String(format: "%@\n%@", chatMessage.message.richString ?? "", String.memoryStyleString(fromByteCount: max(chatMessage.message.richNumber?.int64Value ?? 0, 0))),
                        DIContainer.appDomainUseCase.domainName)

            case .publicChatLink:
                return (chatMessage.message.richString ?? "",
                        "\(chatMessage.message.richNumber?.int64Value ?? 0) \(Strings.Localizable.participants)",
                        DIContainer.appDomainUseCase.domainName)

            default:
                return ("", "", "")
            }
        }
    }
}
