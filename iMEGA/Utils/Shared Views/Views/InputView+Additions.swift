import MEGADesignToken

extension InputView {
    @objc func updateAppearance() {
        topSeparatorView.backgroundColor = TokenColors.Border.strong
        bottomSeparatorView.backgroundColor = TokenColors.Border.strong
        
        iconImageView?.renderImage(withColor: TokenColors.Icon.secondary)
        topLabel?.textColor = normalLabelColor()
        inputTextField?.textColor = normalTextColor()
        
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
}
