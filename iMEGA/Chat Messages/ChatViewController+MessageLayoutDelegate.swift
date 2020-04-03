
import MessageKit

extension ChatViewController: MessagesLayoutDelegate {
        
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if let _ = message as? ChatMessage {
            return 0.0
        }
        
        return isDateLabelVisible(for: indexPath) ? 30.0 : 0.0
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if let _ = message as? ChatMessage {
            return 0.0
        }

        return isTimeLabelVisible(at: indexPath) ? 28.0 : 0.0
    }
    
    func headerViewSize(for section: Int, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        if chatRoomDelegate.isFullChatHistoryLoaded && section == 0 {
            let chatMessageHeaderView = ChatViewIntroductionHeaderView.instanceFromNib
            chatMessageHeaderView.chatRoom = chatRoom
            return chatMessageHeaderView.sizeThatFits(
                CGSize(width: messagesCollectionView.bounds.width,
                       height: .greatestFiniteMagnitude)
            )
        }
        
        return .zero
    }
}
