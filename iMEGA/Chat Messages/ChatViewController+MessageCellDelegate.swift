import MapKit
import MEGADomain
import MEGAL10n
import MessageKit

extension ChatViewController: MessageCellDelegate, MessageLabelDelegate {
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        guard let number = generateURL(forPhoneNumber: phoneNumber) else { return }
        UIApplication.shared.open(number)
    }
    
    private func generateURL(forPhoneNumber phoneNumber: String) -> URL? {
        let urlString = "telprompt://" + phoneNumber.replacingOccurrences(of: " ", with: "-")
        return URL(string: urlString)
    }
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              let dataSource = messagesCollectionView.messagesDataSource,
              let chatMessage = dataSource.messageForItem(at: indexPath, in: messagesCollectionView) as? ChatMessage,
              let cell = cell as? MessageContentCell
        else {
            MEGALogInfo("Failed to identify message when audio cell receive tap gesture")
            return
        }
        
        showAvatarActions(for: chatMessage, cell: cell)
    }
    
    private func showAvatarActions(for chatMessage: ChatMessage, cell: MessageContentCell) {
        guard let userEmail = MEGAChatSdk.shared.userEmailFromCache(byUserHandle: chatMessage.message.userHandle) else {
            return
        }
        
        var actions = [createInfoAction(for: chatMessage, userEmail: userEmail)]
        
        let user = MEGASdk.shared.contact(forEmail: userEmail)
        if user == nil || user?.visibility != MEGAUserVisibility.visible {
            actions.append(createAddContactsAction(forEmail: userEmail))
        }
        
        if chatRoom.ownPrivilege == .moderator, chatRoom.isGroup {
            actions.append(createRemoveParticipantAction(for: chatMessage))
        }
        
        let userActionSheet = ActionSheetViewController(actions: actions,
                                                        headerTitle: chatMessage.displayName,
                                                        dismissCompletion: nil,
                                                        sender: cell.avatarView)
        present(viewController: userActionSheet)
    }
    
    private func createInfoAction(for chatMessage: ChatMessage, userEmail: String) -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.info, detail: nil, image: nil, style: .default) { [weak self] in
            guard let self else { return }
            guard let contactDetailsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactDetailsViewControllerID") as? ContactDetailsViewController else {
                return
            }
            
            contactDetailsVC.contactDetailsMode = self.chatRoom.isGroup ? .fromGroupChat : .fromChat
            contactDetailsVC.userEmail = userEmail
            contactDetailsVC.userName = chatMessage.displayName
            contactDetailsVC.userHandle = chatMessage.message.userHandle
            contactDetailsVC.groupChatRoom = self.chatRoom.toMEGAChatRoom()
            self.navigationController?.pushViewController(contactDetailsVC, animated: true)
        }
    }
    
    private func createAddContactsAction(forEmail userEmail: String) -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.addContact, detail: nil, image: nil, style: .default) {
            if MEGAReachabilityManager.isReachableHUDIfNot() {
                MEGASdk.shared.inviteContact(withEmail: userEmail, message: "", action: .add, delegate: MEGAInviteContactRequestDelegate(numberOfRequests: 1))
            }
        }
    }
    
    private func createRemoveParticipantAction(for chatMessage: ChatMessage) -> ActionSheetAction {
        ActionSheetAction(title: Strings.Localizable.removeParticipant, detail: nil, image: nil, style: .default) {
            MEGAChatSdk.shared.remove(fromChat: chatMessage.chatRoom.chatId, userHandle: chatMessage.message.userHandle)
        }
    }
    
    func didTapAccessoryView(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) as? ChatMessage,
              message.transfer?.state != .failed else {
                  MEGALogInfo("Failed to identify message when audio cell receive tap gesture")
                  return
              }
        
        selectedMessages = [message]
        forwardSelectedMessages()
        
    }
    
    func didSelectURL(_ url: URL) {
        MEGALogInfo("URL Selected: \(url)")
        MEGALinkManager.linkURL = url
        MEGALinkManager.processLinkURL(url)
    }
    
    func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                  MEGALogInfo("Failed to identify message when audio cell receive tap gesture")
                  return
              }
        guard audioController.state != .stopped else {
            // There is no audio sound playing - prepare to start playing for given audio message
            audioController.playSound(for: message, in: cell)
            return
        }
        if audioController.isPlayingSameMessage(message) {
            // tap occur in the current cell that is playing audio sound
            if audioController.state == .playing {
                audioController.pauseSound(for: message, in: cell)
            } else {
                audioController.resumeSound()
            }
        } else {
            // tap occur in a difference cell that the one is currently playing sound. First stop currently playing and start the sound for given message
            audioController.stopAnyOngoingPlaying()
            audioController.playSound(for: message, in: cell)
        }
    }
    
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              let messagesDataSource = messagesCollectionView.messagesDataSource,
              let chatMessage = messagesDataSource.messageForItem(at: indexPath,
                                                                  in: messagesCollectionView) as? ChatMessage,
              let transfer = chatMessage.transfer,
              transfer.state == .failed else { return }
        
        MEGASdk.shared.retryTransfer(transfer)
        messagesCollectionView.reloadData()
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
              let messagesDataSource = messagesCollectionView.messagesDataSource,
              let chatMessage = messagesDataSource.messageForItem(
                at: indexPath,
                in: messagesCollectionView
              ) as? ChatMessage else {
            return
        }
        
        if chatMessage.transfer?.type == .upload {
            checkTransferPauseStatus()
            if chatMessage.transfer?.transferChatMessageType() == .voiceClip {
                guard let cell = cell as? AudioMessageCell else {
                    return
                }
                didTapPlayButton(in: cell)
            }
            return
        }
        
        let megaMessage = chatMessage.message
        
        switch megaMessage.type {
        case .voiceClip:
            didTapVoiceClipTypeMessage(chatMessage, in: cell)
        case .attachment:
            didTapAttachmentTypeMessage(chatMessage, in: cell)
        case .contact:
            didTapContactTypeMessage(chatMessage, in: cell)
        case .containsMeta:
            didTapContainsMetaMessage(chatMessage, in: cell)
        default:
            if megaMessage.node != nil {
                MEGALinkManager.linkURL = megaMessage.megaLink
                MEGALinkManager.processLinkURL(megaMessage.megaLink)
            }
        }
    }
    
    private func didTapVoiceClipTypeMessage(
        _ chatMessage: ChatMessage,
        in cell: MessageCollectionViewCell
    ) {
        guard let cell = cell as? AudioMessageCell else {
            return
        }
        didTapPlayButton(in: cell)
    }
    
    private func didTapAttachmentTypeMessage(
        _ chatMessage: ChatMessage,
        in cell: MessageCollectionViewCell
    ) {
        let megaMessage = chatMessage.message
        if megaMessage.nodeList?.size == 1 {
            var node = megaMessage.nodeList?.node(at: 0)
            if chatRoom.isPreview {
                node = MEGASdk.shared.authorizeChatNode(node!, cauth: chatRoom.authorizationToken)
            }
            
            if let name = node?.name,
               name.fileExtensionGroup.isVisualMedia {
                var mediaNodesArrayIndex = 0
                var foundIndex: Int?
                var mediaMessagesArray = [HandleEntity]()
                let mediaNodesArray = messages.compactMap { message -> MEGANode? in
                    guard let localChatMessage = message as? ChatMessage,
                          localChatMessage.message.type == .attachment,
                          localChatMessage.message.nodeList?.size ?? 0 > 0,
                          let node = localChatMessage.message.nodeList?.node(at: 0),
                          name.fileExtensionGroup.isVisualMedia else {
                              return nil
                          }
                    
                    if chatRoom.isPreview {
                        if let authorizedNode = MEGASdk.shared.authorizeChatNode(node, cauth: chatRoom.authorizationToken) {
                            if localChatMessage == chatMessage {
                                foundIndex = mediaNodesArrayIndex
                            }
                            mediaNodesArrayIndex += 1
                            mediaMessagesArray.append(localChatMessage.message.messageId)
                            return authorizedNode
                        } else {
                            return nil
                        }
                    }
                    
                    if localChatMessage == chatMessage {
                        foundIndex = mediaNodesArrayIndex
                    }
                    mediaNodesArrayIndex += 1
                    mediaMessagesArray.append(localChatMessage.message.messageId)
                    return node
                }
                
                let photoBrowserVC = MEGAPhotoBrowserViewController.photoBrowser(withMediaNodes: NSMutableArray(array: mediaNodesArray),
                                                                                 api: MEGASdk.shared,
                                                                                 displayMode: .chatAttachment, 
                                                                                 isFromSharedItem: false,
                                                                                 preferredIndex: UInt(foundIndex ?? 0))
                photoBrowserVC.configureMediaAttachment(forMessageId: megaMessage.messageId, inChatId: chatRoom.chatId, messagesIds: mediaMessagesArray)
                present(viewController: photoBrowserVC)
            } else {
                if let navController = node?.mnz_viewControllerForNode(inFolderLink: false, fileLink: nil) as? MEGANavigationController, let viewController = navController.topViewController as? PreviewDocumentViewController {
                    viewController.chatId = chatRoom.chatId
                    viewController.messageId = megaMessage.messageId
                    navigationController?.present(navController, animated: true)
                } else {
                    let messageId = NSNumber(value: megaMessage.messageId)
                    let chatId = NSNumber(value: chatRoom.chatId)
                    node?.mnz_open(in: navigationController, folderLink: false, fileLink: nil, messageId: messageId, chatId: chatId, isFromSharedItem: false, allNodes: nil)
                }
            }
        } else {
            let chatAttachedNodesVC = UIStoryboard.init(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ChatAttachedNodesViewControllerID") as! ChatAttachedNodesViewController
            chatAttachedNodesVC.message = megaMessage
            chatAttachedNodesVC.chatId = chatRoom.chatId
            navigationController?.pushViewController(chatAttachedNodesVC, animated: true)
        }
    }
    
    private func didTapContactTypeMessage(
        _ chatMessage: ChatMessage,
        in cell: MessageCollectionViewCell
    ) {
        let megaMessage = chatMessage.message
        if megaMessage.usersCount == 1 {
            let userEmail = megaMessage.userEmail(at: 0)
            let userName = megaMessage.userName(at: 0)
            let userHandle = megaMessage.userHandle(at: 0)
            
            let contactDetailsVC = UIStoryboard.init(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactDetailsViewControllerID") as! ContactDetailsViewController
            contactDetailsVC.contactDetailsMode = .default
            contactDetailsVC.userName = userName
            contactDetailsVC.userEmail = userEmail
            contactDetailsVC.userHandle = userHandle
            navigationController?.pushViewController(contactDetailsVC, animated: true)
        } else {
            let chatAttachedNodesVC = UIStoryboard.init(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ChatAttachedContactsViewControllerID") as! ChatAttachedContactsViewController
            chatAttachedNodesVC.message = megaMessage
            navigationController?.pushViewController(chatAttachedNodesVC, animated: true)
        }
    }
    
    private func didTapContainsMetaMessage(
        _ chatMessage: ChatMessage,
        in cell: MessageCollectionViewCell
    ) {
        let megaMessage = chatMessage.message
        guard let containsMeta = megaMessage.containsMeta else { return }
        if megaMessage.containsMeta?.type == .richPreview {
            let url = URL(string: containsMeta.richPreview?.url ?? "")
            MEGALinkManager.linkURL = url
            MEGALinkManager.processLinkURL(url)
        } else if megaMessage.containsMeta?.type == .geolocation, let geolocation = containsMeta.geolocation {
            let geocoder = CLGeocoder()
            let location = CLLocation(latitude: CLLocationDegrees(geolocation.latitude), longitude: CLLocationDegrees(geolocation.longitude))
            geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                let placemark = MKPlacemark(coordinate: location.coordinate)
                let mapItem = MKMapItem(placemark: placemark)
                
                if error == nil && placemarks?.isNotEmpty == true {
                    mapItem.name = placemarks?.first?.name
                }
                mapItem.openInMaps(launchOptions: nil)
            }
        }
    }
}
