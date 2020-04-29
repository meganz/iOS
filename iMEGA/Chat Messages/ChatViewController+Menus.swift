
import Foundation

extension ChatViewController {
    
    func forwardMessage(_ message: MEGAChatMessage) {
        let chatStoryboard = UIStoryboard(name: "Chat", bundle: nil)
        let sendToNC = chatStoryboard.instantiateViewController(withIdentifier: "SendToNavigationControllerID") as! UINavigationController
        let sendToViewController = sendToNC.viewControllers.first as! SendToViewController
        
        sendToViewController.sendMode = .forward
        sendToViewController.messages = [message]
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
    
    
    func editMessage(_ message: MEGAChatMessage) {
        editMessage = message
        chatInputBar.set(text: editMessage!.content)
    }
}
