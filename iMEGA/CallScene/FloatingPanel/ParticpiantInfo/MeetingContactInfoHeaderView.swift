import MEGAAssets
import UIKit

class MeetingContactInfoHeaderView: UIView {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        avatarImageView.image = MEGAAssets.UIImage.image(named: "icon-contacts")
    }
}
