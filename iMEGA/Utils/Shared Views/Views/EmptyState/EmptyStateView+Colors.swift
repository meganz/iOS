import MEGADesignToken

extension EmptyStateView {
    @objc func designTokenColors() {
        titleLabel?.textColor = TokenColors.Text.primary
        imageView?.tintColor = TokenColors.Icon.secondary
        self.backgroundColor = TokenColors.Background.page
    }
}
