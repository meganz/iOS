extension CreateAccountViewController {
    
    // MARK: - Login
    @objc func setLoginAttributedText() {
        let font = UIFont.mnz_preferredFont(withStyle: .caption1, weight: .regular)
        let accountAttributedString = NSMutableAttributedString(string: Strings.Localizable.Account.CreateAccount.alreadyHaveAnAccount,
                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor.mnz_primaryGray(for: self.traitCollection),
                                                                      NSAttributedString.Key.font: font])
        let loginAttributedString = NSAttributedString(string: Strings.Localizable.login,
                                                         attributes: [NSAttributedString.Key.foregroundColor: UIColor.mnz_turquoise(for: self.traitCollection),
                                                                      NSAttributedString.Key.font: font])
        accountAttributedString.append(NSAttributedString(string: " "))
        accountAttributedString.append(loginAttributedString)
        loginLabel.attributedText = accountAttributedString
    }
    
    @objc func didTapLogin() {
        self.dismiss(animated: true) {
            if let onboardingVC = UIApplication.mnz_visibleViewController() as? OnboardingViewController {
                onboardingVC.presentLoginViewController()
            }
        }
    }
}
