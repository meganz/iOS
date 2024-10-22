import MEGADesignToken
import UIKit

class GeoLocationView: UIView {

    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        updateAppearance()
    }
    
    private func updateAppearance () {
        backgroundColor = .mnz_chatRichLinkContentBubble(traitCollection)
        titleLabel.textColor = UIColor.label
        subtitleLabel.textColor = TokenColors.Text.secondary
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateAppearance()
    }
}
