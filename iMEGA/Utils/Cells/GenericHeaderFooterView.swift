
import UIKit

class GenericHeaderFooterView: UITableViewHeaderFooterView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var bottomSeparatorView: UIView!
    @IBOutlet weak var backgroundColorView: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        updateAppearance()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        updateAppearance()
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
        if (self.contentView.backgroundColor != nil) {
            self.contentView.backgroundColor = UIColor.mnz_tertiaryBackground(self.traitCollection)
        }
        
        self.titleLabel.textColor = UIColor.mnz_secondaryGray(for: self.traitCollection)
        
        self.topSeparatorView.backgroundColor = UIColor.mnz_separatorColor(for: self.traitCollection)
        self.bottomSeparatorView.backgroundColor = UIColor .mnz_separatorColor(for: self.traitCollection)
    }
}
