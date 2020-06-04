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
            var topLabelString: String = message.sentDate.string(withDateFormat: "hh:mm")
            
            if !isFromCurrentSender(message: messages[indexPath.section]) && chatRoom.isGroup {
                let message = messages[indexPath.section]
                topLabelString = message.displayName + " " + topLabelString
            }
            
            return NSAttributedString(
                string: topLabelString,
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13.0, weight: .medium),
                             NSAttributedString.Key.foregroundColor: UIColor(fromHexString: "#848484") ?? .black])
        }
        return nil
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isDateLabelVisible(for: indexPath) {
            return NSAttributedString(
                string: message.sentDate.string(withDateFormat: "E dd MMM") ,
                attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15.0, weight: .bold),
                             NSAttributedString.Key.foregroundColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)])

        }

        return nil
    }
    
    func messageHeaderView(for indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageReusableView {
        
        guard MEGASdkManager.sharedMEGAChatSdk()?.isFullHistoryLoaded(forChat: chatRoom.chatId) ?? false else {
            let loadingMessagesHeaderView = messagesCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: LoadingMessageReusableView.reuseIdentifier, for: indexPath)  as! LoadingMessageReusableView
            loadingMessagesHeaderView.loadingView.mnz_startShimmering()
            return loadingMessagesHeaderView
        }
        
        let chatMessageHeaderView = messagesCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ChatViewIntroductionHeaderView.reuseIdentifier, for: indexPath) as! ChatViewIntroductionHeaderView
        chatMessageHeaderView.chatRoom = chatRoom
        return chatMessageHeaderView
    }
}
