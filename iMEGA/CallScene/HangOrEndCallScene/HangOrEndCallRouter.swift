import SwiftUI
import MEGADomain
import MEGAPresentation
import MEGAData

protocol HangOrEndCallRouting: AnyObject, Routing {
    func leaveCall()
    func endCallForAll()
    func dismiss(animated flag: Bool, completion: (() -> Void)?)
}

final class HangOrEndCallRouter: HangOrEndCallRouting {
    private weak var presenter: UIViewController?
    private weak var baseViewController: UIViewController?
    private weak var meetingContainerViewModel: MeetingContainerViewModel?
    
    init(presenter: UIViewController,
         meetingContainerViewModel: MeetingContainerViewModel) {
        self.presenter = presenter
        self.meetingContainerViewModel = meetingContainerViewModel
    }
    
    func build() -> UIViewController {
        let analyticsEventUseCase = AnalyticsEventUseCase(
            repository: AnalyticsRepository(sdk: MEGASdkManager.sharedMEGASdk())
        )
        let viewModel = HangOrEndCallViewModel(router: self, analyticsEventUseCase: analyticsEventUseCase)
        let hangOrEndCallView = HangOrEndCallView(viewModel: viewModel)
        let hostingController = UIHostingController(rootView: hangOrEndCallView)
        hostingController.view.backgroundColor = .clear
        return hostingController
    }
    
    func start() {
        let viewController = build()
        baseViewController = viewController
        presenter?.present(viewController, animated: true)
    }
    
    func leaveCall() {
        baseViewController?.dismiss(animated: true, completion: {
            self.meetingContainerViewModel?.dispatch(.hangCall(presenter: nil, sender: nil))
        })
    }
    
    func endCallForAll() {
        baseViewController?.dismiss(animated: true, completion: {
            self.meetingContainerViewModel?.dispatch(.endCallForAll)
        })
    }
    
    func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        baseViewController?.dismiss(animated: flag, completion: completion)
    }
}

