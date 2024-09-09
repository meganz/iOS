import Foundation
import MEGADesignToken
import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo
import MEGASwift
import MEGASwiftUI

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
    
    func configureForCookieDialog(type: CookieDialogType, cookiePolicyURLString: String) {
        image = UIImage.cookie
        viewTitle = Strings.Localizable.Dialog.Cookies.Title.manageCookies
        detailAttributedTextWithLink = detailTextAttributedString(detail: type.description, cookiePolicyURLString: cookiePolicyURLString)
        
        firstButtonTitle = Strings.Localizable.Dialog.Cookies.accept
        
        if UIColor.isDesignTokenEnabled() {
            secondButtonTitle = Strings.Localizable.General.cookieSettings
        } else {
            dismissButtonStyle = MEGACustomButtonStyle.basic.rawValue
            dismissButtonTitle = Strings.Localizable.General.cookieSettings
        }
        
        firstCompletion = { [weak self] in
            self?.dismiss(animated: true, completion: {
                Task { @MainActor in
                    do {
                        let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository.newRepo)
                        
                        var cookieSettings = CookiesBitmap.all
                        if type == .adsCookiePolicy {
                            cookieSettings.insert(.adsCheckCookie)
                        }
                        
                        _ = try await cookieSettingsUseCase.setCookieSettings(with: cookieSettings.rawValue)
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
        
        if UIColor.isDesignTokenEnabled() {
            secondCompletion = { [weak self] in
                self?.dismiss(animated: true, completion: {
                    if UIApplication.mnz_presentingViewController().presentedViewController == nil {
                        CookieSettingsRouter(presenter: UIApplication.mnz_visibleViewController()).start()
                    } else {
                        CookieSettingsRouter(presenter: UIApplication.mnz_presentingViewController()).start()
                    }
                })
            }
        } else {
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
        
        viewModel = makeCookieDialogViewModel()
    }
    
    private func makeCookieDialogViewModel() -> CustomModalAlertViewModel {
        let invalidLinkTapAction = {
            SnackBarRouter.shared.present(snackBar: SnackBar(message: Strings.Localizable.somethingWentWrong))
        }
        
        let configureSnackBarPresenter = { [weak self] in
            guard let self else { return }
            SnackBarRouter.shared.configurePresenter(self)
        }
        
        let removeSnackBarPresenter = {
            SnackBarRouter.shared.removePresenter()
        }
        
        return CustomModalAlertViewModel(
            invalidLinkTapAction: invalidLinkTapAction,
            configureSnackBarPresenter: configureSnackBarPresenter,
            removeSnackBarPresenter: removeSnackBarPresenter,
            tracker: DIContainer.tracker,
            analyticsEvents: nil
        )
    }
    
    private func detailTextAttributedString(detail: String, cookiePolicyURLString: String) -> NSAttributedString {
        let cookiePolicy = detail.subString(from: "[A]", to: "[/A]")
        let detailText = detail
            .replacingOccurrences(of: "[A]", with: "")
            .replacingOccurrences(of: "[/A]", with: "")
        let cookiePolicyRange = (detailText as NSString).range(of: cookiePolicy ?? "")
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        
        let normalDetailTextForegroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Text.secondary : UIColor.textForeground
        let detailTextAttributedString = NSMutableAttributedString(
            string: detailText,
            attributes: [
                .font: UIFont.preferredFont(style: .callout, weight: .regular),
                .foregroundColor: normalDetailTextForegroundColor,
                .paragraphStyle: paragraph
            ]
        )
        
        guard let urlLink = URL(string: cookiePolicyURLString) else {
            return detailTextAttributedString
        }
        
        let foregroundColor = UIColor.isDesignTokenEnabled() ? TokenColors.Link.primary : UIColor.turquoise
        detailTextAttributedString.addAttributes(
            [.foregroundColor: foregroundColor, .link: urlLink],
            range: cookiePolicyRange
        )
        
        return detailTextAttributedString
    }
}
