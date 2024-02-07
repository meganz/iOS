import MEGADesignToken

extension PasswordView {
    @objc func updateAppearance() {
        let currentTraitCollection = self.traitCollection
        topSeparatorView.backgroundColor = separatorColor()
        bottomSeparatorView.backgroundColor = separatorColor()
        
        leftImageView?.renderImage(withColor: iconTintColor())
        
        topLabel.textColor = normalLabelColor()
        passwordTextField.textColor = normalTextColor()
        
        if UIColor.isDesignTokenEnabled() {
            backgroundColor = TokenColors.Background.page
        } else {
            if backgroundColor != nil && !self.isUsingDefaultBackgroundColor {
                backgroundColor = UIColor.mnz_tertiaryBackground(currentTraitCollection)
            } else {
                backgroundColor = UIColor.mnz_secondaryBackground(for: currentTraitCollection)
                isUsingDefaultBackgroundColor = true
            }
        }
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }
    
    @objc func errorTextColor() -> UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Text.error : UIColor.systemRed
    }
    
    @objc func normalTextColor() -> UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Button.primary : UIColor.label
    }
    
    @objc func normalLabelColor() -> UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Button.primary : UIColor.mnz_secondaryGray(for: traitCollection)
    }
    
    @objc func setToggleSecureButtonTintColor(isActive: Bool) {
        if UIColor.isDesignTokenEnabled() {
            toggleSecureButton.tintColor = isActive ? TokenColors.Icon.primary : TokenColors.Icon.disabled
        }
    }
    
    // MARK: - Private
    
    private func separatorColor() -> UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Border.strong : UIColor.mnz_separator(for: traitCollection)
    }
    
    private func iconTintColor() -> UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Icon.secondary : UIColor.mnz_secondaryGray(for: traitCollection)
    }
}
