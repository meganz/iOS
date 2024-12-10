import MEGADesignToken

extension ContactRequestsViewController {
    @objc func setupColors() {
        view.backgroundColor = TokenColors.Background.page
        tableView?.backgroundColor = TokenColors.Background.page
        tableView?.separatorColor = TokenColors.Border.strong
    }
    
    @objc func dismissHUD() {
        if SVProgressHUD.isVisible() {
            SVProgressHUD.dismiss()
        }
    }
}
