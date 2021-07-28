import UIKit

@IBDesignable
class MEGAButton: UIButton {
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
        NotificationCenter.default.removeObserver(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleLabel?.adjustsFontForContentSizeCategory = true

        setup()
    }
    
    // MARK: - Private functions
    private func observeContentSizeUpdates() {
        NotificationCenter.default.addObserver(self, selector: #selector(setup), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    @objc private func setup() {
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
