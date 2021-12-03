import UIKit

class GetLinkStringTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var leftImageView: UIImageView!
    @IBOutlet weak var rightImageView: UIImageView!

    func configureLinkCell(link: String) {
        nameLabel.text = link
        leftImageView.image = Asset.Images.GetLinkView.linkGetLink.image
        rightImageView.isHidden = true
    }
    
    func configureKeyCell(key: String) {
        nameLabel.text = key
        leftImageView.image = Asset.Images.Generic.iconKeyOnly.image
        rightImageView.isHidden = true
    }
}
