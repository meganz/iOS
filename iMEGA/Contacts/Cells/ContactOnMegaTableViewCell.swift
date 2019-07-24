
import UIKit

class ContactOnMegaTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!

    func configure(for contact: ContactOnMega) {
        
        nameLabel.text = contact.name
        emailLabel.text = contact.email
        avatarImageView.mnz_setImage(forUserHandle: contact.handle, name: contact.name)
        addButton.setTitle(NSLocalizedString("addContactButton", comment: "Button title to 'Add' the contact to your contacts list"), for: .normal)
    }
    
    @IBAction func addButtonTouchUpInside(_ sender: Any) {
        let inviteContactRequestDelegate = MEGAInviteContactRequestDelegate.init(numberOfRequests: 1)
        MEGASdkManager.sharedMEGASdk().inviteContact(withEmail: emailLabel.text, message: "", action: MEGAInviteAction.add, delegate: inviteContactRequestDelegate)
    }
}
