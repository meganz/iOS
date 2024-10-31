import MEGADesignToken
import UIKit

final class CustomTitleView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: CGFloat.greatestFiniteMagnitude,
                      height: super.intrinsicContentSize.height)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    private func updateAppearance() {
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textColor = TokenColors.Text.primary
        
        subtitleLabel.font = UIFont.systemFont(ofSize: 12)
        subtitleLabel.textColor = TokenColors.Text.secondary
    }
}
