import MEGAAssets
import MEGAChatSdk
import MEGADesignToken
import MEGAL10n
import UIKit

class NodeOwnerInfoTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: MEGALabel!
    @IBOutlet weak var emailLabel: MEGALabel!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var onlineStatusView: RoundedView!
    @IBOutlet weak var contactVerifiedImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupColor()
        contactVerifiedImageView.image = MEGAAssets.UIImage.image(named: "contactVerified")
    }

    private func setupColor() {
        backgroundColor = TokenColors.Background.page
    }
    
    func configure(
        user: MEGAUser,
        shouldDisplayUserVerifiedIcon: Bool
    ) {
        let primaryTextColor = TokenColors.Text.primary
        let secondaryTextColor = TokenColors.Text.secondary
        emailLabel.textColor = primaryTextColor
        emailLabel.text = user.email
        
        let userDisplayName = user.mnz_displayName ?? ""
        nameLabel.attributedText = createOwnerAttributedString(string: Strings.Localizable.CloudDrive.NodeInfo.owner(userDisplayName as Any),
                                                               highligthedString: userDisplayName,
                                                               normalAttributes: [.foregroundColor: secondaryTextColor,
                                                                                  .font: UIFont.preferredFont(style: .body, weight: .bold)],
                                                               highlightedAttributes: [.foregroundColor: primaryTextColor,
                                                                                       .font: UIFont.preferredFont(style: .body, weight: .semibold)])
        
        avatarImageView.mnz_setImage(forUserHandle: user.handle, name: userDisplayName)
        
        onlineStatusView.backgroundColor = UIColor.color(withChatStatus: MEGAChatSdk.shared.userOnlineStatus(user.handle))
        onlineStatusView.layer.cornerRadius = onlineStatusView.frame.height / 2

        contactVerifiedImageView.isHidden = !shouldDisplayUserVerifiedIcon
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
