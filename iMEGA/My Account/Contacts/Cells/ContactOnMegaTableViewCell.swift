import UIKit

protocol ContactOnMegaTableViewCellDelegate: NSObject {
    func addContactCellTapped(_ cell: ContactOnMegaTableViewCell)
}

class ContactOnMegaTableViewCell: UITableViewCell {

    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!

    weak var cellDelegate: (any ContactOnMegaTableViewCellDelegate)?

    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateAppearance()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        updateAppearance()
    }
    
    private func updateAppearance() {
        backgroundColor = .mnz_secondaryBackgroundGrouped(traitCollection)
        
        emailLabel.textColor = UIColor.mnz_subtitles(for: traitCollection)
        addButton.setTitleColor(UIColor.mnz_turquoise(for: traitCollection), for: .normal)
    }

    func configure(for contact: ContactOnMega, delegate: some ContactOnMegaTableViewCellDelegate) {
        nameLabel.text = contact.name
        emailLabel.text = contact.email
        avatarImageView.mnz_setImage(forUserHandle: contact.handle, name: contact.name)
        addButton.setTitle(Strings.Localizable.addContactButton, for: .normal)
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
