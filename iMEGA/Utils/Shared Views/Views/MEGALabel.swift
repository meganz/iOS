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
        
        Task { @MainActor in
            applyFontSizes()
        }
    }
    
    func applyFontSizes() {
        guard let textStyle = FontStyle.TextStyle(rawValue: textStyle ?? ""), let weight = FontStyle.Weight(rawValue: weight ?? "") else { return }
        font = FontStyle(style: textStyle, weight: weight).value
    }
    
    func apply(style: FontStyle.TextStyle, weight: FontStyle.Weight = .regular) {
        self.textStyle = style.rawValue
        self.weight = weight.rawValue
        font = FontStyle(style: style, weight: weight).value
    }
}
