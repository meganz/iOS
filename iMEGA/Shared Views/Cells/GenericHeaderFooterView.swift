
import UIKit

final class GenericHeaderFooterView: UITableViewHeaderFooterView {
    @IBOutlet weak var topSeparatorView: UIView!
    @IBOutlet weak var marginView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bottomSeparatorView: UIView!
    @IBOutlet weak var marginViewHeightConstraint: NSLayoutConstraint!
    
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
    
    @objc func configure(title: String?, topDistance: CGFloat, isTopSeparatorVisible: Bool, isBottomSeparatorVisible: Bool) {
        configure(topDistance: topDistance, isTopSeparatorVisible: isTopSeparatorVisible, isBottomSeparatorVisible: isBottomSeparatorVisible)
        
        guard let title = title else {
            titleLabel.isHidden = true
            return
        }
        titleLabel.isHidden = false
        marginView.isHidden = false
        titleLabel.text = title
    }
    
    @objc func configure(attributedTitle: NSAttributedString, topDistance: CGFloat, isTopSeparatorVisible: Bool, isBottomSeparatorVisible: Bool) {
        configure(topDistance: topDistance, isTopSeparatorVisible: isTopSeparatorVisible, isBottomSeparatorVisible: isBottomSeparatorVisible)
        
        titleLabel.attributedText = attributedTitle
    }
    
    //MARK: - Private
    private func configure(topDistance: CGFloat, isTopSeparatorVisible: Bool, isBottomSeparatorVisible: Bool) {
        if topDistance == 0 {
            marginView.isHidden = true
        } else {
            marginView.isHidden = false
            marginViewHeightConstraint.constant = topDistance
        }
        
        topSeparatorView.isHidden = !isTopSeparatorVisible
        bottomSeparatorView.isHidden = !isBottomSeparatorVisible
    }
    
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
