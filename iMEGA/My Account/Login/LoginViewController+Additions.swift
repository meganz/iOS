import MEGADesignToken
import MEGASwift

extension LoginViewController {
    private enum Constants {
        static let landscapeLoginButtonTopPadding: CGFloat = 45
        static let portraitLoginButtonTopPadding: CGFloat = 155
    }

    @objc func recoveryPasswordURL(_ email: String?) -> URL {
        let encodedEmail = email?.base64Encoded
        let recoveryURLString = encodedEmail != nil ? "https://mega.nz/recovery?email=\(encodedEmail ?? "")" : "https://mega.nz/recovery"
    
        return URL(string: recoveryURLString) ?? URL(fileURLWithPath: "")
    }
    
    @objc func updateLoginButtonTopConstraint() {
        loginButtonTopCostraint.constant =  UIDevice.current.orientation.isLandscape ? Constants.landscapeLoginButtonTopPadding
        : Constants.portraitLoginButtonTopPadding
    }
    
    @objc func requestStopAudioPlayerSession() {
        if AudioPlayerManager.shared.isPlayerAlive() {
            let streamingInfoUseCase = StreamingInfoUseCase()
            streamingInfoUseCase.stopServer()
        }
    }
    
    @objc func forgotPasswordTintColor() -> UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Link.primary : UIColor.mnz_secondaryGray(for: traitCollection)
    }
    
    @objc func loginLabelrimaryTextColor() -> UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Text.primary : UIColor.mnz_primaryGray(for: traitCollection)
    }
    
    @objc func loginLabelLinkTextColor() -> UIColor {
        UIColor.isDesignTokenEnabled() ? TokenColors.Link.primary : UIColor.mnz_turquoise(for: self.traitCollection)
    }
}
