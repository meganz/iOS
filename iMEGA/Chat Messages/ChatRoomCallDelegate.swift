import UIKit

class ChatRoomCallDelegate: NSObject, MEGAChatCallDelegate {

    // MARK: - Properties

    let chatRoom: MEGAChatRoom
    weak var chatViewController: ChatViewController!
    
    // MARK: - Init

    init(chatRoom: MEGAChatRoom, chatViewController: ChatViewController) {
        self.chatRoom = chatRoom
        self.chatViewController = chatViewController
        super.init()
        
        MEGASdkManager.sharedMEGAChatSdk()?.add(self)
    }
        
    // MARK: - MEGAChatCallDelegate methods

}
