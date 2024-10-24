import MEGADesignToken
import MEGADomain
import UIKit

class GetLinkInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    var viewModel: GetLinkAlbumInfoCellViewModel? {
        didSet {
            viewModel?.invokeCommand = { [weak self] in
                self?.executeCommand($0)
            }
            viewModel?.dispatch(.onViewReady)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.textColor = TokenColors.Text.primary
        subtitleLabel.textColor = TokenColors.Text.secondary
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel?.dispatch(.cancelTasks)
        viewModel = nil
    }
    
    func configure(forNode node: MEGANode) {
        nameLabel.text = node.name
        if node.isFile() {
            thumbnailImageView.mnz_setThumbnail(by: node)
            subtitleLabel.text = Helper.size(for: node, api: MEGASdk.shared)
        } else {
            thumbnailImageView.image = NodeAssetsManager.shared.icon(for: node)
            subtitleLabel.text = Helper.filesAndFolders(inFolderNode: node, api: MEGASdk.shared)
        }
    }
    
    @MainActor
    private func executeCommand(_ command: GetLinkAlbumInfoCellViewModel.Command) {
        switch command {
        case .setThumbnail(let imagePath):
            guard let image = UIImage(contentsOfFile: imagePath) else { return }
            thumbnailImageView.image = image
        case .setPlaceholderThumbnail:
            thumbnailImageView.image = UIImage.placeholder
        case .setLabels(let title, let subtitle):
            nameLabel.text = title
            subtitleLabel.text = subtitle
        }
    }
}
