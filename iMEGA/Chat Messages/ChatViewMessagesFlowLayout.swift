import MessageKit

public protocol ChatViewMessagesLayoutDelegate: MessagesLayoutDelegate {
    func collectionView(_ collectionView: MessagesCollectionView, layout collectionViewLayout: MessagesCollectionViewFlowLayout, shouldEditItemAt indexPath: IndexPath) -> Bool
    
    func collectionView(_ collectionView: MessagesCollectionView, layout collectionViewLayout: MessagesCollectionViewFlowLayout, editingOffsetForCellAt indexPath: IndexPath) -> CGFloat
    
//    func collectionView(_ collectionView: MessagesCollectionView, editingOverlayAt indexPath: IndexPath, become selected:Bool)
    
}

class ChatViewMessagesFlowLayout: MessagesCollectionViewFlowLayout {
    lazy var chatViewCallCollectionCellCalculator = ChatViewCallCollectionCellCalculator(layout: self)
    lazy var chatViewAttachmentCellCalculator = ChatViewAttachmentCellCalculator(layout: self)
    lazy var chatMediaCollectionViewSizeCalculator = ChatMediaCollectionViewSizeCalculator(layout: self)
    lazy var chatRichPreviewMediaCollectionViewSizeCalculator = ChatRichPreviewMediaCollectionViewSizeCalculator(layout: self)
    lazy var chatVoiceClipCollectionViewSizeCalculator = ChatVoiceClipCollectionViewSizeCalculator(layout: self)
    lazy var chatlocationCollectionViewSizeCalculator = ChatlocationCollectionViewSizeCalculator(layout: self)
    lazy var chatManagmentTypeCollectionViewSizeCalculator = ChatManagmentTypeCollectionViewSizeCalculator(layout: self)
    lazy var chatAttributedTextMessageSizeCalculator  = ChatTextMessageSizeCalculator(layout: self)
    lazy var chatUnreadMessagesLabelCollectionCellSizeCalculator = ChatUnreadMessagesLabelCollectionCellSizeCalculator(layout: self)
  
    var editing = false {
        didSet {
            invalidateLayout()
        }
    }
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        guard let attributesArray = super.layoutAttributesForElements(in: rect), editing, let chatLayoutDelegate = messagesCollectionView.messagesLayoutDelegate as? ChatViewMessagesLayoutDelegate else {
            return super.layoutAttributesForElements(in: rect)
        }
        
        
        var editingAttributesinRect: [UICollectionViewLayoutAttributes] = [UICollectionViewLayoutAttributes]()
        
        for attributes in attributesArray where attributes.representedElementCategory == .cell {
            if chatLayoutDelegate.collectionView(messagesCollectionView, layout: self, shouldEditItemAt: attributes.indexPath) {
                configureMessageCellLayoutAttributes(attributes)
                editingAttributesinRect.append(createEditingOverlayAttributesForCellAttributes(attributes))
            }
            
        }
        
        if(editingAttributesinRect.count > 0) {
            return attributesArray + editingAttributesinRect
        } else {
            return attributesArray
        }

    }
    
    func configureMessageCellLayoutAttributes(_ layoutAttributes : UICollectionViewLayoutAttributes) {
        guard let chatLayoutDelegate = messagesCollectionView.messagesLayoutDelegate as? ChatViewMessagesLayoutDelegate, chatLayoutDelegate.collectionView(messagesCollectionView, layout: self, shouldEditItemAt: layoutAttributes.indexPath) else {
            return
        }

        let offset = chatLayoutDelegate.collectionView(messagesCollectionView, layout: self, editingOffsetForCellAt: layoutAttributes.indexPath)
        layoutAttributes.frame = layoutAttributes.frame.offsetBy(dx:offset, dy: 0)

    }
    
    func createEditingOverlayAttributesForCellAttributes(_ layoutAttributes : UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        
        let attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: "kCollectionElementKindEditOverlay", with: layoutAttributes.indexPath)
        attributes.zIndex = layoutAttributes.zIndex + 1
        
        let dataSource = messagesDataSource
        
        if !messagesCollectionView.isTypingIndicatorHidden && (layoutAttributes.indexPath.section == dataSource.numberOfSections(in: messagesCollectionView)) {
            attributes.frame = layoutAttributes.frame.offsetBy(dx:-50, dy: 0)
            return attributes
        }
        let message = dataSource.messageForItem(at: layoutAttributes.indexPath, in: messagesCollectionView)
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        attributes.frame = layoutAttributes.frame.offsetBy(dx:isFromCurrentSender ? 0 : -50, dy: 0)

        return attributes
    }
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        switch elementKind {
        case "kCollectionElementKindEditOverlay":
            guard let itemAttributes = layoutAttributesForItem(at: indexPath) else {
                return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
            }
            return createEditingOverlayAttributesForCellAttributes(itemAttributes)
            
        default:
            break
        }
        return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
    }
    
    
    override func cellSizeCalculatorForItem(at indexPath: IndexPath) -> CellSizeCalculator {
        if isSectionReservedForTypingIndicator(indexPath.section) {
            return typingIndicatorSizeCalculator
        }
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)

        if case .custom = message.kind {
            if message is ChatNotificationMessage {
                return chatUnreadMessagesLabelCollectionCellSizeCalculator
            }
            
            guard let chatMessage = message as? ChatMessage else {
                return super.cellSizeCalculatorForItem(at: indexPath)
            }
            
            switch chatMessage.message.type {
            case .attachment, .contact:
                if (chatMessage.message.nodeList?.size?.intValue ?? 0 == 1) {
                    let node = chatMessage.message.nodeList.node(at: 0)!
                    if (node.name!.mnz_isImagePathExtension || node.name!.mnz_isVideoPathExtension) {
                        return chatMediaCollectionViewSizeCalculator
                    }
                }
                return chatViewAttachmentCellCalculator

            case .callEnded, .callStarted:
                return chatViewCallCollectionCellCalculator
            case .normal:
                if chatMessage.message.containsMEGALink() {
                    return chatRichPreviewMediaCollectionViewSizeCalculator
                } else {
                    return chatAttributedTextMessageSizeCalculator
                }
            case .voiceClip:
                return chatVoiceClipCollectionViewSizeCalculator
            case .containsMeta:
                if chatMessage.message.containsMeta.type == .geolocation {
                    return chatlocationCollectionViewSizeCalculator
                } else {
                    return chatRichPreviewMediaCollectionViewSizeCalculator
                }
            default:
                if chatMessage.message.isManagementMessage {
                    return chatManagmentTypeCollectionViewSizeCalculator
                }
                if chatMessage.transfer?.transferChatMessageType() == .voiceClip {
                    return chatVoiceClipCollectionViewSizeCalculator
                }
                if chatMessage.transfer?.transferChatMessageType() == .attachment {
                    return chatMediaCollectionViewSizeCalculator
                }
                
                return super.cellSizeCalculatorForItem(at: indexPath)
            }
        }
        return super.cellSizeCalculatorForItem(at: indexPath)
    }
    
    override func messageSizeCalculators() -> [MessageSizeCalculator] {
        var calculators = super.messageSizeCalculators()
        calculators.append(contentsOf: [
            chatAttributedTextMessageSizeCalculator,
            chatViewAttachmentCellCalculator,
            chatMediaCollectionViewSizeCalculator,
            chatRichPreviewMediaCollectionViewSizeCalculator,
            chatVoiceClipCollectionViewSizeCalculator,
            chatlocationCollectionViewSizeCalculator,
            chatManagmentTypeCollectionViewSizeCalculator
        ])
        return calculators
    }
    
}
