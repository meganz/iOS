import UIKit

class NodeInfoPreviewTableViewCell: UITableViewCell {
    @IBOutlet weak var previewImage: UIImageView!
    @IBOutlet weak var nameLabel: MEGALabel!
    @IBOutlet weak var sizeLabel: MEGALabel!
    @IBOutlet weak var shareStackView: UIStackView!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var previewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var versionedView: UIView!
    @IBOutlet weak var playIconImage: UIImageView!
    @IBOutlet weak var linkedView: UIView!

    func configure(forNode node: MEGANode, isNodeInRubbish: Bool, folderInfo: MEGAFolderInfo?) {
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        nameLabel.text = node.name
        linkedView.isHidden = !node.isExported()
        if (node.type == .file) {
            previewImage.mnz_setThumbnail(by: node)
            sizeLabel.text = Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk())
            shareStackView.isHidden = isNodeInRubbish
            versionedView.isHidden = !MEGASdkManager.sharedMEGASdk().hasVersions(for: node)
            playIconImage.isHidden = node.name?.mnz_isVideoPathExtension != true
        } else if (node.type == .folder) {
            previewImage.mnz_image(for: node)
            let nodeAccess = MEGASdkManager.sharedMEGASdk().accessLevel(for: node)
            shareStackView.isHidden = isNodeInRubbish || (nodeAccess != .accessOwner)
            shareButton.setTitle(Strings.Localizable.CloudDrive.NodeOptions.shareLink.localizedUppercase, for: .normal)
            let folderSize = folderInfo?.currentSize ?? 0
            let versionSize = folderInfo?.versionsSize ?? 0
            let totalSize = folderSize + versionSize
            sizeLabel.text = Helper.memoryStyleString(fromByteCount: totalSize)
        }
        
        shareButton.titleLabel?.font = UIFont.preferredFont(style: .caption1, weight: .bold)
        previewHeightConstraint.constant = node.hasThumbnail() ? 160 : 80
    }
}
