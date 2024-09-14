import MEGADesignToken

extension SelectableTableViewCell {
    @objc func imageViewDesignToken() {
        redCheckmarkImageView?.image = UIImage.turquoiseCheckmark
        redCheckmarkImageView?.tintColor = TokenColors.Support.success
    }
}
