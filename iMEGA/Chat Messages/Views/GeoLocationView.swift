import MEGADesignToken
import UIKit

class GeoLocationView: UIView {

    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            updateAppearance()
            registerForAppearanceChanges()
        }
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) { (view: GeoLocationView, _: UITraitCollection) in
            view.updateAppearance()
        }
    }

    private func updateAppearance () {
        backgroundColor = .mnz_chatRichLinkContentBubble(traitCollection)
        titleLabel.textColor = UIColor.label
        subtitleLabel.textColor = TokenColors.Text.secondary
    }
}
