import UIKit

@IBDesignable
class MEGAButton: UIButton, DynamicTypeComponentProtocol {
    @IBInspectable var textStyle: String?
    @IBInspectable var weight: String?
    @IBInspectable var selectedTextStyle: String?
    @IBInspectable var selectedWeight: String?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        observeContentSizeUpdates()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        observeContentSizeUpdates()
    }
    
    deinit {
        removeObserver()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel?.adjustsFontForContentSizeCategory = true

        applyFontSizes()
    }
    
    func applyFontSizes() {
        if isSelected {
            guard let textStyle = Font.TextStyle(rawValue: selectedTextStyle ?? ""),
                  let weight = Font.Weight(rawValue: selectedWeight ?? "") else {
                defaultSetup()
                return
            }
            titleLabel?.font = Font(style: textStyle, weight: weight).value
        } else {
            defaultSetup()
        }
    }
    
    private func defaultSetup() {
        guard let textStyle = Font.TextStyle(rawValue: textStyle ?? ""),
              let weight = Font.Weight(rawValue: weight ?? "") else { return }
        titleLabel?.font = Font(style: textStyle, weight: weight).value
    }
}
