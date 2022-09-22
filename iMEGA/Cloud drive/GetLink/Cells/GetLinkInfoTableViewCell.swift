import UIKit
import MEGADomain

class GetLinkInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    func configure(forNode node: MEGANode) {
        nameLabel.text = node.name
        if node.isFile() {
            thumbnailImageView.mnz_setThumbnail(by: node)
            subtitleLabel.text = Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk())
        } else {
            thumbnailImageView.image = NodeAssetsManager.shared.icon(for: node)
            subtitleLabel.text = Helper.filesAndFolders(inFolderNode: node, api: MEGASdkManager.sharedMEGASdk())
        }
    }
}
