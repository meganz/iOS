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
                }
                
            }
        default:
            return
        }
    }
    
}
