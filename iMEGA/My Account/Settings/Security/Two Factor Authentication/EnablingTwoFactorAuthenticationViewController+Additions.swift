import MEGADesignToken

extension EnablingTwoFactorAuthenticationViewController {
    @objc var defaultBackgroundColor: UIColor {
        TokenColors.Background.page
    }

    @objc var separatorColor: UIColor {
        TokenColors.Border.strong
    }

    @objc var labelColor: UIColor {
        TokenColors.Text.primary
    }

    @objc var openInButtonStyle: MEGACustomButtonStyle {
        .primary
    }

    @objc var nextButtonStyle: MEGACustomButtonStyle {
        .secondary
    }
}
