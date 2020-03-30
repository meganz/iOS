
import Foundation

extension ChatViewController {
    
    func configureNavigationBar() {
        let titleView = ChatTitleView.instanceFromNib
        titleView.chatRoom = chatRoom
        titleView.tapHandler = { [weak self] in
            print("Handle tap")
            
            guard let `self` = self else {
                return
            }
            
            self.didTapTitle()
        }
        navigationItem.titleView = titleView
    }
    
    private func didTapTitle() {
        if chatRoom.isGroup {
            pushGroupDetailsViewController()
        } else {
            pushContactDetailsViewController()
        }
    }
    
    private func pushGroupDetailsViewController() {
        let storyboard = UIStoryboard(name: "Chat", bundle: nil)
        if let groupDetailsViewController = storyboard.instantiateViewController(withIdentifier:"GroupChatDetailsViewControllerID") as? GroupChatDetailsViewController {
            groupDetailsViewController.chatRoom = chatRoom
            navigationController?.pushViewController(groupDetailsViewController, animated: true)
        } else {
            MEGALogError("ChatViewController: Could not GroupChatDetailsViewController")
        }
    }
    
    private func pushContactDetailsViewController() {
        let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
        if let contactDetailsViewController = storyboard.instantiateViewController(withIdentifier:"ContactDetailsViewControllerID") as? ContactDetailsViewController {
            let peerHandle = chatRoom.peerHandle(at: 0)
            let peerEmail = MEGASdkManager.sharedMEGAChatSdk()?.contacEmail(byHandle: peerHandle)

            contactDetailsViewController.contactDetailsMode = .fromChat
            contactDetailsViewController.userEmail = peerEmail
            contactDetailsViewController.userHandle = peerHandle
            navigationController?.pushViewController(contactDetailsViewController, animated: true)
        } else {
            MEGALogError("ChatViewController: Could not ContactDetailsViewControllerID")
        }
    }
    
}
