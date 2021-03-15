import UIKit

final class MiniPlayerItemCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var item: AudioPlayerItem?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    override func prepareForReuse() {
        titleLabel.text = ""
        subtitleLabel.text = ""
    }
    
    func configure(item: AudioPlayerItem?) {
        self.item = item
        
        titleLabel.text = item?.name
        subtitleLabel.text = item?.artist
    }
    
    private func updateAppearance() {
        contentView.backgroundColor = .clear
        
        titleLabel.textColor = UIColor.mnz_label()
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        
        subtitleLabel.textColor = UIColor.mnz_subtitles(for: traitCollection)
        subtitleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
    }
}
