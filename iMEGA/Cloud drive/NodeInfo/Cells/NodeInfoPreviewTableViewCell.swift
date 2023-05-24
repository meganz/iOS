import UIKit
import MEGADomain

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

    func configure(forNode node: MEGANode, isNodeInRubbish: Bool, folderInfo: MEGAFolderInfo?, isUndecryptedFolder: Bool) {
        backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
        nameLabel.text = isUndecryptedFolder ? Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName : node.name
        linkedView.isHidden = !node.isExported()
        if node.type == .file {
            previewImage.mnz_setThumbnail(by: node)
            sizeLabel.text = Helper.size(for: node, api: MEGASdkManager.sharedMEGASdk())
            shareStackView.isHidden = true
            versionedView.isHidden = !MEGASdkManager.sharedMEGASdk().hasVersions(for: node)
            playIconImage.isHidden = node.name?.mnz_isVideoPathExtension != true
        } else if node.type == .folder {
            previewImage.image = NodeAssetsManager.shared.icon(for: node)
            let nodeAccess = MEGASdkManager.sharedMEGASdk().accessLevel(for: node)
            shareStackView.isHidden = isNodeInRubbish || (nodeAccess != .accessOwner)
            shareButton.setTitle(Strings.Localizable.General.share.localizedUppercase, for: .normal)
            let folderSize = folderInfo?.currentSize ?? 0
            let versionSize = folderInfo?.versionsSize ?? 0
            let totalSize = folderSize + versionSize
            sizeLabel.text = String.memoryStyleString(fromByteCount: totalSize)
        }
        
        shareButton.titleLabel?.font = UIFont.preferredFont(style: .caption1, weight: .bold)
        previewHeightConstraint.constant = node.hasThumbnail() ? 160 : 80
    }
}
