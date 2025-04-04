import Foundation
import MEGAAppSDKRepo
import MEGADomain

@objc final class AddPhoneNumberRouter: NSObject, AddPhoneNumberRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private let hideDontShowAgain: Bool
    
    @objc init(hideDontShowAgain: Bool, presenter: UIViewController) {
        self.hideDontShowAgain = hideDontShowAgain
        self.presenter = presenter
        super.init()
    }
    
    func build() -> UIViewController {
        let vm = AddPhoneNumberViewModel(router: self, achievementUseCase: AchievementUseCase(repo: AchievementRepository.newRepo), hideDontShowAgain: hideDontShowAgain)
        
        let vc = UIStoryboard(name: "SMSVerification", bundle: nil).instantiateViewController(withIdentifier: "AddPhoneNumberViewControllerID") as! AddPhoneNumberViewController
        vc.modalPresentationStyle = .fullScreen
        
        vc.viewModel = vm
        baseViewController = vc
        return vc
    }
    
    @objc func start() {
        UIApplication.mnz_presentingViewController().present(build(), animated: true, completion: nil)
    }
    
    // MARK: UI Actions
    func goToVerification() {
        baseViewController?.dismiss(animated: true) {
            guard let presenter = self.presenter else { return }
            SMSVerificationViewRouter(verificationType: .addPhoneNumber, presenter: presenter).start()
        }
    }
    
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
}
