import MEGAL10n

extension InviteFriendsViewController {
    @objc
    func configureNavigationBar() {
        let title = Strings.Localizable.Account.Achievement.Referral.title
        navigationItem.title = title
        setMenuCapableBackButtonWith(menuTitle: title)
    }
}
