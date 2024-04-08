import MEGADesignToken
import MEGAL10n

extension InviteFriendsViewController {
    @objc
    func configureNavigationBar() {
        let title = Strings.Localizable.Account.Achievement.Referral.title
        navigationItem.title = title
        setMenuCapableBackButtonWith(menuTitle: title)
    }
    
    // MARK: - Token colors
    @objc var defaultBackgroundColor: UIColor {
        TokenColors.Background.page
    }
    
    @objc var primaryTextColor: UIColor {
        TokenColors.Text.primary
    }
    
    @objc var secondayTextColor: UIColor {
        TokenColors.Text.secondary
    }
    
    @objc var separatorColor: UIColor {
        TokenColors.Border.strong
    }
}
