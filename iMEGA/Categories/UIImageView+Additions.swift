
extension UIImageView{
    func renderImage(withColor color: UIColor) {
        guard let image =  self.image else { return }
        
        self.image = image.withRenderingMode(.alwaysTemplate)
        self.tintColor = color
    }
}

extension UIImageView {
    func applyShadow(in container: UIView, color: UIColor = .black, alpha: Float, x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat) {
        container.layer.masksToBounds = false
        container.layer.shadowColor = color.cgColor
        container.layer.shadowOpacity = alpha
        container.layer.shadowOffset = CGSize(width: x, height: y)
        container.layer.shadowRadius = blur / 2.0
        container.layer.cornerRadius = blur / 2.0
        container.layer.shadowPath = spread == 0 ? nil : UIBezierPath(rect: bounds.insetBy(dx: -spread, dy: -spread)).cgPath
        clipsToBounds = true
        layer.cornerRadius = blur / 2
    }
}
