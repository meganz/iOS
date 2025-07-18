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
        configureViewsColor()
    }
    
    // MARK: - Private functions
    
    private func configureViewsColor() {
        contentView.backgroundColor = .clear
        titleLabel.textColor = TokenColors.Text.primary
        subtitleLabel.textColor = TokenColors.Text.secondary
    }
    
    // MARK: - Internal functions
    func configure(item: AudioPlayerItem?) {        
        configureViewsColor()
        
        self.item = item
        
        titleLabel.text = item?.name
        subtitleLabel.text = item?.artist
    }
}
