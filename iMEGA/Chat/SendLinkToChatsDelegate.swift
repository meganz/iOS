
class SendLinkToChatsDelegate: NSObject {

    private let link: String
    private let navigationController: UINavigationController?
    
    @objc init(link: String, navigationController: UINavigationController?) {
        self.link = link
        self.navigationController = navigationController
        super.init()
    }
}

extension SendLinkToChatsDelegate: SendToViewControllerDelegate {
    func send(_ viewController: SendToViewController!, toChats chats: [MEGAChatListItem]!, andUsers users: [MEGAUser]!) {
        if navigationController?.viewControllers.first?.isKind(of: FolderLinkViewController.self) == true {
            navigationController?.popViewController(animated: true)
        } else {
            viewController.dismiss(animated: true, completion: nil)
        }
        
        chats.forEach {
            MEGASdkManager.sharedMEGAChatSdk().sendMessage(toChat: $0.chatId, message: link)
        }
        
        users.forEach {
            let chatRoom = MEGASdkManager.sharedMEGAChatSdk().chatRoom(byUser: $0.handle)
            if (chatRoom != nil) {
                guard let chatId = chatRoom?.chatId else {
                    return
                }
                MEGASdkManager.sharedMEGAChatSdk().sendMessage(toChat: chatId, message: link)
            } else {
                MEGALogDebug("There is not a chat with %@, create the chat and send message", $0.email)
                MEGASdkManager.sharedMEGAChatSdk().mnz_createChatRoom(userHandle: $0.handle, completion: {
                    MEGASdkManager.sharedMEGAChatSdk().sendMessage(toChat: $0.chatId, message: self.link)
                })
            }
        }
        
        let totalCount = chats.count + users.count
        let message = totalCount == 1 ? Strings.Localizable.fileSentToChat : Strings.Localizable.fileSentToXChats(totalCount)
        
        SVProgressHUD.showSuccess(withStatus: message)
    }
}
