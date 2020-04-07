import MessageKit

extension ChatViewController: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType,
                         at indexPath: IndexPath,
                         in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let chatMessage = message as! ChatMessage
        switch chatMessage.message.type {
        case .contact:
            return .clear
        default:
            return isFromCurrentSender(message: message) ? UIColor(fromHexString: "#009476") : UIColor(fromHexString: "#EEEEEE")

        }
    }

    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .black
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return .custom { containerView in
            containerView.layer.cornerRadius = 13.0
            containerView.layer.borderColor = self.isFromCurrentSender(message: message) ?  #colorLiteral(red: 0, green: 0.5803921569, blue: 0.462745098, alpha: 1).cgColor :  #colorLiteral(red: 0.8941176471, green: 0.9215686275, blue: 0.9176470588, alpha: 1).cgColor
            containerView.layer.borderWidth = 1
        }
    }

    func configureAvatarView(_ avatarView: AvatarView,
                             for message: MessageType,
                             at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) {
        if !isFromCurrentSender(message: message) {
            let chatInitials = initials(for: message)
            let avatar = Avatar(image: avatarImage(for: message), initials: chatInitials)
            avatarView.set(avatar: avatar)
            avatarView.isHidden = isFromCurrentSender(message: message)
        }
    }
}
