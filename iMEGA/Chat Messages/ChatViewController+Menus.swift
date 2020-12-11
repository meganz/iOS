
import Foundation

extension ChatViewController {
    
    func copyMessage(_ message: ChatMessage) {
        let megaMessage = message.message
        if megaMessage.type == .normal {
            if let content = megaMessage.content {
                UIPasteboard.general.string = content
            }
        } else if megaMessage.type == .attachment {
            if megaMessage.nodeList.size.uintValue == 1,
               let node = megaMessage.nodeList.node(at: 0),
               node.name.mnz_isImagePathExtension {
                let previewFilePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "previewsV3")
                let originalImagePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "originalV3")
                if FileManager.default.fileExists(atPath: originalImagePath), let originalImage = UIImage(contentsOfFile: originalImagePath) {
                    UIPasteboard.general.image = originalImage
                } else if FileManager.default.fileExists(atPath: previewFilePath), let previewImage = UIImage(contentsOfFile: previewFilePath) {
                    UIPasteboard.general.image = previewImage
                }
            }
        }
    }
    
    func forwardMessage(_ message: ChatMessage) {
        selectedMessages.insert(message)
        customToolbar(type: .forward)
        setEditing(true, animated: true)
        
        guard let index = messages.firstIndex(where: { chatMessage -> Bool in
            guard let chatMessage = chatMessage as? ChatMessage else {
                return false
            }
            return message == chatMessage
        }) else { return }
        
        messagesCollectionView.scrollToItem(at: IndexPath(row: 0, section: index), at: .centeredVertically, animated: true)
        
    }
    
    func editMessage(_ message: ChatMessage) {
        editMessage = message
        if message.message.containsMeta?.type == MEGAChatContainsMetaType.geolocation {
            self.presentShareLocation(editing: true)
        } else {
            guard let content = editMessage?.message.content else {
                return
            }
            chatInputBar?.set(text: content)
        }
    }
    
    func deleteMessage(_ chatMessage: ChatMessage) {
        
        let megaMessage =  chatMessage.message
        
        if megaMessage.type == .attachment ||
            megaMessage.type == .voiceClip {
            if audioController.playingMessage?.messageId == chatMessage.messageId {
                if audioController.state == .playing {
                    audioController.stopAnyOngoingPlaying()
                }
            }
            MEGASdkManager.sharedMEGAChatSdk()?.revokeAttachmentMessage(forChat: chatRoom.chatId, messageId: megaMessage.messageId)
        } else {
            let foundIndex = messages.firstIndex { message -> Bool in
                guard let localChatMessage = message as? ChatMessage else {
                    return false
                }
                
                return chatMessage == localChatMessage
            }
            
            guard let index = foundIndex else {
                return
            }
            
            if megaMessage.status == .sending {
                chatRoomDelegate.chatMessages.remove(at: index)
                messagesCollectionView.performBatchUpdates({
                    messagesCollectionView.deleteSections([index])
                }, completion: nil)
            } else {
                let messageId = megaMessage.status == .sending ? megaMessage.temporalId : megaMessage.messageId
                let deleteMessage = MEGASdkManager.sharedMEGAChatSdk()?.deleteMessage(forChat: chatRoom.chatId, messageId: messageId)
                deleteMessage?.chatId = chatRoom.chatId
                chatRoomDelegate.chatMessages[index] = ChatMessage(message: deleteMessage!, chatRoom: chatRoom)
            }
        }
        
    }
    
    func removeRichPreview(_ message: ChatMessage) {
        let megaMessage =  message.message
        MEGASdkManager.sharedMEGAChatSdk()?.removeRichLink(forChat: chatRoom.chatId, messageId: megaMessage.messageId)
    }
    
    func downloadMessage(_ message: ChatMessage) {
        let megaMessage =  message.message
        var downloading = false
        
        for index in 0...megaMessage.nodeList.size.intValue - 1 {
            var node = megaMessage.nodeList.node(at: index)
            if chatRoom.isPreview {
                node = MEGASdkManager.sharedMEGASdk().authorizeNode(node!) ?? nil
            }
            
            if node != nil {
                Helper.downloadNode(node!, folderPath: Helper.relativePathForOffline(), isFolderLink: false)
                downloading = true
            }
        }
        if downloading {
            SVProgressHUD.show(UIImage(named: "hudDownload")!, status: NSLocalizedString("downloadStarted", comment: "Message shown when a download starts"))
        }
    }
    
    func importMessage(_ message: ChatMessage) {
        let megaMessage = message.message

        var nodes = [MEGANode]()
        for index in 0...megaMessage.nodeList.size.intValue - 1 {
            var node = megaMessage.nodeList.node(at: index)
            if chatRoom.isPreview {
                node = MEGASdkManager.sharedMEGASdk().authorizeNode(node!) ?? nil
            }
            if node != nil {
                nodes.append(node!)
            }
        }
        
        let navigationController = UIStoryboard.init(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as! MEGANavigationController
        
        let browserVC = navigationController.viewControllers.first as! BrowserViewController
        browserVC.selectedNodesArray = nodes
        browserVC.browserAction = .import
        
        present(viewController: navigationController)
        
    }
    
    func addContactMessage(_ message: ChatMessage) {
        let megaMessage =  message.message

        let usersCount = megaMessage.usersCount
        let inviteContactRequestDelegate = MEGAInviteContactRequestDelegate(numberOfRequests: usersCount)
        for index in 0...usersCount - 1 {
            let email = megaMessage.userEmail(at: index)
            MEGASdkManager.sharedMEGASdk().inviteContact(withEmail: email!, message: "", action: .add, delegate: inviteContactRequestDelegate)
        }
        
    }
    
    func saveToPhotos(_ chatMessage: ChatMessage) {
        if chatMessage.message.nodeList.size.uintValue == 1,
            var node = chatMessage.message.nodeList.node(at: 0),
            (node.name.mnz_isImagePathExtension || node.name.mnz_isVideoPathExtension) {
            if chatRoom.isPreview,
                let authorizedNode = MEGASdkManager.sharedMEGASdk().authorizeChatNode(node, cauth: chatRoom.authorizationToken)  {
                node = authorizedNode
            }
            
            node.mnz_saveToPhotos(withApi: MEGASdkManager.sharedMEGASdkFolder())
        } else {
            MEGALogDebug("Wrong Message type to be saved to album")
        }
    }
    
    func select(_ chatMessage: ChatMessage) {
        forwardMessage(chatMessage)
    }
}
