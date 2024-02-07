import MEGADesignToken

extension InputView {
    @objc func updateAppearance() {
        topSeparatorView.backgroundColor = separatorColor()
        bottomSeparatorView.backgroundColor = separatorColor()
        
        iconImageView?.renderImage(withColor: iconTintColor())
        topLabel?.textColor = normalLabelColor()
        inputTextField?.textColor = normalTextColor()
        
        if UIColor.isDesignTokenEnabled() {
            backgroundColor = TokenColors.Background.page
        } else {
            if backgroundColor != nil && !isUsingDefaultBackgroundColor {
                backgroundColor = UIColor.mnz_tertiaryBackground(traitCollection)
            } else {
                backgroundColor = UIColor.mnz_secondaryBackground(for: traitCollection)
                isUsingDefaultBackgroundColor = true
            }
        }
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
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
    
    // MARK: - Private
    
    private func separatorColor() -> UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Border.strong : UIColor.mnz_separator(for: traitCollection)
    }
    
    private func iconTintColor() -> UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Icon.secondary : UIColor.mnz_secondaryGray(for: traitCollection)
    }
}
