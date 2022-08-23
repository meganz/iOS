import UIKit

public extension UIImageView {
    func renderImage(withColor color: UIColor) {
        guard let image =  self.image else { return }
        
        self.image = image.withRenderingMode(.alwaysTemplate)
        self.tintColor = color
    }
    
    func applyShadow(in container: UIView, color: UIColor = .black, alpha: Float, x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat) {
        container.layer.masksToBounds = false
        clipsToBounds = true
        updateShadowProperties(for: container, color: color, alpha: alpha, x: x, y: y, blur: blur)
        updateShadowPath(for: container, spread: spread)
        layer.cornerRadius = blur / 2
    }
    
    func setToIntrinsicContentSize() {
        guard let imageData = image else { return }

        let scaledHeight = imageData.size.height * (frame.size.width / imageData.size.width)
        frame.size = CGSize(width: frame.size.width, height: scaledHeight)
    }
    
    private func updateShadowProperties(for container: UIView, color: UIColor, alpha: Float, x: CGFloat, y: CGFloat, blur: CGFloat) {
        container.layer.shadowColor = color.cgColor
        container.layer.shadowOpacity = alpha
        container.layer.shadowOffset = CGSize(width: x, height: y)
        let radius =  blur / 2.0
        container.layer.shadowRadius = radius
        container.layer.cornerRadius = radius
    }
    
    private func updateShadowPath(for container: UIView, spread: CGFloat) {
        let shadowRect = bounds.insetBy(dx: -spread, dy: -spread)
        let shadowPath = UIBezierPath(rect: shadowRect)
        container.layer.shadowPath = spread == CGFloat.zero ? nil : shadowPath.cgPath
    }
}
