import MEGADesignToken

extension LTHPasscodeViewController {
    @objc func updateColorWithDesignToken() {
        guard UIColor.isDesignTokenEnabled() else { return }

        // Backgrounds
        backgroundColor = TokenColors.Background.surface1
        passcodeBackgroundColor = .clear
        coverViewBackgroundColor = TokenColors.Background.page
        failedAttemptLabelBackgroundColor = TokenColors.Support.error
        enterPasscodeLabelBackgroundColor = .clear
        eraseLocalDataLabelBackgroundColor = .clear

        // Text
        labelTextColor = TokenColors.Text.primary
        passcodeTextColor = TokenColors.Text.primary
        failedAttemptLabelTextColor = TokenColors.Text.onColor
        eraseLocalDataLabelTextColor = TokenColors.Support.error
        optionsButtonTextColor = TokenColors.Support.success
        textFieldBorderColor = TokenColors.Border.strong
    }
}
