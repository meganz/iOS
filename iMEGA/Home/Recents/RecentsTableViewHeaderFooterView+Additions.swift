import MEGADesignToken

extension RecentsTableViewHeaderFooterView {
    @objc func configureTokenColors() {
        contentView.backgroundColor = TokenColors.Background.surface1
        dateLabel.textColor = TokenColors.Text.secondary
    }
}
