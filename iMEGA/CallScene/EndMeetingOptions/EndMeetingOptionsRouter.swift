import PanModal

protocol EndMeetingOptionsRouting: Routing {
    func dismiss(completion: @escaping () -> Void)
    func showJoinMega()
    func showCreateAccount()
}

final class EndMeetingOptionsRouter: EndMeetingOptionsRouting {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private weak var meetingContainerViewModel: MeetingContainerViewModel?
    
    init(presenter: UIViewController, meetingContainerViewModel: MeetingContainerViewModel) {
        self.presenter = presenter
        self.meetingContainerViewModel = meetingContainerViewModel
    }
    
    func build() -> UIViewController {
        let viewModel = EndMeetingOptionsViewModel(router: self)
        return EndMeetingOptionsViewViewController(viewModel: viewModel)
    }
    
    func start() {
        guard let viewController = build() as? PanModalPresentable & UIViewController else { return }
        baseViewController = viewController
        presenter?.presentPanModal(viewController)
    }
    
    func dismiss(completion: @escaping () -> Void) {
        baseViewController?.dismiss(animated: true, completion: completion)
    }
    
    func showJoinMega() {
        meetingContainerViewModel?.dispatch(.dismissCall(completion: {
            JoinMegaRouter(presenter: UIApplication.mnz_presentingViewController()).start()
        }))
    }
    
    func showCreateAccount() {
        let createAccountNC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreateAccountNavigationControllerID")
        presenter?.present(createAccountNC, animated: true, completion: nil)
    }
}
