import MessageKit

extension ChatViewController: MessageCellDelegate, MEGAPhotoBrowserDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
    }
    
    func didTapAccessoryView(in cell: MessageCollectionViewCell) {
        print("Accessory view tapped")
        cell.forward(nil)
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
        MEGALinkManager.linkURL = url;
        MEGALinkManager.processLinkURL(url)
    }
    
    func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                print("Failed to identify message when audio cell receive tap gesture")
                return
        }
        guard audioController.state != .stopped else {
            // There is no audio sound playing - prepare to start playing for given audio message
            audioController.playSound(for: message, in: cell)
            return
        }
        if audioController.playingMessage?.messageId == message.messageId {
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
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message view tapped")
        let indexPath = messagesCollectionView.indexPath(for: cell)!
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else { return }
           
        guard let chatMessage = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as? ChatMessage else {
            return
        }

        let megaMessage = chatMessage.message
        
        switch megaMessage.type {
        case .attachment:
            if megaMessage.nodeList.size.uintValue == 1 {
                var node = megaMessage.nodeList.node(at: 0)
                if chatRoom.isPreview {
                    node = MEGASdkManager.sharedMEGASdk()?.authorizeChatNode(node!, cauth: chatRoom.authorizationToken)

                }
                if node == nil {
                    return
                }
                if node!.name.mnz_isImagePathExtension || node!.name.mnz_isImagePathExtension {
                    let attachments = messages.filter { (message) -> Bool in
                        guard let localChatMessage = message as? ChatMessage else {
                            return false
                        }
                        
                        return localChatMessage.message.type == .attachment
                    }
                    
                    var mediaNodesArray = [MEGANode]()
                    
                    attachments.forEach { (message) in
                        guard let localChatMessage = message as? ChatMessage else {
                            return
                        }
                        
                        var tempNode = localChatMessage.message.nodeList.node(at: 0)
                        if chatRoom.isPreview {
                            tempNode = MEGASdkManager.sharedMEGASdk()?.authorizeChatNode(tempNode!, cauth: chatRoom.authorizationToken)
                        }
                        if tempNode != nil {
                            mediaNodesArray.append(tempNode!)
                        }
                    }
                    let idx = attachments.firstIndex { message -> Bool in
                        guard let localChatMessage = message as? ChatMessage else {
                            return false
                        }
                        
                        return localChatMessage == chatMessage
                    }
                    let photoBrowserVC = MEGAPhotoBrowserViewController.photoBrowser(withMediaNodes:  NSMutableArray(array: mediaNodesArray),
                                                                                     api: MEGASdkManager.sharedMEGASdk(),
                                                                                     displayMode: .chatAttachment,
                                                                                     presenting: nil,
                                                                                     preferredIndex: UInt(idx!))
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
