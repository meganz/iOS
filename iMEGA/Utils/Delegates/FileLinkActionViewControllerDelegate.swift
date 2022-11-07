import Foundation
import MEGADomain

final class FileLinkActionViewControllerDelegate: NSObject, NodeActionViewControllerDelegate {
    
    private weak var viewController: UIViewController?
    private let link: String

    init(link: String, viewController: UIViewController) {
        self.link = link
        self.viewController = viewController
    }
    
    private func download(node: MEGANode) {
        guard let vc = viewController, let linkUrl = URL(string: link) else { return }
        DownloadLinkRouter(link: linkUrl, isFolderLink: false, presenter: vc).start()
    }
    
    func importNode(_ node: MEGANode) {
        guard let vc = viewController else { return }
        
        node.mnz_fileLinkImport(from: vc, isFolderLink: false)
    }
    
    func sendToChat() {
        let storyboard = UIStoryboard(name: "Chat", bundle: Bundle(for: SendToViewController.self))
        if let navController = storyboard.instantiateViewController(withIdentifier: "SendToNavigationControllerID") as? MEGANavigationController,
           let sendToViewController = navController.viewControllers.first as? SendToViewController {
            sendToViewController.sendMode = .fileAndFolderLink
            sendToViewController.sendToViewControllerDelegate = self
            
            viewController?.present(navController, animated: true)
        }
    }
    
    func shareLink() {
        viewController?.present(UIActivityViewController(activityItems: [link], applicationActivities: nil), animated: true, completion: nil)
    }
    
    private func saveToPhotos(node: MEGANode) {
        TransfersWidgetViewController.sharedTransfer().bringProgressToFrontKeyWindowIfNeeded()

        let saveMediaToPhotosUseCase = SaveMediaToPhotosUseCase(downloadFileRepository: DownloadFileRepository(sdk: MEGASdkManager.sharedMEGASdk()), fileCacheRepository: FileCacheRepository.newRepo, nodeRepository: NodeRepository.newRepo)

        saveMediaToPhotosUseCase.saveToPhotos(node: node.toNodeEntity()) { result in
            if case let .failure(error) = result, error != .cancelled {
                SVProgressHUD.dismiss()
                SVProgressHUD.show(Asset.Images.NodeActions.saveToPhotos.image, status: Strings.Localizable.somethingWentWrong)
            }
        }
    }
    
    func nodeAction(_ nodeAction: NodeActionViewController, didSelect action: MegaNodeActionType, for node: MEGANode, from sender: Any) {
        switch action {
        case .download: download(node: node)
        case .import: importNode(node)
        case .sendToChat: sendToChat()
        case .shareLink: shareLink()
        case .saveToPhotos: saveToPhotos(node: node)
        default:
            break
        }
    }
}

extension FileLinkActionViewControllerDelegate: SendToViewControllerDelegate {
    func send(_ viewController: SendToViewController!, toChats chats: [MEGAChatListItem]!, andUsers users: [MEGAUser]!) {
        viewController.dismiss(animated: true, completion: nil)
        
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
