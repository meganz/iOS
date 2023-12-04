import Foundation
import MEGADomain
import MEGAL10n
import MEGASDKRepo

extension CustomModalAlertViewController {
    func configureForCookieDialog() {
        image = UIImage(resource: .cookie)
        viewTitle = Strings.Localizable.Dialog.Cookies.Title.yourPrivacy
        detailAttributed = detailTextAttributedString()
        
        let detailTapGR = UITapGestureRecognizer(target: self, action: #selector(cookiePolicyTouchUpInside))
        detailTapGR.cancelsTouchesInView = false
        detailTapGestureRecognizer = detailTapGR
        
        firstButtonTitle = Strings.Localizable.Dialog.Cookies.accept
        dismissButtonStyle = MEGACustomButtonStyle.basic.rawValue
        dismissButtonTitle = Strings.Localizable.General.cookieSettings
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                Task { @MainActor in
                    do {
                        let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository.newRepo)
                        _ = try await cookieSettingsUseCase.setCookieSettings(with: CookiesBitmap.all.rawValue)
                        self?.dismiss(animated: true, completion: nil)
                    } catch {
                        guard let cookieSettingsError = error as? CookieSettingsErrorEntity else {
                            SVProgressHUD.showError(withStatus: error.localizedDescription)
                            return
                        }
                        switch cookieSettingsError {
                        case .invalidBitmap:
                            SVProgressHUD.showError(withStatus: error.localizedDescription)
                            
                        default:
                            SVProgressHUD.showError(withStatus: error.localizedDescription)
                        }
                    }
                }
            })
        }
        
        dismissCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                if UIApplication.mnz_presentingViewController().presentedViewController == nil {
                    CookieSettingsRouter(presenter: UIApplication.mnz_visibleViewController()).start()
                } else {
                    CookieSettingsRouter(presenter: UIApplication.mnz_presentingViewController()).start()
                }
            })
        }
    }
    
    @objc func detailTextAttributedString() -> NSAttributedString {
        var detailText = Strings.Localizable.Dialog.Cookies.description as NSString
        let cookiePolicy = detailText.mnz_stringBetweenString("[A]", andString: "[/A]")
        detailText = detailText.mnz_removeWebclientFormatters() as NSString
        
        let cookiePolicyRange = detailText.range(of: cookiePolicy ?? "")
        let detailTextAttributedString = NSMutableAttributedString(string: detailText as String, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(style: .footnote, weight: .medium), NSAttributedString.Key.foregroundColor: UIColor.mnz_subtitles(for: traitCollection)])
        detailTextAttributedString.addAttributes([NSAttributedString.Key.foregroundColor: UIColor.mnz_turquoise(for: traitCollection)], range: cookiePolicyRange)
        
        return detailTextAttributedString
    }
    
    @IBAction func cookiePolicyTouchUpInside(_ sender: UITapGestureRecognizer) {
        NSURL.init(string: "https://mega.nz/cookie")?.mnz_presentSafariViewController()
    }
}
