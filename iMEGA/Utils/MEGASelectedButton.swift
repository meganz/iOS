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
        switch traitCollection.userInterfaceStyle {
        case .dark:
            tintColor = isSelected ? .mnz_green00A382() : .white
        case .light:
            tintColor = isSelected ? .mnz_green00A382() : .black
        default: break
        }
    }
}

class MEGAPlayerButton: UIButton {
    override public var isHighlighted: Bool {
        didSet {
            UIView.transition(with: self,
                              duration: 0.3,
                              options: .curveEaseInOut,
                              animations: {
                                switch self.traitCollection.userInterfaceStyle {
                                case .dark:
                                    self.backgroundColor = self.isHighlighted ? .mnz_gray333333() : UIColor.clear
                                case .light:
                                    self.backgroundColor = self.isHighlighted ? .mnz_whiteEFEFEF() : UIColor.clear
                                default: break
                                }
                              },
                              completion: nil)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.layer.cornerRadius = frame.height / 2
    }
}
