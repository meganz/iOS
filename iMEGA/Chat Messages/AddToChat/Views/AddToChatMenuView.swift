import MEGAAssets
import MEGADesignToken
import MEGAL10n
import UIKit

class AddToChatMenuView: UIView {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageBackgroundView: UIView!
    @IBOutlet weak var label: UILabel!
    
    var disabled: Bool = false
    
    var menu: AddToChatMenu? {
        didSet {
            guard let menu = menu else {
                imageView.image = nil
                label.text = nil
                imageBackgroundView.isHidden = true
                return
            }
            
            imageView.image = MEGAAssets.UIImage.image(named: menu.imageKey)
            label.text = Strings.localized(menu.nameKey, comment: "")
            imageBackgroundView.isHidden = false
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        MainActor.assumeIsolated {
            updateAppearance()
            registerForAppearanceChanges()
        }
    }

    private func registerForAppearanceChanges() {
        registerForTraitChanges(UITraitCollection.systemTraitsAffectingColorAppearance) { (view: AddToChatMenuView, _: UITraitCollection) in
            view.updateAppearance()
        }
    }

    func disable(_ disable: Bool) {
        disabled = disable
        imageView.alpha = disable ? 0.5 : 1.0
        label.alpha = disable ? 0.5 : 1.0
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageBackgroundView.layer.cornerRadius = imageBackgroundView.bounds.width / CGFloat(2.0)
    }
    
    private func updateAppearance() {
        imageBackgroundView.backgroundColor = .mnz_inputbarButtonBackground(traitCollection)
        label.textColor = TokenColors.Icon.secondary
    }

}
