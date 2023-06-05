import UIKit

class NodeOwnerInfoTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: MEGALabel!
    @IBOutlet weak var emailLabel: MEGALabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var onlineStatusView: RoundedView!

    func configure(user: MEGAUser) {
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        emailLabel.textColor = UIColor.mnz_label()
        emailLabel.text = user.email
        
        let userDisplayName = user.mnz_displayName ?? ""
        nameLabel.attributedText = createOwnerAttributedString(string: Strings.Localizable.CloudDrive.NodeInfo.owner(userDisplayName as Any),
                                                               highligthedString: userDisplayName,
                                                               normalAttributes: [.foregroundColor: UIColor.mnz_secondaryGray(for: traitCollection),
                                                                                  .font: UIFont.preferredFont(style: .body, weight: .bold)],
                                                               highlightedAttributes: [.foregroundColor: UIColor.mnz_label(),
                                                                                       .font: UIFont.preferredFont(style: .body, weight: .semibold)])
        
        avatarImageView.mnz_setImage(forUserHandle: user.handle, name: userDisplayName)
        
        onlineStatusView.backgroundColor = UIColor.mnz_color(for: MEGASdkManager.sharedMEGAChatSdk().userOnlineStatus(user.handle))
        onlineStatusView.layer.cornerRadius = onlineStatusView.frame.height / 2
    }
    
    func createOwnerAttributedString(string: String,
                                     highligthedString: String,
                                     normalAttributes: [NSAttributedString.Key: Any],
                                     highlightedAttributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        
        let ownerAttributedString = NSMutableAttributedString(string: string, attributes: normalAttributes)
        ownerAttributedString.addAttributes(highlightedAttributes, range: (string as NSString).range(of: highligthedString))
        return ownerAttributedString
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        avatarImageView.image = nil
        nameLabel.text = ""
        emailLabel.text = ""
    }
}
