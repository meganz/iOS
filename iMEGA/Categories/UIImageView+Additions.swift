
extension UIImageView{
    func renderImage(withColor color: UIColor) {
        guard let image =  self.image else { return }
        
        self.image = image.withRenderingMode(.alwaysTemplate)
        self.tintColor = color
    }
}

