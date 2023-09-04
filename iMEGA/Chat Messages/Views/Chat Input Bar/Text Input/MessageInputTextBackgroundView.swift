class MessageInputTextBackgroundView: UIView {
    
    var maxCornerRadius: CGFloat = .greatestFiniteMagnitude
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = min(bounds.height / 2.0, maxCornerRadius)
    }
}
