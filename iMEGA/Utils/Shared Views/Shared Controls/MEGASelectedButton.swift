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
            tintColor = isSelected ?  MEGAAppColor.Green._00A382.uiColor : MEGAAppColor.White._FFFFFF.uiColor
        case .light:
            tintColor = isSelected ? MEGAAppColor.Green._00A382.uiColor : MEGAAppColor.Black._000000.uiColor
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
                                    self.backgroundColor = self.isHighlighted ? MEGAAppColor.Gray._333333.uiColor : UIColor.clear
                                case .light:
                                    self.backgroundColor = self.isHighlighted ? MEGAAppColor.White._EFEFEF.uiColor : UIColor.clear
                                default: break
                                }
                              },
                              completion: nil)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let height: CGFloat = frame.height
        let divisor: CGFloat = 2.0
        self.layer.cornerRadius = height / divisor
    }
}
