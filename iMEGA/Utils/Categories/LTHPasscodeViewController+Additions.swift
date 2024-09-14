import MEGADesignToken

extension LTHPasscodeViewController {
    @objc func updateColorWithDesignToken() {
        // Backgrounds
        backgroundColor = TokenColors.Background.surface1
        passcodeBackgroundColor = .clear
        coverViewBackgroundColor = TokenColors.Background.page
        failedAttemptLabelBackgroundColor = .clear
        enterPasscodeLabelBackgroundColor = .clear
        eraseLocalDataLabelBackgroundColor = .clear

        // Text
        labelTextColor = TokenColors.Text.primary
        passcodeTextColor = TokenColors.Text.primary
        failedAttemptLabelTextColor = TokenColors.Support.error
        eraseLocalDataLabelTextColor = TokenColors.Support.error
        optionsButtonTextColor = TokenColors.Link.primary
        textFieldBorderColor = TokenColors.Border.strong
    }
}
