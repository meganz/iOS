import UIKit

final class PlaylistHeaderFooterView: UITableViewHeaderFooterView {

    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var separatorView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateAppearance()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        updateAppearance()
    }
    
    func configure(title: String) {
        typeLabel.text = title
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if #available(iOS 13, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                updateAppearance()
            }
        }
    }
    
    //MARK: - Private
    private func updateAppearance() {
        contentView.backgroundColor = .mnz_backgroundElevated(traitCollection)
        
        typeLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        typeLabel.textColor = .mnz_green00A886()
        
        separatorView.backgroundColor = UIColor.mnz_gray3C3C43().withAlphaComponent(0.29)
    }
}
