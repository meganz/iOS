import MEGAPresentation
import PanModal

protocol EndMeetingOptionsRouting: Routing {
    func dismiss(completion: @escaping () -> Void)
    func showJoinMega()
}

final class EndMeetingOptionsRouter: EndMeetingOptionsRouting {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private weak var meetingContainerViewModel: MeetingContainerViewModel?
    private weak var sender: UIButton?
    
    init(presenter: UIViewController,
         meetingContainerViewModel: MeetingContainerViewModel,
         sender: UIButton) {
        self.presenter = presenter
        self.meetingContainerViewModel = meetingContainerViewModel
        self.sender = sender
    }
    
    func build() -> UIViewController {
        let viewModel = EndMeetingOptionsViewModel(router: self)
        return EndMeetingOptionsViewViewController(viewModel: viewModel)
    }
    
    func start() {
        guard let viewController = build() as? PanModalPresentable & UIViewController else { return }
        if let sender = sender, UIDevice.current.iPad {
            viewController.modalPresentationStyle = .popover
            viewController.popoverPresentationController?.sourceView = sender
            viewController.popoverPresentationController?.sourceRect = sender.frame
            viewController.popoverPresentationController?.backgroundColor = .mnz_black1C1C1E()
        } else {
            viewController.modalPresentationStyle = .custom
            viewController.modalPresentationCapturesStatusBarAppearance = true
            viewController.transitioningDelegate = PanModalPresentationDelegate.default
        }
        baseViewController = viewController
        presenter?.present(viewController, animated: true)
    }
    
    func dismiss(completion: @escaping () -> Void) {
        baseViewController?.dismiss(animated: true, completion: completion)
    }
    
    func showJoinMega() {
        meetingContainerViewModel?.dispatch(.endGuestUserCall {
            EncourageGuestUserToJoinMegaRouter(presenter: UIApplication.mnz_presentingViewController()).start()
        })
    }
}
