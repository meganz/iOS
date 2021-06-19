import UIKit

@IBDesignable
final class MEGALabel: UILabel {
    @IBInspectable var textStyle: String?
    @IBInspectable var weight: String?
    
    // MARK: - Private functions
    private func setup() {
        guard let textStyle = Font.TextStyle(rawValue: textStyle ?? ""), let weight = Font.Weight(rawValue: weight ?? "") else { return }
        font = Font(style: textStyle, weight: weight).value
    }
    
    // MARK: - Internal functions
    func apply(style: MEGALabelStyle) {
        traitCollection.theme.labelStyleFactory.styler(of: style)(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        adjustsFontForContentSizeCategory = true

        setup()
    }
}
