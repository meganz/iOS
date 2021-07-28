import UIKit

@IBDesignable
final class MEGALabel: UILabel, DynamicTypeProtocol {
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
    
    func apply(style: MEGALabelStyle) {
        traitCollection.theme.labelStyleFactory.styler(of: style)(self)
    }
    
    func applyFontSizes() {
        guard let textStyle = Font.TextStyle(rawValue: textStyle ?? ""), let weight = Font.Weight(rawValue: weight ?? "") else { return }
        font = Font(style: textStyle, weight: weight).value
    }
}
