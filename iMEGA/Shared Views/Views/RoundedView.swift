import Foundation

final class RoundedView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        layer.cornerRadius = frame.height / 2
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        setNeedsLayout()
    }
}
