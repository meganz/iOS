import MessageKit

extension ChatViewController: MessageCellDelegate, MEGAPhotoBrowserDelegate {
    
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
    }
    
    func didTapAccessoryView(in cell: MessageCollectionViewCell) {
        print("Accessory view tapped")
        cell.forward(nil)
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message view tapped")
        let indexPath = messagesCollectionView.indexPath(for: cell)!
        print(indexPath)
        guard let messagesDataSource = messagesCollectionView.messagesDataSource else { return }
           
        let chatMessage = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView) as! ChatMessage

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
                    let reverse = messages.filter { (message) -> Bool in
                        return message.message.type == .attachment
                    }.reversed()
                    
                    var mediaNodesArray = [MEGANode]()
                    
                    reverse.forEach { (message) in
                        var tempNode = message.message.nodeList.node(at: 0)
                        if chatRoom.isPreview {
                            tempNode = MEGASdkManager.sharedMEGASdk()?.authorizeChatNode(tempNode!, cauth: chatRoom.authorizationToken)
                        }
                        if tempNode != nil {
                            mediaNodesArray.append(tempNode!)
                        }
                    }
                    let idx = mediaNodesArray.firstIndex(of:node!) ?? 0
                    let photoBrowserVC = MEGAPhotoBrowserViewController.photoBrowser(withMediaNodes:  NSMutableArray(array: mediaNodesArray),
                                                                                     api: MEGASdkManager.sharedMEGASdk(),
                                                                                     displayMode: .chatAttachment,
                                                                                     presenting: nil,
                                                                                     preferredIndex: UInt(idx))
                    photoBrowserVC?.delegate = self
                    photoBrowserVC?.hidesBottomBarWhenPushed = true
                    present(viewController: photoBrowserVC!)
                } else {
                    node?.mnz_open(in: navigationController, folderLink: false)
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
