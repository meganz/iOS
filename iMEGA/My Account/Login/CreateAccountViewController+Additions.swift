import MEGAAssets
import MEGADesignToken
import MEGAAppPresentation
import MEGAL10n

extension CreateAccountViewController {
    @objc var domainName: String {
        DIContainer.appDomainUseCase.domainName
    }
    
    // MARK: - Login
    @objc func setLoginAttributedText() {
        let font = UIFont.mnz_preferredFont(withStyle: .caption1, weight: .regular)
        let accountAttributedString = NSMutableAttributedString(string: Strings.Localizable.Account.CreateAccount.alreadyHaveAnAccount,
                                                                attributes: [NSAttributedString.Key.foregroundColor: termPrimaryTextColor(),
                                                                             NSAttributedString.Key.font: font])
        let loginAttributedString = NSAttributedString(string: Strings.Localizable.login,
                                                       attributes: [NSAttributedString.Key.foregroundColor: termLinkTextColor(),
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
    
    @objc func setUpCheckBoxButton() {
        termsCheckboxButton.setImage(MEGAAssets.UIImage.checkBoxSelectedSemantic, for: .selected)
        termsCheckboxButton.setImage(MEGAAssets.UIImage.checkBoxUnselected, for: .normal)
        termsForLosingPasswordCheckboxButton.setImage(MEGAAssets.UIImage.checkBoxSelectedSemantic, for: .selected)
        termsForLosingPasswordCheckboxButton.setImage(MEGAAssets.UIImage.checkBoxUnselected, for: .normal)
    }
    
    @objc func termPrimaryTextColor() -> UIColor {
       TokenColors.Text.primary
    }
    
    @objc func termLinkTextColor() -> UIColor {
        TokenColors.Link.primary
    }
    
    @objc func passwordStrengthBackgroundColor() -> UIColor {
        TokenColors.Background.page
    }
}
