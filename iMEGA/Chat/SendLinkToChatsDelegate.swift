import MEGAL10n

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
            MEGAChatSdk.shared.sendMessage(toChat: $0.chatId, message: link)
        }
        
        users.forEach {
            let chatRoom = MEGAChatSdk.shared.chatRoom(byUser: $0.handle)
            if chatRoom != nil {
                guard let chatId = chatRoom?.chatId else {
                    return
                }
                MEGAChatSdk.shared.sendMessage(toChat: chatId, message: link)
            } else {
                MEGALogDebug("There is not a chat with %@, create the chat and send message", $0.email ?? "No user email")
                MEGAChatSdk.shared.mnz_createChatRoom(userHandle: $0.handle, completion: {
                    MEGAChatSdk.shared.sendMessage(toChat: $0.chatId, message: self.link)
                })
            }
        }
        
        let totalCount = chats.count + users.count
        let message = totalCount == 1 ?
            Strings.Localizable.Chat.Message.filesSentToAChat(1) :
            Strings.Localizable.Chat.Message.fileSentToMultipleChats(totalCount)
        
        SVProgressHUD.showSuccess(withStatus: message)
    }
}
