import Foundation
import MEGADomain
import MEGAL10n
import MEGASDKRepo
import MEGASwift

extension CustomModalAlertViewController {
    enum CookieDialogType {
        case noAdsCookiePolicy, adsCookiePolicy
        
        var description: String {
            switch self {
            case .noAdsCookiePolicy:
                return Strings.Localizable.Dialog.Cookies.Description.cookiePolicy
            case .adsCookiePolicy:
                return Strings.Localizable.Dialog.Cookies.Description.adsCookiePolicy
            }
        }
    }
    
    func configureForCookieDialog(type: CookieDialogType) {
        image = UIImage(resource: .cookie)
        viewTitle = Strings.Localizable.Dialog.Cookies.Title.manageCookies
        detailAttributedTextWithLink = detailTextAttributedString(detail: type.description)

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
    
    private func detailTextAttributedString(detail: String) -> NSAttributedString {
        let cookiePolicy = detail.subString(from: "[A]", to: "[/A]")
        let detailText = detail
            .replacingOccurrences(of: "[A]", with: "")
            .replacingOccurrences(of: "[/A]", with: "")
        let cookiePolicyRange = (detailText as NSString).range(of: cookiePolicy ?? "")
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        let detailTextAttributedString = NSMutableAttributedString(
            string: detailText,
            attributes: [
                .font: UIFont.preferredFont(style: .callout, weight: .regular),
                .foregroundColor: UIColor.textForeground,
                .paragraphStyle: paragraph
            ]
        )
        
        guard let urlLink = URL(string: "https://mega.nz/cookie") else {
            return detailTextAttributedString
        }
        detailTextAttributedString.addAttributes(
            [.foregroundColor: UIColor.turquoise, .link: urlLink],
            range: cookiePolicyRange
        )
        
        return detailTextAttributedString
    }
}
