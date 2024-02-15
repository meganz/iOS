import MEGADesignToken

extension SelectableTableViewCell {
    @objc func imageViewDesignToken() {
        if UIColor.isDesignTokenEnabled() {
            redCheckmarkImageView.image = UIImage.turquoiseCheckmark
            redCheckmarkImageView.tintColor = TokenColors.Support.success
        }
    }
}
