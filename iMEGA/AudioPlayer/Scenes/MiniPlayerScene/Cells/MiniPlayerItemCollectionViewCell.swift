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
    
    // MARK: - Private functions
    private func style(with trait: UITraitCollection) {
        contentView.backgroundColor = .clear
        
        titleLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.label
        subtitleLabel.textColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.mnz_subtitles(for: trait)
    }
    
    // MARK: - Internal functions
    func configure(item: AudioPlayerItem?) {
        style(with: traitCollection)
        
        self.item = item
        
        titleLabel.text = item?.name
        subtitleLabel.text = item?.artist
    }
}
