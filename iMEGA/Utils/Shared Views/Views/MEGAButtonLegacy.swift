import UIKit

@IBDesignable
class MEGAButtonLegacy: UIButton, DynamicTypeComponentProtocol {
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
    
    init(textStyle: String, weight: String) {
        super.init(frame: .zero)

        self.textStyle = textStyle
        self.weight = weight
        
        observeContentSizeUpdates()
        applyFontSizes()
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
            guard let textStyle = FontStyle.TextStyle(rawValue: selectedTextStyle ?? ""),
                  let weight = FontStyle.Weight(rawValue: selectedWeight ?? "") else {
                defaultSetup()
                return
            }
            titleLabel?.font = FontStyle(style: textStyle, weight: weight).value
        } else {
            defaultSetup()
        }
    }
    
    private func defaultSetup() {
        guard let textStyle = FontStyle.TextStyle(rawValue: textStyle ?? ""),
              let weight = FontStyle.Weight(rawValue: weight ?? "") else { return }
        titleLabel?.font = FontStyle(style: textStyle, weight: weight).value
    }
}
