
import MessageKit

class ChatViewMessagesFlowLayout: MessagesCollectionViewFlowLayout {
    lazy var chatViewCallCollectionCellCalculator = ChatViewCallCollectionCellCalculator(layout: self)

    override func cellSizeCalculatorForItem(at indexPath: IndexPath) -> CellSizeCalculator {
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        
        if case .custom = message.kind {
            return chatViewCallCollectionCellCalculator
        }
        
        return super.cellSizeCalculatorForItem(at: indexPath)
    }
}
