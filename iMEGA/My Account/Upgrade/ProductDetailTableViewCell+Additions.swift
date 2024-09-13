import MEGADesignToken

extension ProductDetailTableViewCell {
    
    @objc func updateAppearance() {
        backgroundColor = TokenColors.Background.page
        
        let primaryTextColor = TokenColors.Text.primary
        periodLabel.textColor = primaryTextColor
        priceLabel.textColor = primaryTextColor
    }
    
}
