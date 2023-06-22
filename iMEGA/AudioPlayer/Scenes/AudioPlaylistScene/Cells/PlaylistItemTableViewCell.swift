import MEGADomain
import UIKit

final class PlaylistItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: MEGALabel!
    @IBOutlet weak var artistLabel: UILabel!

    var item: AudioPlayerItem?
 
    override func prepareForReuse() {
        super.prepareForReuse()
        
        thumbnailImageView.image = nil
    }
    
    // MARK: - Private functions
    private func style(with trait: UITraitCollection) {
        titleLabel.textColor = UIColor.mnz_label()
        artistLabel.textColor = UIColor.mnz_subtitles(for: trait)
    }
    
    private func configureThumbnail(_ item: AudioPlayerItem?) {
        if let image = item?.artwork {
            thumbnailImageView.image = image
        } else if let node = item?.node {
            if node.hasThumbnail() {
                let thumbnailFilePath = Helper.path(for: node, inSharedSandboxCacheDirectory: "thumbnailsV3")
                if FileManager.default.fileExists(atPath: thumbnailFilePath) {
                    thumbnailImageView.image = UIImage(contentsOfFile: thumbnailFilePath)
                } else {
                    MEGASdkManager.sharedMEGASdk().getThumbnailNode(node, destinationFilePath: thumbnailFilePath, delegate: MEGAGenericRequestDelegate { [weak self] request, error in
                        if request.nodeHandle == node.handle && error.type == .apiOk {
                            self?.thumbnailImageView.image = UIImage(contentsOfFile: request.file)
                        }
                    })
                }
            } else {
                thumbnailImageView.image = NodeAssetsManager.shared.icon(for: node)
            }
            
        } else {
            thumbnailImageView.image = Asset.Images.AudioPlayer.defaultArtwork.image
        }
        
        thumbnailImageView.layer.cornerRadius = 8.0
    }
    
    // MARK: - Internal functions
    func configure(item: AudioPlayerItem?) {
        style(with: traitCollection)
        
        self.item = item
        titleLabel.text = item?.name
        artistLabel.text = item?.artist ?? ""
        
        configureThumbnail(item)
    }
}
