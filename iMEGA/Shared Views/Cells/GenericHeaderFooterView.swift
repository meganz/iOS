
import UIKit

class GenericHeaderFooterView: UITableViewHeaderFooterView {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var bottomSeparatorView: UIView!
    @IBOutlet weak var backgroundColorView: UIView!
    @IBOutlet weak var titleLabelTopDistanceConstraint: NSLayoutConstraint!
    
    private var usingDefaultBackgroundColor: Bool = false
    
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
        
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    //MARK: - Private
    
    private func updateAppearance() {
        if self.contentView.backgroundColor != nil && !usingDefaultBackgroundColor {
            self.contentView.backgroundColor = .mnz_backgroundGroupedElevated(traitCollection)
        } else {
            self.contentView.backgroundColor = .mnz_backgroundGrouped(for: traitCollection)
            usingDefaultBackgroundColor = true
        }
        
        self.titleLabel.textColor = UIColor.mnz_secondaryGray(for: self.traitCollection)
        
        self.topSeparatorView.backgroundColor = UIColor.mnz_separator(for: self.traitCollection)
        self.bottomSeparatorView.backgroundColor = UIColor .mnz_separator(for: self.traitCollection)
    }
}
