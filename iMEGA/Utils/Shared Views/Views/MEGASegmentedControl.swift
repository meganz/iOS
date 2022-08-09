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
        if let textStyle = FontStyle.TextStyle(rawValue: textStyle ?? ""),
           let weight = FontStyle.Weight(rawValue: weight ?? "") {
            if let color = color {
                setTitleTextAttributes([.font: FontStyle(style: textStyle, weight: weight).value,
                                        .foregroundColor: color], for: .normal)
            } else {
                setTitleTextAttributes([.font: FontStyle(style: textStyle, weight: weight).value], for: .normal)
            }
        }
        
        if let selectedTextStyle = FontStyle.TextStyle(rawValue: selectedTextStyle ?? ""),
           let selectedWeight = FontStyle.Weight(rawValue: selectedWeight ?? "") {
            if let selectedColor = selectedColor {
                setTitleTextAttributes([.font: FontStyle(style: selectedTextStyle, weight: selectedWeight).value,
                                        .foregroundColor: selectedColor], for: .selected)
            } else {
                setTitleTextAttributes([.font: FontStyle(style: selectedTextStyle, weight: selectedWeight).value], for: .selected)
            }
        }
    }
}
