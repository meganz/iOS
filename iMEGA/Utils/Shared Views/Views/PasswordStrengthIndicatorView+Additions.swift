import MEGADesignToken

extension PasswordStrengthIndicatorView {
    @objc func textColor() -> UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Text.secondary : UIColor.label
    }
    
    @objc func strengthLabeColor(with type: PasswordStrength) -> UIColor {
        var labelColor: UIColor = .black
        
        switch type {
        case .veryWeak:
            labelColor = UIColor.isDesignTokenEnabled() ? TokenColors.Indicator.pink : UIColor.systemRed
        case .weak:
            labelColor = UIColor.isDesignTokenEnabled() ? TokenColors.Indicator.orange : UIColor(red: 1.0, green: 165.0/255.0, blue: 0, alpha: 1.0)
        case .medium:
            labelColor = UIColor.isDesignTokenEnabled() ? TokenColors.Indicator.green : UIColor.systemGreen
        case .good:
            labelColor = UIColor.isDesignTokenEnabled() ? TokenColors.Indicator.green : UIColor.systemGreen
        case .strong:
            labelColor = UIColor.isDesignTokenEnabled() ? TokenColors.Indicator.blue : UIColor.mnz_blue(for: traitCollection)
        @unknown default:
            labelColor = UIColor.isDesignTokenEnabled() ? TokenColors.Indicator.pink : UIColor.systemRed
        }
        
        return labelColor
    }
    
    @objc func setStrengthImageViewTintColor(with type: PasswordStrength) {
        if UIColor.isDesignTokenEnabled() {
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
}
