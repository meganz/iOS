
import Foundation

extension ChatViewController {
    
    func copyMessage(_ message: ChatMessage) {
        let megaMessage = message.message
        UIPasteboard.general.string = megaMessage.content
    }
    
    func forwardMessage(_ message: ChatMessage) {
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
                
                let chatNC = self.parent as! UINavigationController
                chatNC.pushViewController(messagesVC, animated: true)
                var viewControllers = chatNC.viewControllers
                viewControllers.remove(at: viewControllers.count - 2)
                chatNC.viewControllers = viewControllers
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
        chatInputBar.set(text: editMessage!.message.content)
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
    
}
