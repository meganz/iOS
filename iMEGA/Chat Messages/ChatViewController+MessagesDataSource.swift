import MEGADesignToken
import MEGAL10n
import MessageKit

extension ChatViewController: MessagesDataSource {
    public func currentSender() -> any SenderType {
        return myUser
    }
    
    public func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    public func messageForItem(at indexPath: IndexPath,
                               in messagesCollectionView: MessagesCollectionView) -> any MessageType {
        return messages[safe: indexPath.section] ?? ConcreteMessageType(sender: User(senderId: "", displayName: ""), messageId: "", sentDate: Date(), kind: .text(""))
    }
    
    func messageTopLabelAttributedText(for message: any MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        guard let message = messages[safe: indexPath.section],
              let chatMessage = message as? ChatMessage else {
            return nil
        }
        
        if isTimeLabelVisible(at: indexPath) {
            let dateString = chatMessage.sentDate.string(withDateFormat: "HH:mm")
            let displayName = if !isFromCurrentSender(message: chatMessage) && chatRoom.isGroup {
                !chatMessage.message.isManagementMessage ? "\(chatMessage.displayName) " : ""
            } else {
                ""
            }
            let fullText = "\(displayName)\(dateString)"
            
            let attributedString = NSMutableAttributedString(
                string: fullText,
                attributes: [
                    NSAttributedString.Key.font: UIFont.preferredFont(style: .caption1, weight: .bold)
                ]
            )
            
            let dateRange = (fullText as NSString).range(of: dateString)
            attributedString.addAttribute(.foregroundColor, value: TokenColors.Text.secondary, range: dateRange)
            
            if !displayName.isEmpty {
                let displayNameRange = (fullText as NSString).range(of: displayName)
                attributedString.addAttribute(.foregroundColor, value: TokenColors.Text.primary, range: displayNameRange)
            }
            
            return attributedString
        }
        
        return nil
    }
    
    func cellTopLabelAttributedText(for message: any MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isDateLabelVisible(for: indexPath) {
            return NSAttributedString(
                string: NSCalendar.current.isDateInToday(message.sentDate) ? Strings.Localizable.today : message.sentDate.string(withDateFormat: "E dd MMM"),
                attributes: [
                    NSAttributedString.Key.font: UIFont.preferredFont(style: .subheadline, weight: .bold),
                    NSAttributedString.Key.foregroundColor: TokenColors.Text.primary
                ]
            )
        }
        
        return nil
    }
    
    func messageHeaderView(for indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageReusableView {
        
        guard MEGAChatSdk.shared.isFullHistoryLoaded(forChat: chatRoom.chatId) else {
            let loadingMessagesHeaderView = messagesCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: LoadingMessageReusableView.reuseIdentifier, for: indexPath)  as! LoadingMessageReusableView
            loadingMessagesHeaderView.loadingView.mnz_startShimmering()
            return loadingMessagesHeaderView
        }
        
        let chatMessageHeaderView = messagesCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: ChatViewIntroductionHeaderView.reuseIdentifier, for: indexPath) as! ChatViewIntroductionHeaderView
        chatMessageHeaderView.chatRoom = chatRoom
        return chatMessageHeaderView
    }
    
    func messageFooterView(for indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageReusableView {
        guard let chatMessageReactionView = messagesCollectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: MessageReactionReusableView.reuseIdentifier, for: indexPath) as? MessageReactionReusableView else {
            fatalError("Failed to dequeue MessageReactionReusableView")
        }
        
        if let chatMessage = messages[indexPath.section] as? ChatMessage {
            chatMessageReactionView.chatMessage = chatMessage
            chatMessageReactionView.indexPath = indexPath
        }
        
        chatMessageReactionView.delegate = self
        return chatMessageReactionView
    }
    
    func messageBottomLabelAttributedText(for message: any MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        guard let message = message as? ChatMessage, let transfer = message.transfer, transfer.state == .failed else {
            return nil
        }
        
        let bottomLabelString = Strings.Localizable.CouldnTLoad.redTapToRetryRED
        guard let title = (bottomLabelString as NSString).mnz_stringBetweenString("[RED]", andString: "[/RED]") else {
            return nil
        }
        let description = (bottomLabelString as NSString).replacingOccurrences(of: String(format: "[RED]%@[/RED]", title), with: "")
        let titleAttributes = [
            NSAttributedString.Key.foregroundColor: TokenColors.Text.error,
            NSAttributedString.Key.font: UIFont.preferredFont(style: .caption2, weight: .medium)
        ]
        let titleAttributedString = NSMutableAttributedString(string: title, attributes: titleAttributes)
        
        let descriptionAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor.mnz_primaryGray(),
            NSAttributedString.Key.font: UIFont.preferredFont(style: .caption2, weight: .medium)
        ]
        let descriptionAttributedString = NSMutableAttributedString(string: description, attributes: descriptionAttributes)
        
        descriptionAttributedString.append(titleAttributedString)
        
        return descriptionAttributedString
    }
}

extension ChatViewController: MessageReactionReusableViewDelegate {
    func addMorePressed(chatMessage: ChatMessage, sender: UIView) {
        guard chatRoom.canAddReactions else {
            return
        }
        
        let vc = ReactionPickerViewController()
        
        vc.message = chatMessage
        dismissKeyboardIfRequired()
        presentPanModal(vc, sourceView: sender, sourceRect: sender.bounds)
    }
    
    func emojiLongPressed(_ emoji: String, chatMessage: ChatMessage, sender: UIView) {
        guard chatRoom.canAddReactions else {
            return
        }
        guard let emojisStringList = MEGAChatSdk.shared.messageReactions(forChat: chatRoom.chatId,
                                                                         messageId: chatMessage.message.messageId) else {
            MEGALogDebug("Could not fetch the emoji list for a message")
            return
        }
        
        let emojis = (0..<emojisStringList.size).compactMap { emojisStringList.string(at: $0) }
        let vc = ReactedEmojisUsersListViewController(delegate: self,
                                                      emojiList: emojis,
                                                      selectedEmoji: emoji,
                                                      chatRoom: chatRoom,
                                                      messageId: chatMessage.message.messageId)
        
        dismissKeyboardIfRequired()
        presentPanModal(vc, sourceView: sender, sourceRect: sender.bounds)
    }
}

extension ChatViewController: ReactedEmojisUsersListViewControllerDelegate {
    
    func didSelectUserhandle(_ userhandle: UInt64) {
        pushContactDetailsViewController(withPeerHandle: userhandle)
    }
}
