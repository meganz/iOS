import UIKit

enum ToolbarType {
    case delete
    case forward
}

extension ChatViewController {
    func customToolbar(type: ToolbarType) {
        let flexibleItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        switch type {
        case .forward:
            setToolbarItems([shareBarButtonItem, flexibleItem, forwardBarButtonItem], animated: true)
        case .delete:
            setToolbarItems([deleteBarButtonItem], animated: true)
        }
    }
    
    
    @objc func deleteSelectedMessages() {
        
        for chatMessage in selectedMessages {
            
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
        setEditing(false, animated: true)
    }
    
    @objc func forwardSelectedMessages() {
      
        var megaMessages = [MEGAChatMessage]()
        for chatMessage in selectedMessages {
            megaMessages.append(chatMessage.message)
        }
        let chatStoryboard = UIStoryboard(name: "Chat", bundle: nil)
        let sendToNC = chatStoryboard.instantiateViewController(withIdentifier: "SendToNavigationControllerID") as! UINavigationController
        let sendToViewController = sendToNC.viewControllers.first as! SendToViewController
        
        sendToViewController.sendMode = .forward
        sendToViewController.messages = megaMessages.sorted(by: { (obj1, obj2) -> Bool in
            obj1.messageIndex < obj2.messageIndex
        })
        sendToViewController.sourceChatId = chatRoom.chatId
        sendToViewController.completion = { (chatIdNumbers, sentMessages) in
            var selfForwarded = false
            var showSuccess = false
            self.setEditing(false, animated: true)

            chatIdNumbers?.forEach({ (chatIdNumber) in
                let chatId = chatIdNumber.uint64Value
                if chatId == self.chatRoom.chatId {
                    selfForwarded = true
                }
            })
            
            if selfForwarded {
                sentMessages?.forEach({ (message) in
                    let filteredArray = self.messages.filter { chatMessage in
                        guard let localChatMessage = chatMessage as? ChatMessage else {
                            return false
                        }
                        
                        return localChatMessage.message.temporalId == message.temporalId
                    }
                    if filteredArray.count > 0 {
                        MEGALogWarning("Forwarded message was already added to the array, probably onMessageUpdate received before now.")
                    } else {
                        message.chatId = self.chatRoom.chatId
                        self.chatRoomDelegate.insertMessage(message)
                        self.messagesCollectionView.scrollToBottom()
                    }
                    
                })
                
                showSuccess = chatIdNumbers?.count ?? 0 > 1
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
    
    
    @objc func shareSelectedMessages(sender: UIBarButtonItem) {
        SVProgressHUD.show()
        var megaMessages = [MEGAChatMessage]()
        for chatMessage in selectedMessages {
            megaMessages.append(chatMessage.message)
        }
        megaMessages = megaMessages.sorted(by: { (obj1, obj2) -> Bool in
            obj1.messageIndex < obj2.messageIndex
        })
        
        DispatchQueue.global(qos: .default).async {
            guard let activityViewController = Helper.activityViewController(for: megaMessages, sender: sender) else {
                SVProgressHUD.showError(withStatus: AMLocalizedString("linkUnavailable", nil))
                return
            }
            
            DispatchQueue.main.async(execute: {
                SVProgressHUD.dismiss()
                self.present(viewController: activityViewController)
            })
        }
    }
    
    func updateToolbarState() {
        let isEnabled = selectedMessages.count > 0
        forwardBarButtonItem.isEnabled = isEnabled
        shareBarButtonItem.isEnabled = isEnabled
        deleteBarButtonItem.isEnabled = isEnabled
    }
}

