import MEGADesignToken

extension ContactRequestsViewController {
    @objc func updateAppearance() {
        if UIColor.isDesignTokenEnabled() {
            view.backgroundColor = TokenColors.Background.page
            tableView?.backgroundColor = TokenColors.Background.page
            tableView?.separatorColor = TokenColors.Border.strong
        } else {
            tableView?.separatorColor = UIColor.mnz_separator(for: traitCollection)
        }
    }
}
