import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGAL10n
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
    @IBOutlet weak var linkedImageView: UIImageView!
    @IBOutlet weak var versionedImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupColors()
        configureImages()
    }
    
    private func configureImages() {
        playIconImage.image = MEGAAssets.UIImage.image(named: "video_list")
        linkedImageView.image = MEGAAssets.UIImage.image(named: "linked")
        versionedImageView.image = MEGAAssets.UIImage.image(named: "versioned")
    }
    
    private func setupColors() {
        backgroundColor = TokenColors.Background.page
        nameLabel.textColor = TokenColors.Text.primary
        sizeLabel.textColor = TokenColors.Text.primary
        shareButton.backgroundColor = TokenColors.Button.primary
        shareButton.setTitleColor(TokenColors.Text.inverse, for: UIControl.State.normal)
    }
    
    func configure(forNode node: MEGANode, isNodeInRubbish: Bool, folderInfo: MEGAFolderInfo?, isUndecryptedFolder: Bool) {
        nameLabel.text = isUndecryptedFolder ? Strings.Localizable.SharedItems.Tab.Incoming.undecryptedFolderName : node.name
        linkedView.isHidden = !node.isExported()
        if node.type == .file {
            previewImage.mnz_setThumbnail(by: node)
            sizeLabel.text = Helper.size(for: node, api: MEGASdk.shared)
            shareStackView.isHidden = true
            versionedView.isHidden = !MEGASdk.shared.hasVersions(for: node)
            playIconImage.isHidden = node.name?.fileExtensionGroup.isVideo != true
        } else if node.type == .folder {
            previewImage.image = NodeAssetsManager.shared.icon(for: node)
            let nodeAccess = MEGASdk.shared.accessLevel(for: node)
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
