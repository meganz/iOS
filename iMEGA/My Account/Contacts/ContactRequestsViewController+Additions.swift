import MEGADesignToken

extension ContactRequestsViewController {
    @objc func updateAppearance() {
        view.backgroundColor = TokenColors.Background.page
        tableView?.backgroundColor = TokenColors.Background.page
        tableView?.separatorColor = TokenColors.Border.strong
    }
}
