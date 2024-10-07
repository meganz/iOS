import Foundation

extension UIControl.State: @retroactive Hashable {}

protocol ButtonBackgroundStateAware {

    var statedColor: [UIControl.State: UIColor] { get }
    
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State)
}

final class MEGAThemeButton: UIButton, ButtonBackgroundStateAware, DynamicTypeComponentProtocol {
    
    @IBInspectable var textStyle: String?
    @IBInspectable var weight: String?
    @IBInspectable var selectedTextStyle: String?
    @IBInspectable var selectedWeight: String?
    
    private(set) var statedColor: [UIControl.State: UIColor] = [:]
    
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

    override var isHighlighted: Bool {
        didSet {
            let color = isHighlighted ? statedColor[.highlighted] : statedColor[.normal]
            backgroundColor = color
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            let color = isEnabled ? statedColor[.normal] : statedColor[.disabled]
            backgroundColor = color
        }
    }
    
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State) {
        statedColor[state] = color
        if case .normal = state {
            backgroundColor = color
        }
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
