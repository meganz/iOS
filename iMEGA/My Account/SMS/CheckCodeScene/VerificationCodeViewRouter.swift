import Foundation
import MEGAAppPresentation
import MEGADomain
import MEGASDKRepo

final class VerificationCodeViewRouter: VerificationCodeViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    
    private let verificationType: SMSVerificationType
    private let phoneNumber: String
    private let regionCode: RegionCode
    private let onPhoneNumberVerified: () -> Void
    
    init(
        navigationController: UINavigationController?,
        verificationType: SMSVerificationType,
        phoneNumber: String,
        regionCode: RegionCode,
        onPhoneNumberVerified: @escaping () -> Void
    ) {
        self.navigationController = navigationController
        self.verificationType = verificationType
        self.phoneNumber = phoneNumber
        self.regionCode = regionCode
        self.onPhoneNumberVerified = onPhoneNumberVerified
    }
    
    func build() -> UIViewController {
        let vm = VerificationCodeViewModel(router: self,
                                           checkSMSUseCase: CheckSMSUseCase(repo: SMSRepository.newRepo),
                                           authUseCase: DIContainer.authUseCase,
                                           verificationType: verificationType,
                                           phoneNumber: phoneNumber,
                                           regionCode: regionCode)
        
        let vc = UIStoryboard(name: "SMSVerification", bundle: nil).instantiateViewController(withIdentifier: "VerificationCodeViewControllerID") as! VerificationCodeViewController
        
        vc.viewModel = vm
        baseViewController = vc
        return vc
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    // MARK: - UI Actions
    func phoneNumberVerified() {
        onPhoneNumberVerified()
        dismiss()
    }

    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    func goToOnboarding() {
        dismiss()
        (UIApplication.shared.delegate as? AppDelegate)?.showOnboarding(completion: nil)
    }
}
