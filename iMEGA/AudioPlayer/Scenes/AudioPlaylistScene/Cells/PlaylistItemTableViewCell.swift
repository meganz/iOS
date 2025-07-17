import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken
import MEGADomain
import MEGASwiftUI
import SwiftUI
import UIKit

final class PlaylistItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: MEGALabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    var item: AudioPlayerItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureViewsColor()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        thumbnailImageView.image = nil
    }
    
    // MARK: - Private functions
    
    private func configureViewsColor() {
        titleLabel.textColor = TokenColors.Text.primary
        artistLabel.textColor = TokenColors.Text.secondary
        
        contentView.backgroundColor = TokenColors.Background.page
        contentView.superview?.backgroundColor = TokenColors.Background.page
        
        tintColor = TokenColors.Components.selectionControl
        
        separatorView.backgroundColor = TokenColors.Border.strong
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
                    MEGASdk.shared.getThumbnailNode(node, destinationFilePath: thumbnailFilePath, delegate: RequestDelegate { [weak self] result in
                        if case let .success(request) = result,
                           request.nodeHandle == node.handle,
                           let  file = request.file {
                            self?.thumbnailImageView.image = UIImage(contentsOfFile: file)
                        }
                    })
                }
            } else {
                thumbnailImageView.image = NodeAssetsManager.shared.icon(for: node)
            }
            
        } else {
            thumbnailImageView.image = MEGAAssets.UIImage.defaultArtwork
        }
        
        thumbnailImageView.layer.cornerRadius = 8.0
    }
    
    // MARK: - Internal functions
    func configure(item: AudioPlayerItem?) {
        configureViewsColor()
        
        self.item = item
        titleLabel.text = item?.name
        artistLabel.text = item?.artist ?? ""
        
        configureThumbnail(item)
    }
}
