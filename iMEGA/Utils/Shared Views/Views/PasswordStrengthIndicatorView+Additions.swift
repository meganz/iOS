import MEGADesignToken

extension PasswordStrengthIndicatorView {
    @objc func textColor() -> UIColor {
        TokenColors.Text.secondary
    }
    
    @objc func strengthLabeColor(with type: PasswordStrength) -> UIColor {
        var labelColor: UIColor = .black
        
        switch type {
        case .veryWeak:
            labelColor = TokenColors.Indicator.pink
        case .weak:
            labelColor = TokenColors.Indicator.orange
        case .medium, .good:
            labelColor = TokenColors.Indicator.green
        case .strong:
            labelColor = TokenColors.Indicator.blue
        @unknown default:
            labelColor = TokenColors.Indicator.pink
        }
        
        return labelColor
    }
    
    @objc func setStrengthImageViewTintColor(with type: PasswordStrength) {
        switch type {
        case .veryWeak:
            imageView.renderImage(withColor: TokenColors.Indicator.pink)
        case .weak:
            imageView.renderImage(withColor: TokenColors.Indicator.orange)
        case .medium:
            imageView.renderImage(withColor: TokenColors.Indicator.green)
        case .good:
            imageView.renderImage(withColor: TokenColors.Indicator.green)
        case .strong:
            imageView.renderImage(withColor: TokenColors.Indicator.blue)
        @unknown default:
            imageView.renderImage(withColor: TokenColors.Indicator.pink)
        }
    }
}
