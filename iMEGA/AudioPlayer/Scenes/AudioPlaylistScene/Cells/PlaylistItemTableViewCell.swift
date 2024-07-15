import MEGADesignToken
import MEGADomain
import MEGASDKRepo
import MEGASwiftUI
import SwiftUI
import UIKit

final class PlaylistItemTableViewCell: UITableViewCell {
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: MEGALabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    var item: AudioPlayerItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        registerForTraitChanges()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        thumbnailImageView.image = nil
    }
    
    // MARK: - Private functions
    private func style(with trait: UITraitCollection) {
        configureViewsColor(trait: trait)
    }
    
    private func registerForTraitChanges() {
        guard #available(iOS 17.0, *) else { return }
        registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { [weak self] (cell: PlaylistItemTableViewCell, previousTraitCollection: UITraitCollection) in
            self?.handleTraitCollectionChange(previousTraitCollection, newestTraitCollection: cell.traitCollection)
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17.0) {
            guard let previousTraitCollection else { return }
            handleTraitCollectionChange(previousTraitCollection, newestTraitCollection: traitCollection)
        }
    }
    
    private func handleTraitCollectionChange(_ previousTraitCollection: UITraitCollection, newestTraitCollection: UITraitCollection) {
        if newestTraitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle {
            configureViewsColor(trait: newestTraitCollection)
        }
    }
    
    private func configureViewsColor(trait: UITraitCollection) {
        if UIColor.isDesignTokenEnabled() {
            titleLabel.textColor = TokenColors.Text.primary
            artistLabel.textColor = TokenColors.Text.secondary
            
            contentView.backgroundColor = TokenColors.Background.page
            contentView.superview?.backgroundColor = TokenColors.Background.page
        } else {
            titleLabel.textColor = UIColor.label
            artistLabel.textColor = UIColor.mnz_subtitles(for: trait)
        }
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
            thumbnailImageView.image = UIImage(resource: .defaultArtwork)
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
