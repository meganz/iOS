import MEGADesignToken

extension PasswordView {
    @objc func updateAppearance() {
        topSeparatorView.backgroundColor = TokenColors.Border.strong
        bottomSeparatorView.backgroundColor = TokenColors.Border.strong
        
        leftImageView?.renderImage(withColor: TokenColors.Icon.secondary)
        
        topLabel.textColor = normalLabelColor()
        passwordTextField.textColor = normalTextColor()
        
        backgroundColor = TokenColors.Background.page
    }
    
    @objc func errorTextColor() -> UIColor {
        TokenColors.Text.error
    }
    
    @objc func normalTextColor() -> UIColor {
        TokenColors.Button.primary
    }
    
    @objc func normalLabelColor() -> UIColor {
        TokenColors.Button.primary
    }
    
    @objc func setToggleSecureButtonTintColor(isActive: Bool) {
        toggleSecureButton.tintColor = isActive ? TokenColors.Icon.primary : TokenColors.Icon.disabled
    }
}
