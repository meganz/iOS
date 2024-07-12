import MEGADesignToken
import UIKit

final class MEGASelectedButton: UIButton {
    
    override var isSelected: Bool {
        didSet {
            setRightTintColor()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        registerForTraitChanges()
        self.setRightTintColor()
    }
    
    func setRightTintColor() {
        imageView?.image?.withRenderingMode(.alwaysTemplate)
        
        if UIColor.isDesignTokenEnabled() {
            tintColor = isSelected ? TokenColors.Components.interactive : TokenColors.Icon.primary
        } else {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                tintColor = isSelected ? UIColor.green00A382 : UIColor.whiteFFFFFF
            case .light:
                tintColor = isSelected ? UIColor.green00A382 : UIColor.black000000
            default: break
            }
        }
    }
    
    private func registerForTraitChanges() {
        guard #available(iOS 17.0, *) else { return }
        registerForTraitChanges([UITraitUserInterfaceStyle.self], handler: { [weak self] (button: MEGASelectedButton, previousTraitCollection: UITraitCollection) in
            if button.traitCollection.userInterfaceStyle != previousTraitCollection.userInterfaceStyle {
                self?.setRightTintColor()
            }
        })
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #unavailable(iOS 17.0), traitCollection.userInterfaceStyle != previousTraitCollection?.userInterfaceStyle {
            setRightTintColor()
        }
    }
}

class MEGAPlayerButton: UIButton {
    override public var isHighlighted: Bool {
        didSet {
            UIView.transition(with: self,
                              duration: 0.3,
                              options: .curveEaseInOut,
                              animations: { [weak self] in self?.setHighlightedBackgroundColor() },
                              completion: nil)
        }
    }
    
    private func setHighlightedBackgroundColor() {
        if UIColor.isDesignTokenEnabled() {
            backgroundColor = isHighlighted ? TokenColors.Background.surface1 : UIColor.clear
        } else {
            switch traitCollection.userInterfaceStyle {
            case .dark:
                backgroundColor = isHighlighted ? UIColor.gray333333 : UIColor.clear
            case .light:
                backgroundColor = isHighlighted ? UIColor.whiteEFEFEF : UIColor.clear
            default:
                break
            }
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let height: CGFloat = frame.height
        let divisor: CGFloat = 2.0
        self.layer.cornerRadius = height / divisor
    }
}
