
@objc final class CallViewRouter: NSObject, CallViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UIViewController?
    private weak var navigationController: UINavigationController?
    private weak var containerViewModel: MeetingContainerViewModel?
    private(set) weak var viewModel: CallViewModel?
    
    private let chatRoom: ChatRoomEntity
    private var initialVideoCall: Bool

    init(presenter: UIViewController, containerViewModel: MeetingContainerViewModel, chatRoom: ChatRoomEntity, initialVideoCall: Bool = false) {
        self.presenter = presenter
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.initialVideoCall = initialVideoCall
        super.init()
    }
    
    func build() -> UIViewController {
        guard let containerViewModel = containerViewModel else { return UIViewController() }
        let vm = CallViewModel(router: self, containerViewModel: containerViewModel, callManager: CallManagerUseCase(), callsUseCase: CallsUseCase(repository: CallsRepository()), userAttributesUseCase: UserAttributesUseCase(repository: UserAttributesRepository()), captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()), chatRoom: chatRoom, initialVideoCall: initialVideoCall)
        
        let nc = UIStoryboard(name: "Calls", bundle: nil).instantiateViewController(withIdentifier: "CallNavigationControllerID") as! UINavigationController
        let vc = nc.topViewController as! CallsViewController
        vc.viewModel = vm
        baseViewController = vc
        viewModel = vm
        return vc
    }
    
    @objc func start() {
        guard let nav = build().navigationController, let presenter = presenter else { return }
        navigationController = nav
        
        presenter.addChild(nav)
        presenter.view.addSubview(nav.view)
        nav.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            nav.view.leadingAnchor.constraint(equalTo: presenter.view.leadingAnchor),
            nav.view.trailingAnchor.constraint(equalTo: presenter.view.trailingAnchor),
            nav.view.topAnchor.constraint(equalTo: presenter.view.topAnchor),
            nav.view.bottomAnchor.constraint(equalTo: presenter.view.bottomAnchor)
        ])
        nav.didMove(toParent: presenter)
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
