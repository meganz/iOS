import MEGAAppSDKRepo
import MEGAAssets
import MEGADesignToken

/// A dedicated subclass used to distinguish the custom reorder image view from the system-provided `UIImageView` inside `UITableViewCell`.
/// This avoids relying on view tags or string identifiers and provides a safer, more maintainable way to manage our custom reorder icon.
private final class CustomReorderIconView: UIImageView {}

final class PlaylistItemTableViewCell: UITableViewCell {
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: MEGALabel!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    private lazy var reorderIconImage = MEGAAssets.UIImage.ellipsis
    private var customReorderIconView: CustomReorderIconView?
    
    var item: AudioPlayerItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureViewsColor()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        thumbnailImageView.image = nil
        customReorderIconView?.removeFromSuperview()
        customReorderIconView = nil
        
        artistLabel.isHidden = true
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        updateReorderControlIcon()
    }
    
    // MARK: - Internal
    
    func configure(item: AudioPlayerItem?) {
        configureViewsColor()
        self.item = item
        titleLabel.text = item?.name
        if let artist = item?.artist {
            artistLabel.text = artist
            artistLabel.isHidden = false
        } else {
            artistLabel.isHidden = true
        }
        configureThumbnail(item)
    }
    
    // MARK: - Private
    
    private func configureViewsColor() {
        titleLabel.textColor = TokenColors.Text.primary
        artistLabel.textColor = TokenColors.Text.secondary
        
        contentView.backgroundColor = TokenColors.Background.page
        contentView.superview?.backgroundColor = TokenColors.Background.page
        
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
                           let file = request.file {
                            self?.thumbnailImageView.image = UIImage(contentsOfFile: file)
                        }
                    })
                }
            } else {
                thumbnailImageView.image = NodeAssetsManager.shared.icon(for: node)
            }
            
        } else {
            thumbnailImageView.image = MEGAAssets.UIImage.image(forFileName: item?.name ?? "")
        }
        
        thumbnailImageView.layer.cornerRadius = 8.0
    }

    private func updateReorderControlIcon() {
        guard showsReorderControl, let reorderClass = NSClassFromString("UITableViewCellReorderControl") else { return }
        
        for subview in self.subviews {
            guard subview.isKind(of: reorderClass) else {
                continue
            }
            
            subview.subviews
                .compactMap { $0 as? UIImageView }
                .filter { !($0 is CustomReorderIconView) }
                .forEach { $0.isHidden = true }
            
            if self.customReorderIconView == nil {
                let icon = self.createCustomReorderIcon()
                self.add(reorderIcon: icon, to: subview)
                self.customReorderIconView = icon
            }
            
            break
        }
    }

    private func createCustomReorderIcon() -> CustomReorderIconView {
        let icon = CustomReorderIconView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = reorderIconImage
        icon.contentMode = .scaleAspectFit
        return icon
    }

    private func add(reorderIcon: CustomReorderIconView, to container: UIView) {
        container.addSubview(reorderIcon)
        NSLayoutConstraint.activate([
            reorderIcon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            reorderIcon.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            reorderIcon.widthAnchor.constraint(equalToConstant: 28),
            reorderIcon.heightAnchor.constraint(equalToConstant: 28)
        ])
    }
}
