import Foundation

protocol ButtonBackgroundStateAware {

    var statedColor: [UIControl.State: UIColor]  { get }
    
    func setBackgroundColor(_ color: UIColor, for state: UIControl.State)
}

final class MEGAThemeButton: UIButton, ButtonBackgroundStateAware {

    private(set) var statedColor: [UIControl.State: UIColor] = [:]

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
}
