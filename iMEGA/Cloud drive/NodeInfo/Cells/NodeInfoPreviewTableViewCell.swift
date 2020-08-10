import UIKit

class NodeInfoPreviewTableViewCell: UITableViewCell {
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var previewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var versionedImage: UIImageView!
    @IBOutlet weak var playIconImage: UIImageView!

    func configure(forNode node: MEGANode) {
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        nameLabel.text = node.name;
        if (node.type == .file) {
            previewImage.mnz_setThumbnail(by: node)
            sizeLabel.text = Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk())
            shareButton.isHidden = true
            versionedImage.isHidden = !MEGASdkManager.sharedMEGASdk().hasVersions(for: node)
            playIconImage.isHidden = !node.name.mnz_isVideoPathExtension
        } else if (node.type == .folder) {
            previewImage.mnz_image(for: node)
            sizeLabel.text = Helper.filesAndFolders(inFolderNode: node, api: MEGASdkManager.sharedMEGASdk())
        }
        
        previewHeightConstraint.constant = node.hasThumbnail() ? 160 : 80
    }
}
