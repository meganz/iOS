import MEGADesignToken

extension ProductDetailTableViewCell {
    
    @objc func updateAppearance() {
        backgroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Background.page : UIColor.systemBackground
        
        let primaryTextColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.label
        periodLabel.textColor = primaryTextColor
        priceLabel.textColor = primaryTextColor
    }
    
}
