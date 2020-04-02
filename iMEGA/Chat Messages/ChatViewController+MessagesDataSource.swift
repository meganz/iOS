
import MessageKit

extension ChatViewController: MessagesDataSource {
    
    public func currentSender() -> SenderType {
        return myUser
    }
    
    public func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    public func messageForItem(at indexPath: IndexPath,
                               in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            return NSAttributedString(
                string: message.sentDate.string(withDateFormat: "hh:mm") ,
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: .medium),
                             NSAttributedString.Key.foregroundColor: UIColor(fromHexString: "#848484") ?? .black])
        }
        return nil
    }
    
    func messageHeaderView(for indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageReusableView {
        let chatMessageHeaderView = messagesCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ChatMessageIntroductionHeaderView.reuseIdentifier, for: indexPath) as! ChatMessageIntroductionHeaderView
        chatMessageHeaderView.chatRoom = chatRoom
        return chatMessageHeaderView
    }
}
