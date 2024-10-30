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
        self.setRightTintColor()
    }
    
    func setRightTintColor() {
        imageView?.image?.withRenderingMode(.alwaysTemplate)
        tintColor = isSelected ? TokenColors.Components.interactive : TokenColors.Icon.primary
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
        backgroundColor = isHighlighted ? TokenColors.Background.surface1 : UIColor.clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let height: CGFloat = frame.height
        let divisor: CGFloat = 2.0
        self.layer.cornerRadius = height / divisor
    }
}
