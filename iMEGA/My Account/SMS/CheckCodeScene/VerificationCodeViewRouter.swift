import Foundation
import MEGADomain
import MEGAData

final class VerificationCodeViewRouter: VerificationCodeViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var navigationController: UINavigationController?
    
    private let verificationType: SMSVerificationType
    private let phoneNumber: String
    
    init(navigationController: UINavigationController?, verificationType: SMSVerificationType, phoneNumber: String) {
        self.navigationController = navigationController
        self.verificationType = verificationType
        self.phoneNumber = phoneNumber
    }
    
    func build() -> UIViewController {
        let vm = VerificationCodeViewModel(router: self,
                                           checkSMSUseCase: CheckSMSUseCase(repo: SMSRepository.newRepo),
                                           authUseCase: AuthUseCase(repo: AuthRepository(sdk: MEGASdk.shared), credentialRepo: CredentialRepository.newRepo),
                                           verificationType: verificationType,
                                           phoneNumber: phoneNumber)
        
        let vc = UIStoryboard(name: "SMSVerification", bundle: nil).instantiateViewController(withIdentifier: "VerificationCodeViewControllerID") as! VerificationCodeViewController
        
        vc.viewModel = vm
        baseViewController = vc
        return vc
    }
    
    func start() {
        navigationController?.pushViewController(build(), animated: true)
    }
    
    // MARK: - UI Actions
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
