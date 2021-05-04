
protocol MeetingContainerRouting: Routing {
    func showMeetingUI(containerViewModel: MeetingContainerViewModel)
    func dismiss(completion: (() -> Void)?)
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel)
    func showEndMeetingOptions(presenter: UIViewController, meetingContainerViewModel: MeetingContainerViewModel)
}

final class MeetingContainerRouter: MeetingContainerRouting {
    private weak var presenter: UIViewController?
    private let chatRoom: ChatRoomEntity
    private let call: CallEntity
    private let isVideoEnabled: Bool
    
    private weak var baseViewController: UIViewController?
    private weak var floatingPanelRouter: MeetingFloatingPanelRouting?
    private weak var callViewRouter: CallViewRouter?
    
    init(presenter: UIViewController, chatRoom: ChatRoomEntity, call: CallEntity, isVideoEnabled: Bool) {
        self.presenter = presenter
        self.chatRoom = chatRoom
        self.call = call
        self.isVideoEnabled = isVideoEnabled
    }
    
    func build() -> UIViewController {
        let viewModel = MeetingContainerViewModel(router: self,
                                                  chatRoom: chatRoom,
                                                  call: call,
                                                  callsUseCase: CallsUseCase(repository: CallsRepository()),
                                                  callManagerUseCase: CallManagerUseCase(),
                                                  userUseCase: UserUseCase(repo: .live))
        let vc = MeetingContainerViewController(viewModel: viewModel)
        baseViewController = vc
        return vc
    }
    
    func start() {
        let vc = build()
        vc.modalPresentationStyle = .fullScreen
        presenter?.present(vc, animated: false) {
            guard let vc = vc as? MeetingContainerViewController else { return }
            vc.configureUI()
        }
    }
    
    func showMeetingUI(containerViewModel: MeetingContainerViewModel) {
        showCallViewRouter(containerViewModel: containerViewModel)
        showFloatingPanel(containerViewModel: containerViewModel)
    }
    
    func dismiss(completion: (() -> Void)?) {
        floatingPanelRouter?.dismiss()
        baseViewController?.dismiss(animated: false, completion: completion)
    }
    
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        if let floatingPanelRouter = floatingPanelRouter {
            floatingPanelRouter.dismiss()
            self.floatingPanelRouter = nil
        } else {
            showFloatingPanel(containerViewModel: containerViewModel)
        }
    }
    
    func showEndMeetingOptions(presenter: UIViewController, meetingContainerViewModel: MeetingContainerViewModel) {
        EndMeetingOptionsRouter(presenter: presenter, meetingContainerViewModel: meetingContainerViewModel).start()
    }
    
    //MARK:- Private methods.
    private func showCallViewRouter(containerViewModel: MeetingContainerViewModel) {
        guard let baseViewController = baseViewController else { return }
        let callViewRouter = CallViewRouter(presenter: baseViewController,
                                            containerViewModel: containerViewModel,
                                            chatRoom: chatRoom,
                                            initialVideoCall: isVideoEnabled)
        callViewRouter.start()
        self.callViewRouter = callViewRouter
    }
    
    private func showFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        guard let baseViewController = baseViewController else { return }
        let floatingPanelRouter = MeetingFloatingPanelRouter(presenter: baseViewController,
                                                             containerViewModel: containerViewModel,
                                                             chatRoom: chatRoom,
                                                             call: call,
                                                             isVideoEnabled: isVideoEnabled)
        floatingPanelRouter.start()
        self.floatingPanelRouter = floatingPanelRouter
    }
}
