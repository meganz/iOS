import Accounts
import Foundation
import MEGAAppPresentation
import MEGADesignToken
import MEGADomain
import MEGAL10n
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
    
    func configureForCookieDialog(
        type: CookieDialogType,
        cookiePolicyURLString: String,
        router: CustomModalAlertCookieDialogRouter
    ) {
        image = UIImage.cookie
        viewTitle = Strings.Localizable.Dialog.Cookies.Title.manageCookies
        detailAttributedTextWithLink = detailTextAttributedString(detail: type.description, cookiePolicyURLString: cookiePolicyURLString)
        
        firstButtonTitle = Strings.Localizable.Dialog.Cookies.accept
        secondButtonTitle = Strings.Localizable.General.cookieSettings
        
        firstCompletion = { [weak self] in
            router.dismissView {
                Task { @MainActor in
                    await self?.acceptCookies(router: router)
                    await router.showAdMobConsentIfNeeded()
                }
            }
        }
        
        secondCompletion = {
            router.dismissView {
                router.showCookieSettings()
            }
        }
        
        viewModel = makeCookieDialogViewModel()
    }
    
    private func acceptCookies(router: CustomModalAlertCookieDialogRouter) async {
        do {
            let cookieSettingsUseCase = CookieSettingsUseCase(repository: CookieSettingsRepository.newRepo)
            
            let cookieSettings = CookiesBitmap.all
            
            _ = try await cookieSettingsUseCase.setCookieSettings(with: cookieSettings.rawValue)
            router.dismissView(completion: nil)
        } catch {
            SVProgressHUD.showError(withStatus: error.localizedDescription)
        }
    }
    
    private func makeCookieDialogViewModel() -> CustomModalAlertViewModel {
        let invalidLinkTapAction = {
            self.showSnackBar(snackBar: SnackBar(message: Strings.Localizable.somethingWentWrong))
        }
        
        return CustomModalAlertViewModel(
            invalidLinkTapAction: invalidLinkTapAction,
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
        
        let normalDetailTextForegroundColor = TokenColors.Text.secondary
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
        
        let foregroundColor = TokenColors.Link.primary
        detailTextAttributedString.addAttributes(
            [.foregroundColor: foregroundColor, .link: urlLink],
            range: cookiePolicyRange
        )
        
        return detailTextAttributedString
    }
}
