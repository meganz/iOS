import MEGADomain
import MEGASDKRepo
import MEGASwift
import MessageKit
import UIKit

class ContactLinkCollectionViewCell: TextMessageCell {
    open var contactLinkContentView: ContactLinkContentView = {
        let view = ContactLinkContentView.instanceFromNib
        return view
    }()
    
    override func configure(with message: any MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        guard let chatMessage = message as? ChatMessage else {
            return
        }
        
        let megaMessage = chatMessage.message
        contactLinkContentView.message = megaMessage
        
        let dummyMessage = ConcreteMessageType(sender: message.sender, messageId: message.messageId, sentDate: message.sentDate, kind: .text(megaMessage.content ?? ""))
        super.configure(with: dummyMessage, at: indexPath, and: messagesCollectionView)
        
        guard megaMessage.richString == nil,
              let path = megaMessage.megaLink?.absoluteString,
              let rangeOfPrefix = path.endIndex(of: DeeplinkFragmentKey.contact.rawValue),
              let handle = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo).handle(forBase64Handle: String(path[rangeOfPrefix...])) else {
            return
        }
        
        contactLinkContentView.showLoading()
        Task { [weak self] in
            guard let self else { return }
            let contactLinkUC = ContactLinkUseCase(repo: ContactLinkRepository.newRepo)
            guard let contactEntity = try await contactLinkUC.contactLinkQuery(handle: handle) else {
                contactLinkContentView.hideLoading()
                return
            }
            
            self.contactLinkContentView.hideLoading()
            
            let visibleIndexPaths = messagesCollectionView.indexPathsForVisibleItems
            guard visibleIndexPaths.contains(indexPath) else {
                return
            }
            
            megaMessage.richTitle = contactEntity.name
            megaMessage.richString = contactEntity.email
            megaMessage.contactLinkUserHandle = contactEntity.userHandle ?? .invalidHandle
            
            if self.isLastSectionVisible(collectionView: messagesCollectionView) {
               messagesCollectionView.reloadDataAndKeepOffset()
            } else {
                messagesCollectionView.reloadItems(at: [indexPath])
            }
        }
    }
    
    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(contactLinkContentView)
        setupConstraints()
    }
    
    // MARK: - Methods

    /// Responsible for setting up the constraints of the cell's subviews.
    open func setupConstraints() {
        contactLinkContentView.translatesAutoresizingMaskIntoConstraints = false
        contactLinkContentView.leadingAnchor.constraint(equalTo: messageContainerView.leadingAnchor).isActive = true
        contactLinkContentView.trailingAnchor.constraint(equalTo: messageContainerView.trailingAnchor).isActive = true
        contactLinkContentView.bottomAnchor.constraint(equalTo: messageContainerView.bottomAnchor).isActive = true
    }
}

open class ChatContactLinkCollectionViewSizeCalculator: TextMessageSizeCalculator {
    
    let chatRichPreviewMediaCollectionViewCell = ChatRichPreviewMediaCollectionViewCell()
    let defaultPreviewSize: CGSize = CGSize(width: 60.0, height: 60.0)
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
        let messageKind: MessageKind = .text(megaMessage.content ?? "")
        let dummyMessage = ConcreteMessageType(sender: message.sender,
                                              messageId: message.messageId,
                                              sentDate: message.sentDate,
                                              kind: messageKind)

        let maxWidth = messageContainerMaxWidth(for: dummyMessage, at: indexPath)

        let containerSize = super.messageContainerSize(for: dummyMessage, at: indexPath)
        switch message.kind {
        case .custom:
            let messageInfo = messageInfo(for: chatMessage)
            calculateTitleLabel.text = messageInfo.title
            calculateTitleLabel.font = UIFont.preferredFont(style: .subheadline, weight: .medium)
            calculateDescriptionLabel.text = messageInfo.description
            calculateDescriptionLabel.font = UIFont.preferredFont(forTextStyle: .caption1)
            
            let maxWidth = max(maxWidth, containerSize.width)
            let maxSize = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
            let previewSize = calculatePreviewSize(for: chatMessage)
            let labelsContainerSize = CGSize(width: maxSize.width - elementSpacing - previewSize.width - elementSpacing, height: maxSize.height)
            let titleLabelSize = calculateTitleLabel.sizeThatFits(labelsContainerSize)
            let descriptionLabelSize = calculateDescriptionLabel.sizeThatFits(labelsContainerSize)
            
            return CGSize(width: maxSize.width,
                          height: containerSize.height
                                    + max(defaultPreviewSize.height,
                                          elementSpacing
                                          + titleLabelSize.height
                                          + elementSpacing
                                          + descriptionLabelSize.height
                                          + elementSpacing))
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
    }
    
    private func calculatePreviewSize(for chatMessage: ChatMessage) -> CGSize {
        CGSize(width: 60.0, height: 60.0)
    }
    
    private func messageInfo(for chatMessage: ChatMessage) -> (title: String, description: String) {
        (chatMessage.message.richTitle ?? "", chatMessage.message.richString ?? "")
    }
}
