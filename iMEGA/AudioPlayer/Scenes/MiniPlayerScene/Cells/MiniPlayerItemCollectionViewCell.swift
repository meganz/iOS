import MEGADesignToken
import UIKit

final class MiniPlayerItemCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: MEGALabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var item: AudioPlayerItem?
    
    override func prepareForReuse() {
        titleLabel.text = ""
        subtitleLabel.text = ""
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        registerForTraitChanges()
    }
    
    // MARK: - Private functions
    private func style(with trait: UITraitCollection) {
        configureViewsColor(trait: trait)
    }
    
    private func registerForTraitChanges() {
        guard #available(iOS 17.0, *) else { return }
        registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { [weak self] (cell: MiniPlayerItemCollectionViewCell, previousTraitCollection: UITraitCollection) in
            if cell.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle {
                self?.configureViewsColor(trait: cell.traitCollection)
            }
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17.0), traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            configureViewsColor(trait: traitCollection)
        }
    }
    
    private func configureViewsColor(trait: UITraitCollection) {
        contentView.backgroundColor = .clear
        titleLabel.textColor = TokenColors.Text.primary
        subtitleLabel.textColor = TokenColors.Text.primary
    }
    
    // MARK: - Internal functions
    func configure(item: AudioPlayerItem?) {
        style(with: traitCollection)
        
        self.item = item
        
        titleLabel.text = item?.name
        subtitleLabel.text = item?.artist
    }
}
