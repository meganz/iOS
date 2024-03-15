import MEGADomain
import MEGAL10n
import MEGAPresentation
import MEGASDKRepo

class CallWillEndAlertRouter: CallWillEndAlertRouting {
    private var baseViewController: UIViewController
    private var callWillEndAlert: UIViewController?
    private var viewModel: CallWillEndAlertViewModel?
    private let remainingSeconds: Int
    private let isCallUIVisible: Bool
    private var dismissCompletion: ((Int) -> Void)?
    
    init(baseViewController: UIViewController,
         remainingSeconds: Int,
         isCallUIVisible: Bool,
         dismissCompletion: ((Int) -> Void)?) {
        self.baseViewController = baseViewController
        self.remainingSeconds = remainingSeconds
        self.isCallUIVisible = isCallUIVisible
        self.dismissCompletion = dismissCompletion
    }
    
    func build() -> UIViewController {
        viewModel = CallWillEndAlertViewModel(
            router: self,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            remainingSeconds: remainingSeconds,
            dismissCompletion: dismissCompletion
        )
        
        return createCallWillEndAlert()
    }
    
    func start() {
        callWillEndAlert = build()
        viewModel?.viewReady()
    }
    
    private func createCallWillEndAlert() -> UIAlertController {
        let alert = UIAlertController(
            title: Strings.Localizable.Calls.FreePlanLimitWarning.DurationLimitAlert.title(remainingSeconds),
            message: Strings.Localizable.Calls.FreePlanLimitWarning.DurationLimitAlert.message,
            preferredStyle: .alert
        )
        
        if isCallUIVisible {
            alert.overrideUserInterfaceStyle = .dark
        }
        
        return alert
    }
    
    func showCallWillEndAlert(upgradeAction: @escaping () -> Void, notNowAction: @escaping () -> Void) {
        guard let alert = callWillEndAlert as? UIAlertController, let presenter = baseViewController.presenterViewController() else { return }
        
        let preferredAction = UIAlertAction(
            title: Strings.Localizable.Calls.FreePlanLimitWarning.DurationLimitAlert.notNow,
            style: .default
        ) { [weak self] _ in
            notNowAction()
            self?.callWillEndAlert = nil
        }
        
        alert.addAction(preferredAction)
        
        alert.preferredAction = preferredAction
        
        alert.addAction(
            UIAlertAction(
                title: Strings.Localizable.Calls.FreePlanLimitWarning.DurationLimitAlert.upgrade,
                style: .default
            ) { [weak self] _ in
                upgradeAction()
                self?.callWillEndAlert = nil
            }
        )
        
        dismissAlertController {
            presenter.present(alert, animated: true)
        }
    }

    func updateCallWillEndAlertTitle(remainingMinutes: Int) {
        callWillEndAlert?.title = Strings.Localizable.Calls.FreePlanLimitWarning.DurationLimitAlert.title(remainingMinutes)
    }
    
    func showUpgradeAccount(_ account: AccountDetailsEntity) {
        guard let presenter = baseViewController.presenterViewController() else { return }
        UpgradeAccountPlanRouter(presenter: presenter, accountDetails: account).start()
    }
    
    func dismissCallWillEndAlertIfNeeded() {
        callWillEndAlert?.dismiss(animated: false)
    }
    
    private func dismissAlertController(completion: @escaping () -> Void) {
        guard let presentedViewController = baseViewController.presenterViewController()?.presentedViewController,
              presentedViewController.isKind(of: UIAlertController.self) else {
            completion()
            return
        }
        presentedViewController.dismiss(animated: true) {
            completion()
        }
    }
}
