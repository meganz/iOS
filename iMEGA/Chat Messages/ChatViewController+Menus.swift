
import Foundation

extension ChatViewController {
    
    func copyMessage(_ message: ChatMessage) {
        let megaMessage = message.message
        UIPasteboard.general.string = megaMessage.content
    }
    
    func forwardMessage(_ message: ChatMessage) {
        
        self.setEditing(true, animated: true)
        return
        let megaMessage = message.message
        let chatStoryboard = UIStoryboard(name: "Chat", bundle: nil)
        let sendToNC = chatStoryboard.instantiateViewController(withIdentifier: "SendToNavigationControllerID") as! UINavigationController
        let sendToViewController = sendToNC.viewControllers.first as! SendToViewController
        
        sendToViewController.sendMode = .forward
        sendToViewController.messages = [megaMessage]
        sendToViewController.sourceChatId = chatRoom.chatId
        sendToViewController.completion = { (chatIdNumbers, sentMessages) in
            var selfForwarded = false
            var showSuccess = false
            
            chatIdNumbers?.forEach({ (chatIdNumber) in
                let chatId = chatIdNumber.uint64Value
                if chatId == self.chatRoom.chatId {
                    selfForwarded = true
                }
            })
            
            if selfForwarded {
                sentMessages?.forEach({ (message) in
                    let filteredArray = self.messages.filter { chatMessage in
                        return chatMessage.message.temporalId == message.temporalId
                    }
                    if filteredArray.count > 0 {
                        MEGALogWarning("Forwarded message was already added to the array, probably onMessageUpdate received before now.")
                    } else {
                        message.chatId = self.chatRoom.chatId
                        self.chatRoomDelegate.insertMessage(message)
                        self.messagesCollectionView.scrollToBottom()
                    }
                    
                })
                
                showSuccess = chatIdNumbers?.count ?? 0 > 1;
            } else if chatIdNumbers?.count == 1 && self.chatRoom.isPreview {
                let chatId = chatIdNumbers?.first!.uint64Value
                let chatRoom = MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(forChatId: chatId!)
                let messagesVC = ChatViewController()
                messagesVC.chatRoom = chatRoom
                self.replaceCurrentViewController(withViewController: messagesVC)
            } else {
                showSuccess = true
            }
            
            
            
            if showSuccess {
                SVProgressHUD.showSuccess(withStatus: AMLocalizedString("messagesSent", "Success message shown after forwarding messages to other chats"))
            }
        }
        
        present(sendToNC, animated: true, completion: nil)
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
