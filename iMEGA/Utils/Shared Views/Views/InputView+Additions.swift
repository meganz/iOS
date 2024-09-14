import MEGADesignToken

extension InputView {
    @objc func updateAppearance() {
        topSeparatorView.backgroundColor = separatorColor()
        bottomSeparatorView.backgroundColor = separatorColor()
        
        iconImageView?.renderImage(withColor: iconTintColor())
        topLabel?.textColor = normalLabelColor()
        inputTextField?.textColor = normalTextColor()
        
        backgroundColor = TokenColors.Background.page
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
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
    
    // MARK: - Private
    
    private func separatorColor() -> UIColor {
        TokenColors.Border.strong
    }
    
    private func iconTintColor() -> UIColor {
        TokenColors.Icon.secondary
    }
}
