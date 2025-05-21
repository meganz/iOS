import MEGAAssets
import MEGADesignToken
import MessageKit

extension ChatViewController: MessagesDisplayDelegate {
    
    private var containerViewBorderColor: CGColor {
        MEGAAssets.UIColor.grayE4EBEA.withAlphaComponent(0).cgColor
    }
    
    func backgroundColor(for message: any MessageType,
                         at indexPath: IndexPath,
                         in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        guard let chatMessage = messageForItem(at: indexPath, in: messagesCollectionView) as? ChatMessage else {
            return chatBubbleBackgroundColor(for: message)
        }
        
        if chatMessage.message.isManagementMessage {
            return .clear
        }
        
        if chatMessage.transfer?.transferChatMessageType() == .attachment {
            return chatBubbleBackgroundColor(for: message)
        }
        
        switch chatMessage.message.type {
        case .contact, .attachment:
            return chatBubbleBackgroundColor(for: message)
        case .normal:
            if ((chatMessage.message.content ?? "") as NSString).mnz_isPureEmojiString() {
                return .clear
            }
            return chatBubbleBackgroundColor(for: message)
            
        default:
            return chatBubbleBackgroundColor(for: message)
            
        }
    }
    
    func textColor(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return senderIsMyself(message: message) ? TokenColors.Text.inverse : TokenColors.Text.primary
    }
    
    func messageStyle(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return .custom { [weak self] containerView in
            guard let `self` = self else {
                return
            }
            
            guard let chatMessage = self.messageForItem(at: indexPath, in: messagesCollectionView) as? ChatMessage else {
                return
            }
            containerView.layer.cornerRadius = 13.0
            
            let boraderColor = chatBubbleBackgroundColor(for: message)
            containerView.layer.borderColor = boraderColor.cgColor
            containerView.layer.borderWidth = 1
            
            if chatMessage.message.status == .sending || chatMessage.message.status == .sendingManual, chatMessage.transfer?.transferChatMessageType() != .voiceClip {
                containerView.alpha = 0.7
            } else {
                containerView.alpha = 1
            }
            
            if chatMessage.message.isManagementMessage {
                containerView.layer.borderColor = containerViewBorderColor
                return
            }
            
            if chatMessage.message.type == .normal && ((chatMessage.message.content ?? "") as NSString).mnz_isPureEmojiString() {
                containerView.layer.borderColor = containerViewBorderColor
            }
            
            if chatMessage.transfer?.transferChatMessageType() == .attachment {
                containerView.layer.borderColor = containerViewBorderColor
            }
            
            if chatMessage.message.type == .attachment && (chatMessage.message.nodeList?.size ?? 0 == 1) {
                if let node = chatMessage.message.nodeList?.node(at: 0),
                   let nodeName = node.name,
                   nodeName.fileExtensionGroup.isVisualMedia {
                    containerView.layer.borderColor = containerViewBorderColor
                }
            }
            
            if chatMessage.message.type == .containsMeta,
               chatMessage.message.containsMeta?.type == .giphy {
                containerView.layer.borderColor = containerViewBorderColor
            }
            
        }
    }
    
    func configureAccessoryView(_ accessoryView: UIView, for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        // Cells are reused, so only add a button here once. For real use you would need to
        // ensure any subviews are removed if not needed
        accessoryView.subviews.forEach { $0.removeFromSuperview() }
        accessoryView.backgroundColor = .clear
        guard let chatMessage = self.messageForItem(at: indexPath, in: messagesCollectionView) as? ChatMessage, shouldShowAccessoryView(for: chatMessage), !isEditing else {
            accessoryView.isHidden = true
            return
        }
        accessoryView.isHidden = false
        let button = UIButton()
        accessoryView.addSubview(button)
        button.frame = accessoryView.bounds
        button.isUserInteractionEnabled = false // respond to accessoryView tap through `MessageCellDelegate`
        accessoryView.clipsToBounds = true
        if let message = message as? ChatMessage, let transfer = message.transfer, transfer.state == .failed {
            button.setImage(MEGAAssets.UIImage.triangle.imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        } else {
            let forwardImage = MEGAAssets.UIImage.forwardButton.imageFlippedForRightToLeftLayoutDirection()
            button.setImage(forwardImage, for: .normal)
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView,
                             for message: any MessageType,
                             at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) {
        
        guard let userHandle = UInt64(message.sender.senderId) else { return }
        guard let chatMessage = self.messageForItem(at: indexPath, in: messagesCollectionView) as? ChatMessage else {
            return
        }
        
        guard !chatMessage.message.isManagementMessage else { return }
        
        if indexPath.section < messages.count - 1 {
            // we show avatar only in the last message from user -
            // basically only in the last cell (when there are multiple consecutive messages from single user),
            // before the cell showing a message from another user
            guard messages[indexPath.section + 1].sender.senderId != message.sender.senderId else {
                avatarView.isHidden = true
                return
            }
        }
        
        let chatInitials = initials(for: message)
        // if avatar is hidden we can skip the avatar loading logic
        let hidden = senderIsMyself(message: message)
        avatarView.isHidden = hidden
        if !hidden {
            // getting avatar is 2 stage process
            // 1. if we have file saved to disk [generated or fetched], we return it immediately
            // 2. if not, we generate avatar placeholder, save it to disk and kick off a request to SDK
            //    to fetch proper image and then we save it to the same file, where we saved the generated image
            // There are two problems with this
            //  a. If we request the same avatar for few cells quickly one after another,
            // they will all have generated avatar displayed and there's no mechanism to reload those avatars (with fetched image) once
            // image is fetched by the SDK (this problem is solved below, by getting all cells that have avatar and reloading them)
            //  b. There' seems to be no mechanism (in the iOS) for retrying the image fetching if it fails for some reason.
            // Because we use presence of the image file at a given path as marker of needing to kick off the fetch, once avatar
            // is generated, it will not be refetched
            
            let avatarLoaded = {[weak self] in
                guard let self else { return }
                let indexPaths = messagesCollectionView.visibleCells.compactMap { cell in
                    cell as? MessageContentCell
                }.compactMap { cell in
                    if
                        let ip = messagesCollectionView.indexPath(for: cell),
                        let pathsToReload = self.avatarIndexPathsForUserHandle[userHandle] {
                        return pathsToReload.contains(ip) ? ip : nil
                    }
                    return nil
                }
                // we reload only the cells that where displaying avatar for this user
                messagesCollectionView.reloadItems(at: indexPaths)
                avatarIndexPathsForUserHandle[userHandle] = nil
            }
            // we keep track of which cells were used to show avatar of given user,
            // we remove those index paths once cells are removed from UICV (implemented in the didEndDisplaying method)
            // so that once avatar is loaded, we reload ONLY visible cells for given user
            addCell(indexPath: indexPath, userHandle: userHandle)
            
            let avatar = Avatar(image: avatarImage(for: message, avatarLoaded: avatarLoaded), initials: chatInitials)
            avatarView.set(avatar: avatar)
        }
    }
    
    func addCell(indexPath: IndexPath, userHandle: UInt64) {
        if var indexPaths = avatarIndexPathsForUserHandle[userHandle] {
            indexPaths.insert(indexPath)
            avatarIndexPathsForUserHandle[userHandle] = indexPaths
        } else {
            avatarIndexPathsForUserHandle[userHandle] = [indexPath]
        }
    }
    
    func detectorAttributes(for detector: DetectorType, and message: any MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        let color = textColor(for: message, at: indexPath, in: messagesCollectionView)
        return [.foregroundColor: color,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: color
        ]
        
    }
    
    func enabledDetectors(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .transitInformation, .mention, .hashtag]
    }
    
    // MARK: - Audio Messages
    
    func audioTintColor(for message: any MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        textColor(for: message, at: indexPath, in: messagesCollectionView)
    }
    
    func configureAudioCell(_ cell: AudioMessageCell, message: any MessageType) {
        audioController.configureAudioCell(cell, message: message) // this is needed especily when the cell is reconfigure while is playing sound
    }
    
    func audioProgressTextFormat(_ duration: Float, for audioCell: AudioMessageCell, in messageCollectionView: MessagesCollectionView) -> String {
        return TimeInterval(duration).timeString
    }
    
    // MARK: - Private methods
    
    private func shouldShowAccessoryView(for message: some MessageType) -> Bool {
        guard let chatMessage = message as? ChatMessage,
              !isEditing
        else { return false }
        
        return chatMessage.message.shouldShowForwardAccessory()
    }
    
    private func chatBubbleBackgroundColor(for message: any MessageType) -> UIColor {
        return isFromCurrentSender(message: message) ?
        TokenColors.Background.surfaceInverseAccent :
        TokenColors.Background.surface2
    }
}
