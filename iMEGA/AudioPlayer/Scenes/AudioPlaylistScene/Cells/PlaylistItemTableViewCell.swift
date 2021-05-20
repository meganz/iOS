import UIKit

final class PlaylistItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!

    var item: AudioPlayerItem?
 
    override func prepareForReuse() {
        super.prepareForReuse()
        
        thumbnailImageView.image = nil
    }
    
    // MARK: - Public functions
    func configure(item: AudioPlayerItem?) {
        self.item = item
        titleLabel.text = item?.name
        artistLabel.text = item?.artist ?? ""
        
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
                thumbnailImageView.mnz_image(for: node)
            }
           
        } else {
            thumbnailImageView.image = UIImage(named: "defaultArtwork")
        }
        
        thumbnailImageView.layer.cornerRadius = 8.0
    }
}
