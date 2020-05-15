import MessageKit

extension ChatViewController: ChatViewMessagesLayoutDelegate {
    func collectionView(_ collectionView: MessagesCollectionView, layout collectionViewLayout: MessagesCollectionViewFlowLayout, editingOffsetForCellAt indexPath: IndexPath) -> CGFloat {
        let message = messages[indexPath.section]

        guard !message.message.isManagementMessage else {
            return 0
        }
        
        return isFromCurrentSender(message: message) ? 0 : 50
    }
    
    func collectionView(_ collectionView: MessagesCollectionView, editingOverlayAt indexPath: IndexPath, become selected: Bool) {
        if selected {
            selectedEditingIndexPaths.insert(indexPath)
        } else {
            selectedEditingIndexPaths.remove(indexPath)
        }
    }
    
    func collectionView(_ collectionView: MessagesCollectionView, layout collectionViewLayout: MessagesCollectionViewFlowLayout, shouldEditItemAt indexPath: IndexPath) -> Bool {
        let message = messages[indexPath.section]
        return !message.message.isManagementMessage
             
    }
    


    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return isDateLabelVisible(for: indexPath) ? 30.0 : 0.0
    }

    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
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
