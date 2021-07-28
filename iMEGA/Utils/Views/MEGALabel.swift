import UIKit

@IBDesignable
final class MEGALabel: UILabel {
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
        NotificationCenter.default.removeObserver(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        adjustsFontForContentSizeCategory = true

        setup()
    }
    
    // MARK: - Private functions
    private func observeContentSizeUpdates() {
        NotificationCenter.default.addObserver(self, selector: #selector(setup), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    @objc private func setup() {
        guard let textStyle = Font.TextStyle(rawValue: textStyle ?? ""), let weight = Font.Weight(rawValue: weight ?? "") else { return }
        font = Font(style: textStyle, weight: weight).value
    }
    
    // MARK: - Internal functions
    func apply(style: MEGALabelStyle) {
        traitCollection.theme.labelStyleFactory.styler(of: style)(self)
    }
}
