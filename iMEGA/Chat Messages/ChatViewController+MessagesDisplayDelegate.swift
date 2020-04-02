
import MessageKit

extension ChatViewController: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType,
                         at indexPath: IndexPath,
                         in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(fromHexString: "#009476") : UIColor(fromHexString: "#EEEEEE")
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .black
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return .custom { containerView in
            containerView.layer.cornerRadius = 13.0
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView,
                             for message: MessageType,
                             at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) {
        avatarView.isHidden = isFromCurrentSender(message: message)
        
        let chatInitials = initials(for: message)
        let avatar = Avatar(image: avatarImage(for: message), initials: chatInitials)
        avatarView.set(avatar: avatar)
    }
}
