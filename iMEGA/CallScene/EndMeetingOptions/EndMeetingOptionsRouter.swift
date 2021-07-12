import PanModal

protocol EndMeetingOptionsRouting: Routing {
    func dismiss(completion: @escaping () -> Void)
    func showJoinMega()
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
        viewController.modalPresentationStyle = .custom
        viewController.modalPresentationCapturesStatusBarAppearance = true
        viewController.transitioningDelegate = PanModalPresentationDelegate.default
        baseViewController = viewController
        presenter?.present(viewController, animated: true)
    }
    
    func dismiss(completion: @escaping () -> Void) {
        baseViewController?.dismiss(animated: true, completion: completion)
    }
    
    func showJoinMega() {
        meetingContainerViewModel?.dispatch(.endGuestUserCall {
            JoinMegaRouter(presenter: UIApplication.mnz_presentingViewController()).start()
        })
    }
}
