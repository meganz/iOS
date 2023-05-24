import UIKit
import MEGADomain

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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        viewModel = nil
    }
    
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
    
    @MainActor
    private func executeCommand(_ command: GetLinkAlbumInfoCellViewModel.Command) {
        switch command {
        case .setThumbnail(let imagePath):
            guard let image = UIImage(contentsOfFile: imagePath) else { return }
            thumbnailImageView.image = image
        case .setPlaceholderThumbnail:
            thumbnailImageView.image = Asset.Images.Album.placeholder.image
        case .setLabels(let title, let subtitle):
            nameLabel.text = title
            subtitleLabel.text = subtitle
        }
    }
}
