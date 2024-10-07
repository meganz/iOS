import MEGADesignToken

extension PasswordView {
    @objc func updateAppearance() {
        topSeparatorView.backgroundColor = separatorColor()
        bottomSeparatorView.backgroundColor = separatorColor()
        
        leftImageView?.renderImage(withColor: iconTintColor())
        
        topLabel.textColor = normalLabelColor()
        passwordTextField.textColor = normalTextColor()
        
        backgroundColor = TokenColors.Background.page
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
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
    
    // MARK: - Private
    
    private func separatorColor() -> UIColor {
        TokenColors.Border.strong
    }
    
    private func iconTintColor() -> UIColor {
        TokenColors.Icon.secondary
    }
}
