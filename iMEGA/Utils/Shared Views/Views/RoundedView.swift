import Foundation

final class RoundedView: UIView {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let height = frame.height
        let divisor: CGFloat = 2
        layer.cornerRadius = height / divisor
    }
}
