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
        if #available(iOS 12.0, *) {
            imageView?.image?.withRenderingMode(.alwaysTemplate)
            switch traitCollection.userInterfaceStyle {
            case .dark:
                tintColor = isSelected ? .mnz_green00A382() : .white
            case .light:
                tintColor = isSelected ? .mnz_green00A382() : .black
            default: break
            }
        } else {
            tintColor = isSelected ? .mnz_green00A382() : .white
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
                                if #available(iOS 12.0, *) {
                                    switch self.traitCollection.userInterfaceStyle {
                                    case .dark:
                                        self.backgroundColor = self.isHighlighted ? .mnz_gray333333() : UIColor.clear
                                    case .light:
                                        self.backgroundColor = self.isHighlighted ? .mnz_whiteEFEFEF() : UIColor.clear
                                    default: break
                                    }
                                } else {
                                    self.backgroundColor = self.isHighlighted ? .mnz_whiteEFEFEF() : UIColor.clear
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
