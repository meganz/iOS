import MessageKit

extension ChatViewController: MessagesDisplayDelegate {
    
    func backgroundColor(for message: MessageType,
                         at indexPath: IndexPath,
                         in messagesCollectionView: MessagesCollectionView) -> UIColor {
        
        guard let chatMessage = messageForItem(at: indexPath, in: messagesCollectionView) as? ChatMessage else {
            return isFromCurrentSender(message: message) ? UIColor.mnz_chatOutgoingBubble(UIScreen.main.traitCollection) : UIColor.mnz_chatIncomingBubble(UIScreen.main.traitCollection)
        }
        
        if chatMessage.message.isManagementMessage {
            return .clear
        }
        
        if chatMessage.transfer?.transferChatMessageType() == .attachment {
            return UIColor.mnz_chatIncomingBubble(UIScreen.main.traitCollection)
        }
        
        switch chatMessage.message.type {
        case .contact, .attachment:
            return UIColor.mnz_chatIncomingBubble(UIScreen.main.traitCollection)
        case .normal:
            if ((chatMessage.message.content ?? "") as NSString).mnz_isPureEmojiString() {
                return .clear
            }
            return isFromCurrentSender(message: message) ? UIColor.mnz_chatOutgoingBubble(UIScreen.main.traitCollection) : UIColor.mnz_chatIncomingBubble(UIScreen.main.traitCollection)
            
        default:
            return isFromCurrentSender(message: message) ? UIColor.mnz_chatOutgoingBubble(UIScreen.main.traitCollection) : UIColor.mnz_chatIncomingBubble(UIScreen.main.traitCollection)
            
        }
        
    }

    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .mnz_label()
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        return .custom { [weak self] containerView in
            guard let `self` = self else {
                return
            }
            
            guard let chatMessage = self.messageForItem(at: indexPath, in: messagesCollectionView) as? ChatMessage else {
                return
            }
            containerView.layer.cornerRadius = 13.0
            
            let boraderColor = self.isFromCurrentSender(message: message) ? UIColor.mnz_chatOutgoingBubble(UIScreen.main.traitCollection) : UIColor.mnz_chatIncomingBubble(UIScreen.main.traitCollection)
            containerView.layer.borderColor = boraderColor.cgColor
            containerView.layer.borderWidth = 1
            
            if chatMessage.message.status == .sending || chatMessage.message.status == .sendingManual, chatMessage.transfer?.transferChatMessageType() != .voiceClip {
                containerView.alpha = 0.7
            } else {
                containerView.alpha = 1
            }
            
            if chatMessage.message.isManagementMessage {
                containerView.layer.borderColor = #colorLiteral(red: 0.8941176471, green: 0.9215686275, blue: 0.9176470588, alpha: 0).cgColor
                return
            }
            
            if chatMessage.message.type == .normal && ((chatMessage.message.content ?? "") as NSString).mnz_isPureEmojiString() {
                containerView.layer.borderColor = #colorLiteral(red: 0.8941176471, green: 0.9215686275, blue: 0.9176470588, alpha: 0).cgColor
            }
            
            if chatMessage.transfer?.transferChatMessageType() == .attachment {
                containerView.layer.borderColor = #colorLiteral(red: 0.8941176471, green: 0.9215686275, blue: 0.9176470588, alpha: 0).cgColor
            }
            
            if chatMessage.message.type == .attachment && (chatMessage.message.nodeList?.size?.intValue ?? 0 == 1) {
                if let node = chatMessage.message.nodeList?.node(at: 0), (node.name?.mnz_isVisualMediaPathExtension ?? false) {
                    containerView.layer.borderColor = #colorLiteral(red: 0.8941176471, green: 0.9215686275, blue: 0.9176470588, alpha: 0).cgColor
                }
            }
            
            if chatMessage.message.type == .containsMeta,
                chatMessage.message.containsMeta?.type == .giphy {
                containerView.layer.borderColor = #colorLiteral(red: 0.8941176471, green: 0.9215686275, blue: 0.9176470588, alpha: 0).cgColor
            }
            
        }
    }

    func configureAccessoryView(_ accessoryView: UIView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
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
            button.setImage(Asset.Images.Chat.triangle.image.imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        } else {
            button.setImage(Asset.Images.Chat.Messages.forward.image.imageFlippedForRightToLeftLayoutDirection(), for: .normal)
        }
    }
    
    func configureAvatarView(_ avatarView: AvatarView,
                             for message: MessageType,
                             at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) {
        
        guard let chatMessage = self.messageForItem(at: indexPath, in: messagesCollectionView) as? ChatMessage else {
            return
        }
        if !chatMessage.message.isManagementMessage && !isFromCurrentSender(message: message) {
            if indexPath.section < messages.count - 1 {
                guard messages[indexPath.section + 1].sender.senderId != message.sender.senderId else {
                    avatarView.isHidden = true
                    return
                }
            }
            
            let chatInitials = initials(for: message)
            let avatar = Avatar(image: avatarImage(for: message), initials: chatInitials)
            avatarView.set(avatar: avatar)
            avatarView.isHidden = isFromCurrentSender(message: message)
        }
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        let color = textColor(for: message, at: indexPath, in: messagesCollectionView)
        return [.foregroundColor: color,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .underlineColor: color
        ]
        
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .transitInformation, .mention, .hashtag]
    }
    
    // MARK: - Audio Messages
    
    func audioTintColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .mnz_label()
    }
    
    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        audioController.configureAudioCell(cell, message: message) // this is needed especily when the cell is reconfigure while is playing sound
    }
    
    func audioProgressTextFormat(_ duration: Float, for audioCell: AudioMessageCell, in messageCollectionView: MessagesCollectionView) -> String {
        return NSString.mnz_string(fromTimeInterval: TimeInterval(duration))
    }
    
    // MARK: - Private methods
    
    private func shouldShowAccessoryView(for message: MessageType) -> Bool {
        guard let chatMessage = message as? ChatMessage,
            !isEditing
            else { return false }
        
        return chatMessage.message.shouldShowForwardAccessory()
    }
}
