import MessageKit
import MapKit

extension ChatViewController: MessageCellDelegate, MEGAPhotoBrowserDelegate, MessageLabelDelegate {
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        guard let number = URL(string: "telprompt://" + phoneNumber.replacingOccurrences(of: " ", with: "-")) else { return }
        UIApplication.shared.open(number)
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
        
        let userName = chatMessage.displayName
        guard let userEmail = MEGASdkManager.sharedMEGAChatSdk().userEmailFromCache(byUserHandle: chatMessage.message.userHandle) else {
            return
        }
        
        let infoAction = ActionSheetAction(title: Strings.Localizable.info, detail: nil, image: nil, style: .default) { [weak self] in
            guard let self = self else { return }
            guard let contactDetailsVC = UIStoryboard(name: "Contacts", bundle: nil).instantiateViewController(withIdentifier: "ContactDetailsViewControllerID") as? ContactDetailsViewController else {
                return
            }
            
            contactDetailsVC.contactDetailsMode = self.chatRoom.isGroup ? .fromGroupChat : .fromChat
            contactDetailsVC.userEmail = userEmail
            contactDetailsVC.userName = userName
            contactDetailsVC.userHandle = chatMessage.message.userHandle
            contactDetailsVC.groupChatRoom = self.chatRoom
            self.navigationController?.pushViewController(contactDetailsVC, animated: true)
        }
        
        var actions = [infoAction]
        
        let user = MEGASdkManager.sharedMEGASdk().contact(forEmail: userEmail)
        if user == nil || user?.visibility != MEGAUserVisibility.visible {
            let addContactAction = ActionSheetAction(title: Strings.Localizable.addContact, detail: nil, image: nil, style: .default) {
                if MEGAReachabilityManager.isReachableHUDIfNot() {
                    MEGASdkManager.sharedMEGASdk().inviteContact(withEmail: userEmail, message: "", action: .add, delegate: MEGAInviteContactRequestDelegate(numberOfRequests: 1))
                }
                
                
            }
            actions.append(addContactAction)

        }
        
        if chatRoom.ownPrivilege == .moderator,
        chatRoom.isGroup {
            let removeParticipantAction = ActionSheetAction(title: Strings.Localizable.removeParticipant, detail: nil, image: nil, style: .default) {
                MEGASdkManager.sharedMEGAChatSdk().remove(fromChat: chatMessage.chatRoom.chatId, userHandle: chatMessage.message.userHandle)
            }
            actions.append(removeParticipantAction)

        }
        
        let userActionSheet = ActionSheetViewController(actions: actions,
                                                        headerTitle: userName,
                                                        dismissCompletion: {
            
        
        },
                                                        sender: cell.avatarView)
        present(viewController: userActionSheet)
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
        
        MEGASdkManager.sharedMEGASdk().retryTransfer(transfer)
        messagesCollectionView.reloadData()
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let messagesDataSource = messagesCollectionView.messagesDataSource,
            let chatMessage = messagesDataSource.messageForItem(at: indexPath,
                                                                in: messagesCollectionView) as? ChatMessage else { return }
        if let transfer = chatMessage.transfer, transfer.type == .upload {
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
            guard let cell = cell as? AudioMessageCell else {
                return
            }
            didTapPlayButton(in: cell)

        case .attachment:
            if megaMessage.nodeList.size.uintValue == 1 {
                var node = megaMessage.nodeList.node(at: 0)
                if chatRoom.isPreview {
                    node = MEGASdkManager.sharedMEGASdk().authorizeChatNode(node!, cauth: chatRoom.authorizationToken)

                }
                
                if let name = node?.name,
                    (name.mnz_isVisualMediaPathExtension) {
                    var mediaNodesArrayIndex = 0
                    var foundIndex: Int?
                    let mediaNodesArray = messages.compactMap { message -> MEGANode? in
                        guard let localChatMessage = message as? ChatMessage,
                              localChatMessage.message.type == .attachment,
                              localChatMessage.message.nodeList.size.intValue > 0,
                              let node = localChatMessage.message.nodeList.node(at: 0),
                              name.mnz_isVisualMediaPathExtension else {
                            return nil
                        }
                        
                        if chatRoom.isPreview {
                            if let authorizedNode = MEGASdkManager.sharedMEGASdk().authorizeChatNode(node, cauth: chatRoom.authorizationToken) {
                                if localChatMessage == chatMessage {
                                    foundIndex = mediaNodesArrayIndex
                                }
                                mediaNodesArrayIndex += 1
                                return authorizedNode
                            } else {
                                return nil
                            }
                        }
                        
                        if localChatMessage == chatMessage {
                            foundIndex = mediaNodesArrayIndex
                        }
                        mediaNodesArrayIndex += 1
                        return node
                    }
                    
                    let photoBrowserVC = MEGAPhotoBrowserViewController.photoBrowser(withMediaNodes:  NSMutableArray(array: mediaNodesArray),
                                                                                     api: MEGASdkManager.sharedMEGASdk(),
                                                                                     displayMode: .chatAttachment,
                                                                                     presenting: nil,
                                                                                     preferredIndex: UInt(foundIndex ?? 0))
                    photoBrowserVC?.delegate = self
                    present(viewController: photoBrowserVC!)
                } else {
                    node?.mnz_open(in: navigationController, folderLink: false, fileLink: nil)
                }
            } else {
                let chatAttachedNodesVC = UIStoryboard.init(name: "Chat", bundle: nil).instantiateViewController(withIdentifier: "ChatAttachedNodesViewControllerID") as! ChatAttachedNodesViewController
                chatAttachedNodesVC.message = megaMessage
                navigationController?.pushViewController(chatAttachedNodesVC, animated: true)
            }
            
        case .contact:
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
        case .containsMeta:
            if megaMessage.containsMeta.type == .richPreview {
                let url = URL(string: megaMessage.containsMeta.richPreview.url)
                MEGALinkManager.linkURL = url
                MEGALinkManager.processLinkURL(url)
            } else if megaMessage.containsMeta.type == .geolocation {
                let geocoder = CLGeocoder()
                let location = CLLocation(latitude: CLLocationDegrees(megaMessage.containsMeta.geolocation.latitude), longitude: CLLocationDegrees(megaMessage.containsMeta.geolocation.longitude))
                geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
                    let placemark = MKPlacemark(coordinate: location.coordinate)
                    let mapItem = MKMapItem(placemark: placemark)
                    
                    if (error == nil && placemarks!.count > 0) {
                        mapItem.name = placemarks?.first?.name
                    }
                    mapItem.openInMaps(launchOptions: nil)
                }
            }
        default:
            if megaMessage.node != nil {
                MEGALinkManager.linkURL = megaMessage.megaLink
                MEGALinkManager.processLinkURL(megaMessage.megaLink)
            }
        }
    }
    
}
