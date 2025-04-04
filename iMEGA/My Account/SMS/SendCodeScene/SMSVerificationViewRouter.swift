import Foundation
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGADomain

@objc enum SMSVerificationType: Int {
    case unblockAccount
    case addPhoneNumber
}

final class SMSVerificationViewRouter: NSObject, SMSVerificationViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private weak var navigationController: UINavigationController?
    
    private let verificationType: SMSVerificationType
    private let onPhoneNumberVerified: (() -> Void)?
    
    @objc init(
        verificationType: SMSVerificationType,
        presenter: UIViewController,
        onPhoneNumberVerified: (() -> Void)? = nil
    ) {
        self.verificationType = verificationType
        self.presenter = presenter
        self.onPhoneNumberVerified = onPhoneNumberVerified
        super.init()
    }
    
    func build() -> UIViewController {
        let repo = SMSRepository.newRepo
        let smsUseCase = SMSUseCase(getSMSUseCase: GetSMSUseCase(repo: repo, l10n: L10nRepository()), checkSMSUseCase: CheckSMSUseCase(repo: repo))
        let vm = SMSVerificationViewModel(router: self,
                                          smsUseCase: smsUseCase,
                                          achievementUseCase: AchievementUseCase(repo: AchievementRepository.newRepo),
                                          authUseCase: DIContainer.authUseCase,
                                          verificationType: verificationType)
        
        let vc = UIStoryboard(name: "SMSVerification", bundle: nil).instantiateViewController(withIdentifier: "SMSVerificationViewControllerID") as! SMSVerificationViewController
        vc.viewModel = vm
        
        baseViewController = vc
        return vc
    }
    
    @objc func start() {
        let nav = SMSNavigationViewController(rootViewController: build())
        nav.modalPresentationStyle = .fullScreen
        navigationController = nav
        presenter?.present(nav, animated: true, completion: nil)
    }
    
    // MARK: - UI Actions
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func goToRegionList(_ list: [SMSRegion], onRegionSelected: @escaping (SMSRegion) -> Void) {
        let router = RegionListViewRouter(navigationController: navigationController, regionCodes: list, onRegionSelected: onRegionSelected)
        router.start()
    }
    
    func goToVerificationCode(forPhoneNumber number: String, withRegionCode regionCode: RegionCode) {
        let router = VerificationCodeViewRouter(
            navigationController: navigationController,
            verificationType: verificationType,
            phoneNumber: number,
            regionCode: regionCode,
            onPhoneNumberVerified: { self.onPhoneNumberVerified?() }
        )
        router.start()
    }
}
