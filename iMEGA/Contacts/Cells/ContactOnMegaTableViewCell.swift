
import UIKit

protocol ContactOnMegaTableViewCellDelegate: NSObject {
    func addContactCellTapped(_ cell: ContactOnMegaTableViewCell)
}

class ContactOnMegaTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!

    weak var cellDelegate: ContactOnMegaTableViewCellDelegate?

    func configure(for contact: ContactOnMega, delegate: ContactOnMegaTableViewCellDelegate) {
        
        nameLabel.text = contact.name
        emailLabel.text = contact.email
        avatarImageView.mnz_setImage(forUserHandle: contact.handle, name: contact.name)
        addButton.setTitle(AMLocalizedString("addContactButton", "Button title to 'Add' the contact to your contacts list"), for: .normal)
        cellDelegate = delegate
    }
    
    @IBAction func addButtonTouchUpInside(_ sender: Any) {
        if MEGAReachabilityManager.isReachableHUDIfNot() {
            let inviteContactRequestDelegate = MEGAInviteContactRequestDelegate.init(numberOfRequests: 1, presentSuccessOver: UIApplication.mnz_visibleViewController()) {
                self.cellDelegate?.addContactCellTapped(self)
            }
            guard let email = emailLabel.text else { return }
            MEGASdkManager.sharedMEGASdk().inviteContact(withEmail: email, message: "", action: MEGAInviteAction.add, delegate: inviteContactRequestDelegate)
        }
    }
}
