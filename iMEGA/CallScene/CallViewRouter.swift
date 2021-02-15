
@objc final class CallViewRouter: NSObject, CallViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private weak var navigationController: UINavigationController?
    
    private let chatRoom: MEGAChatRoom
    private let callType: CallType
    private var initialVideoCall: Bool

    @objc init(presenter: UIViewController, chatRoom: MEGAChatRoom, callType: CallType, initialVideoCall: Bool = false) {
        self.presenter = presenter
        self.chatRoom = chatRoom
        self.callType = callType
        self.initialVideoCall = initialVideoCall
        super.init()
    }
    
    func build() -> UIViewController {
        let vm = CallViewModel(router: self, callManager: CallManagerUseCase(), callsUseCase: CallsUseCase(repository: CallsRepository()), userAttributesUseCase: UserAttributesUseCase(repository: UserAttributesRepository()), chatRoom: chatRoom, callType: callType, initialVideoCall: initialVideoCall)
        
        let nc = UIStoryboard(name: "Calls", bundle: nil).instantiateViewController(withIdentifier: "CallNavigationControllerID") as! UINavigationController
        let vc = nc.topViewController as! CallsViewController
        vc.viewModel = vm
        baseViewController = vc
        
        return vc
    }
    
    @objc func start() {
        guard let nav = build().navigationController else { return }
        navigationController = nav
        nav.modalPresentationStyle = .fullScreen
        nav.modalTransitionStyle = .crossDissolve
        presenter?.present(nav, animated: true, completion: nil)
    }
    
    func dismiss() {
        navigationController?.dismiss(animated: true, completion: nil)
    }

    func dismissAndShowPasscodeIfNeeded() {
        navigationController?.dismiss(animated: true, completion: {
            if UserDefaults.standard.bool(forKey: "presentPasscodeLater") && LTHPasscodeViewController.doesPasscodeExist() {
                LTHPasscodeViewController.sharedUser()?.showLockScreenOver(UIApplication.mnz_visibleViewController().view, withAnimation: true, withLogout: false, andLogoutTitle: nil)
                UserDefaults.standard.set(false, forKey: "presentPasscodeLater")
            }
            LTHPasscodeViewController.sharedUser()?.enablePasscodeWhenApplicationEntersBackground()
        })
    }
}
