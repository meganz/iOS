
import MEGAData
import UIKit

class ContactsGroupTableViewCell: UITableViewCell {

    @IBOutlet weak var backAvatarImage: UIImageView!
    @IBOutlet weak var frontAvatarImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var keyRotationImage: UIImageView!
    
    func configure(for chatListItem: MEGAChatListItem) {
        titleLabel.text = chatListItem.chatTitle()
        keyRotationImage.isHidden = chatListItem.isPublicChat
        
        guard let chatRoom = MEGASdkManager.sharedMEGAChatSdk().chatRoom(forChatId: chatListItem.chatId) else {
            return
        }
        backAvatarImage.mnz_setImage(forUserHandle: chatRoom.peerHandle(at: 0))
        let handle = chatRoom.peerCount > 1 ? chatRoom.peerHandle(at: 1) : MEGASdk.currentUserHandle()?.uint64Value ?? MEGAInvalidHandle
        frontAvatarImage.mnz_setImage(forUserHandle: handle)
        frontAvatarImage.borderColor = .mnz_backgroundElevated(traitCollection)
    }
}
