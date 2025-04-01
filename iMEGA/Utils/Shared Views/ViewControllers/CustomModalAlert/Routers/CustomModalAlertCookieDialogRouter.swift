import MEGAAppPresentation

final class CustomModalAlertCookieDialogRouter: Routing {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private let cookiePolicyURLString: String
    
    init(cookiePolicyURLString: String, presenter: UIViewController) {
        self.cookiePolicyURLString = cookiePolicyURLString
        self.presenter = presenter
    }
    
    func build() -> UIViewController {
        let viewController = CustomModalAlertViewController()
        viewController.configureForCookieDialog(
            type: .noAdsCookiePolicy,
            cookiePolicyURLString: cookiePolicyURLString,
            router: self
        )
        baseViewController = viewController
        return viewController
    }
    
    func start() {
        presenter?.present(build(), animated: true, completion: nil)
    }
    
    @MainActor
    func showAdMobConsentIfNeeded() async {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        await appDelegate.showAdMobConsentIfNeeded(isFromCookieDialog: true)
    }
    
    @MainActor
    func showCookieSettings() {
        let cookiePresenter = UIApplication.mnz_presentingViewController().presentedViewController == nil ? UIApplication.mnz_visibleViewController() : UIApplication.mnz_presentingViewController()
        CookieSettingsRouter(presenter: cookiePresenter, shouldShowAdMobConsent: true).start()
    }
    
    @MainActor
    func dismissView(completion: (() -> Void)?) {
        baseViewController?.dismiss(animated: true, completion: completion)
    }
}
