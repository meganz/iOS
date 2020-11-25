import UIKit

class NodeInfoPreviewTableViewCell: UITableViewCell {
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var previewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var versionedImage: UIImageView!
    @IBOutlet weak var playIconImage: UIImageView!
    @IBOutlet weak var linkedImage: UIImageView!

    func configure(forNode node: MEGANode, folderInfo: MEGAFolderInfo?) {
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        nameLabel.text = node.name
        linkedImage.isHidden = !node.isExported()
        if (node.type == .file) {
            previewImage.mnz_setThumbnail(by: node)
            sizeLabel.text = Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk())
            shareButton.isHidden = true
            versionedImage.isHidden = !MEGASdkManager.sharedMEGASdk().hasVersions(for: node)
            playIconImage.isHidden = !node.name.mnz_isVideoPathExtension
        } else if (node.type == .folder) {
            previewImage.mnz_image(for: node)
            let nodeAccess = MEGASdkManager.sharedMEGASdk().accessLevel(for: node)
            shareButton.isHidden = nodeAccess != .accessOwner
            shareButton.setTitle(AMLocalizedString("SHARE", "Title for the share button in the folder information view. Tapping the button will start the flow for sharing a folder"), for: .normal)
            sizeLabel.text = Helper.memoryStyleString(fromByteCount: (folderInfo?.currentSize ?? 0) + (folderInfo?.versionsSize ?? 0))
        }
        
        previewHeightConstraint.constant = node.hasThumbnail() ? 160 : 80
    }
}
