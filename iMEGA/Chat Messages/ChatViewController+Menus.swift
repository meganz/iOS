
import Foundation

extension ChatViewController {
    
    func copyMessage(_ message: ChatMessage) {
        let megaMessage = message.message
        UIPasteboard.general.string = megaMessage.content
    }
    
    func forwardMessage(_ message: ChatMessage) {
        self.setEditing(true, animated: true)
    }
    
    
    func editMessage(_ message: ChatMessage) {
        editMessage = message
        chatInputBar?.set(text: editMessage!.message.content)
    }
    
    func deleteMessage(_ message: ChatMessage) {
    
        let megaMessage =  message.message
        
        if megaMessage.type == .attachment ||
        megaMessage.type == .voiceClip {
            
        } else {
            let index = messages.firstIndex(of: message)!
            if megaMessage.status == .sending {
                chatRoomDelegate.messages.remove(at: index)
                messagesCollectionView.performBatchUpdates({
                    messagesCollectionView.deleteSections([index])
                }, completion: nil)
            } else {
                let messageId = megaMessage.status == .sending ? megaMessage.temporalId : megaMessage.messageId
                let deleteMessage = MEGASdkManager.sharedMEGAChatSdk()?.deleteMessage(forChat: chatRoom.chatId, messageId: messageId)
                deleteMessage?.chatId = chatRoom.chatId
                chatRoomDelegate.messages[index] = ChatMessage(message: deleteMessage!, chatRoom: chatRoom)
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
                node = MEGASdkManager.sharedMEGASdk()?.authorizeNode(node!) ?? nil
            }
            
            if node != nil {
                Helper.downloadNode(node!, folderPath: Helper.relativePathForOffline(), isFolderLink: false, shouldOverwrite: false)
                downloading = true
            }
        }
        if downloading {
            SVProgressHUD.show(UIImage(named: "hudDownload")!, status: AMLocalizedString("downloadStarted", "Message shown when a download starts"))
        }
    }
    
    func importMessage(_ message: ChatMessage) {
        let megaMessage = message.message

        var nodes = [MEGANode]()
        for index in 0...megaMessage.nodeList.size.intValue - 1 {
            var node = megaMessage.nodeList.node(at: index)
            if chatRoom.isPreview {
                node = MEGASdkManager.sharedMEGASdk()?.authorizeNode(node!) ?? nil
            }
            if node != nil {
                nodes.append(node!)
            }
        }
        
        let navigationController = UIStoryboard.init(name: "Cloud", bundle: nil).instantiateViewController(withIdentifier: "BrowserNavigationControllerID") as! MEGANavigationController
        
        let browserVC = navigationController.viewControllers.first as! BrowserViewController
        browserVC.selectedNodesArray = nodes
        browserVC.browserAction = .import
        
        self.present(viewController: navigationController)
        
    }
    
    func addContactMessage(_ message: ChatMessage) {
        let megaMessage =  message.message

        let usersCount = megaMessage.usersCount
        let inviteContactRequestDelegate = MEGAInviteContactRequestDelegate(numberOfRequests: usersCount)
        for index in 0...usersCount - 1 {
            let email = megaMessage.userEmail(at: index)
            MEGASdkManager.sharedMEGASdk()?.inviteContact(withEmail: email!, message: "", action: .add, delegate: inviteContactRequestDelegate)
        }
        
    }
}
