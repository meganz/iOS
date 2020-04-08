import MessageKit

class ChatViewMessagesFlowLayout: MessagesCollectionViewFlowLayout {
    lazy var chatViewCallCollectionCellCalculator = ChatViewCallCollectionCellCalculator(layout: self)
    lazy var chatViewAttachmentCellCalculator = ChatViewAttachmentCellCalculator(layout: self)
    lazy var customContactMessageSizeCalculator = CustomContactMessageSizeCalculator(layout: self)

    override func cellSizeCalculatorForItem(at indexPath: IndexPath) -> CellSizeCalculator {
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)

        if case .custom = message.kind {
            guard let chatMessage = message as? ChatMessage else {
                return super.cellSizeCalculatorForItem(at: indexPath)
            }

            switch chatMessage.message.type {
            case .attachment:
                return chatViewAttachmentCellCalculator
            case .callEnded, .callStarted:
                return chatViewCallCollectionCellCalculator
            case .contact:
                return customContactMessageSizeCalculator
            default:
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
            customContactMessageSizeCalculator
        ])
        return calculators
    }
}
