import MessageKit

class ChatViewMessagesFlowLayout: MessagesCollectionViewFlowLayout {
    lazy var chatViewCallCollectionCellCalculator = ChatViewCallCollectionCellCalculator(layout: self)
    lazy var chatViewAttachmentCellCalculator = ChatViewAttachmentCellCalculator(layout: self)
    lazy var chatMediaCollectionViewSizeCalculator = ChatMediaCollectionViewSizeCalculator(layout: self)
    lazy var chatRichPreviewMediaCollectionViewSizeCalculator = ChatRichPreviewMediaCollectionViewSizeCalculator(layout: self)
    lazy var chatVoiceClipCollectionViewSizeCalculator = ChatVoiceClipCollectionViewSizeCalculator(layout: self)
    lazy var chatlocationCollectionViewSizeCalculator = ChatlocationCollectionViewSizeCalculator(layout: self)
    lazy var chatManagmentTypeCollectionViewSizeCalculator = ChatManagmentTypeCollectionViewSizeCalculator(layout: self)
  
    
    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath)
    }
    
    
    override func cellSizeCalculatorForItem(at indexPath: IndexPath) -> CellSizeCalculator {
        if isSectionReservedForTypingIndicator(indexPath.section) {
            return typingIndicatorSizeCalculator
        }
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)

        if case .custom = message.kind {
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
                return super.cellSizeCalculatorForItem(at: indexPath)
            }
        }
        return super.cellSizeCalculatorForItem(at: indexPath)
    }
    
    override func messageSizeCalculators() -> [MessageSizeCalculator] {
        var calculators = super.messageSizeCalculators()
        calculators.append(contentsOf: [
            chatViewAttachmentCellCalculator,
            chatViewCallCollectionCellCalculator,
            chatMediaCollectionViewSizeCalculator,
            chatRichPreviewMediaCollectionViewSizeCalculator,
            chatVoiceClipCollectionViewSizeCalculator,
            chatlocationCollectionViewSizeCalculator,
            chatManagmentTypeCollectionViewSizeCalculator
        ])
        return calculators
    }
}
