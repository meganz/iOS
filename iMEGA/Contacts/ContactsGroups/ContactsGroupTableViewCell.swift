
import UIKit

class ContactsGroupTableViewCell: UITableViewCell {

    @IBOutlet weak var backAvatarImage: UIImageView!
    @IBOutlet weak var frontAvatarImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var keyRotationImage: UIImageView!
    
    func configure(for chatListItem: MEGAChatListItem) {
        titleLabel.text = chatListItem.chatTitle()
        keyRotationImage.isHidden = chatListItem.isPublicChat
        
        guard let chatRoom = MEGASdkManager.sharedMEGAChatSdk()?.chatRoom(forChatId: chatListItem.chatId) else {
            return
        }
        backAvatarImage.mnz_setImage(forUserHandle: chatRoom.peerHandle(at: 0))
        frontAvatarImage.mnz_setImage(forUserHandle: chatRoom.peerHandle(at: 1))
        frontAvatarImage.borderColor = .mnz_backgroundElevated(traitCollection)
    }
}
