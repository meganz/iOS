
class SendLinkToChatsDelegate: NSObject {

    var openedChatIds = Set<NSNumber>()
    var sendToCount = NSInteger()
    var sendToTotal = NSInteger()
    let link: String
    let navigationController: UINavigationController?
    
    @objc init(link: String, navigationController: UINavigationController?) {
        self.link = link
        self.navigationController = navigationController
        super.init()
    }
    
    private func send(message: String, toChatId chatId: UInt64) {
        if !openedChatIds.contains(NSNumber(value: chatId)) {
            MEGASdkManager.sharedMEGAChatSdk()?.openChatRoom(chatId, delegate: self)
            openedChatIds.insert(NSNumber(value: chatId))
        }
        MEGASdkManager.sharedMEGAChatSdk()?.sendMessage(toChat: chatId, message: message)
    }
}

extension SendLinkToChatsDelegate: SendToViewControllerDelegate {
    func send(_ viewController: SendToViewController!, toChats chats: [MEGAChatListItem]!, andUsers users: [MEGAUser]!) {
        if (navigationController != nil) {
            navigationController?.popViewController(animated: true)
        } else {
            viewController.dismiss(animated: true, completion: nil)
        }
        
        openedChatIds.removeAll()
        sendToTotal = chats.count + users.count
        sendToCount = 0
        
        chats.forEach {
            send(message: link, toChatId: $0.chatId)
        }
        
        users.forEach {
            let chatRoom = MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(byUser: $0.handle)
            if (chatRoom != nil) {
                guard let chatId = chatRoom?.chatId else {
                    return
                }
                send(message: link, toChatId: chatId)
            } else {
                MEGALogDebug("There is not a chat with %@, create the chat and send message", $0.email)
                MEGASdkManager.sharedMEGAChatSdk()?.mnz_createChatRoom(userHandle: $0.handle, completion: {
                    self.send(message: self.link, toChatId: $0.chatId)
                })
            }
        }
    }
}

extension SendLinkToChatsDelegate: MEGAChatRoomDelegate {
    func onMessageUpdate(_ api: MEGAChatSdk!, message: MEGAChatMessage!) {
        if message.hasChanged(for: .status) {
            if message.status == .serverReceived {
                sendToCount += 1
                if sendToCount == sendToTotal {
                    openedChatIds.forEach {
                        MEGASdkManager.sharedMEGAChatSdk()?.closeChatRoom($0.uint64Value, delegate: self)
                    }
                    let message = sendToTotal == 1 ? AMLocalizedString("fileSentToChat", "Toast text upon sending a single file to chat") : String(format: AMLocalizedString("fileSentToXChats", "Success message when the attachment has been sent to a many chats"), sendToTotal)
                    SVProgressHUD.showSuccess(withStatus: message)
                }
            }
        }
    }
}
