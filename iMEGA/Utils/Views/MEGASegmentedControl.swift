import UIKit

@IBDesignable
final class MEGASegmentedControl: UISegmentedControl, DynamicTypeComponentProtocol {
    @IBInspectable var textStyle: String?
    @IBInspectable var weight: String?
    @IBInspectable var selectedTextStyle: String?
    @IBInspectable var selectedWeight: String?
    
    private var color: UIColor?
    private var selectedColor: UIColor?

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
        
        applyFontSizes()
    }
    
    @objc func setTitleTextColor(_ color: UIColor, selectedColor: UIColor) {
        self.color = color
        self.selectedColor = selectedColor
        
        applyFontSizes()
    }

    func applyFontSizes() {
        if let textStyle = Font.TextStyle(rawValue: textStyle ?? ""),
           let weight = Font.Weight(rawValue: weight ?? "") {
            if let color = color {
                setTitleTextAttributes([.font: Font(style: textStyle, weight: weight).value,
                                        .foregroundColor: color], for: .normal)
            } else {
                setTitleTextAttributes([.font: Font(style: textStyle, weight: weight).value], for: .normal)
            }
        }
        
        if let selectedTextStyle = Font.TextStyle(rawValue: selectedTextStyle ?? ""),
           let selectedWeight = Font.Weight(rawValue: selectedWeight ?? "") {
            if let selectedColor = selectedColor {
                setTitleTextAttributes([.font: Font(style: selectedTextStyle, weight: selectedWeight).value,
                                        .foregroundColor: selectedColor], for: .selected)
            } else {
                setTitleTextAttributes([.font: Font(style: selectedTextStyle, weight: selectedWeight).value], for: .selected)
            }
        }
    }
}
