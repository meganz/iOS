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
        TokenColors.Link.primary
    }
    
    @objc func loginLabelrimaryTextColor() -> UIColor {
        TokenColors.Text.primary
    }
    
    @objc func loginLabelLinkTextColor() -> UIColor {
        TokenColors.Link.primary
    }
}
