import UIKit

@IBDesignable
final class MEGALabel: UILabel, DynamicTypeComponentProtocol {
    @IBInspectable var textStyle: String?
    @IBInspectable var weight: String?
    
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
    
    func applyFontSizes() {
        guard let textStyle = Font.TextStyle(rawValue: textStyle ?? ""), let weight = Font.Weight(rawValue: weight ?? "") else { return }
        font = Font(style: textStyle, weight: weight).value
    }
    
    func apply(style: Font.TextStyle, weight: Font.Weight = .regular) {
        self.textStyle = style.rawValue
        self.weight = weight.rawValue
        font = Font(style: style, weight: weight).value
    }
}
