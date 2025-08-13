import MEGAAppPresentation
import MEGADesignToken

extension TwoFactorAuthenticationViewController {
    @objc var defaultBackgroundColor: UIColor {
        TokenColors.Background.page
    }

    @objc var separatorColor: UIColor {
        TokenColors.Border.strong
    }

    @objc var errorColor: UIColor {
        TokenColors.Support.error
    }

    @objc var labelColor: UIColor {
        TokenColors.Text.primary
    }

    @objc var domainName: String {
        DIContainer.appDomainUseCase.domainName
    }
}
