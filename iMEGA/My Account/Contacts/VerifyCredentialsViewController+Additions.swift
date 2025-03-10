import MEGADesignToken
import MEGAL10n

extension VerifyCredentialsViewController {
    
    @objc func setContentMessages() {
        navigationItem.title = Strings.Localizable.verifyCredentials
        myCredentialsHeaderLabel.text = Strings.Localizable.SharedItems.ContactVerification.Section.MyCredentials.message

        if isVerifyContactForSharedItem {
            contactHeaderLabel.text = isIncomingSharedItem ?
            Strings.Localizable.SharedItems.ContactVerification.Section.VerifyContact.Receiver.message:
            Strings.Localizable.SharedItems.ContactVerification.Section.VerifyContact.Owner.message
        } else {
            contactHeaderLabel.text = Strings.Localizable.VerifyCredentials.headerMessage
        }
    }

    @objc func setupColors() {
        contactHeaderLabel.textColor = TokenColors.Text.secondary
        myCredentialsHeaderLabel.textColor = TokenColors.Text.secondary
        view.backgroundColor = TokenColors.Background.page
        myCredentialsTopSeparatorView.backgroundColor = TokenColors.Border.strong
        myCredentialsView.backgroundColor = TokenColors.Background.surface1
        userEmailLabel.textColor = TokenColors.Text.secondary
        myCredentialsSubView.layer.borderColor = TokenColors.Border.strong.cgColor
        myCredentialsSubView.backgroundColor = TokenColors.Background.surface2
    }
    
    @objc func setResetButtonColor(_ button: UIButton) {
        button.backgroundColor = TokenColors.Button.secondary
        button.setTitleColor(TokenColors.Text.accent, for: UIControl.State.normal)
    }
}
