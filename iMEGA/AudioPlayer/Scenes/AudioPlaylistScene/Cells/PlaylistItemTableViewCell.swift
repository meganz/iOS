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
        } else {
            thumbnailImageView.image = UIImage(named: "defaultArtwork")
        }
        
        thumbnailImageView.layer.cornerRadius = 8.0
    }
}
