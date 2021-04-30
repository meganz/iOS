
protocol MeetingContainerRouting: Routing {
    func showMeetingUI(containerViewModel: MeetingContainerViewModel)
    func dismiss()
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel)
}

final class MeetingContainerRouter: MeetingContainerRouting {
    private weak var presenter: UIViewController?
    private let chatRoom: ChatRoomEntity
    private let call: CallEntity
    
    private weak var baseViewController: UIViewController?
    private weak var floatingPanelRouter: MeetingFloatingPanelRouting?
    private weak var callViewRouter: CallViewRouter?
    
    init(presenter: UIViewController, chatRoom: ChatRoomEntity, call: CallEntity) {
        self.presenter = presenter
        self.chatRoom = chatRoom
        self.call = call
    }
    
    func build() -> UIViewController {
        let viewModel = MeetingContainerViewModel(router: self,
                                                  chatRoom: chatRoom,
                                                  call: call,
                                                  callsUseCase: CallsUseCase(repository: CallsRepository()),
                                                  callManagerUseCase: CallManagerUseCase())
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
    
    func dismiss() {
        floatingPanelRouter?.dismiss()
        baseViewController?.dismiss(animated: false)
    }
    
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        if let floatingPanelRouter = floatingPanelRouter {
            floatingPanelRouter.dismiss()
            self.floatingPanelRouter = nil
        } else {
            showFloatingPanel(containerViewModel: containerViewModel)
        }
    }
    
    //MARK:- Private methods.
    private func showCallViewRouter(containerViewModel: MeetingContainerViewModel) {
        guard let baseViewController = baseViewController else { return }
        let callViewRouter = CallViewRouter(presenter: baseViewController,
                                            containerViewModel: containerViewModel,
                                            chatRoom: chatRoom,
                                            initialVideoCall: false)
        callViewRouter.start()
        self.callViewRouter = callViewRouter
    }
    
    private func showFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        guard let baseViewController = baseViewController else { return }
        let floatingPanelRouter = MeetingFloatingPanelRouter(presenter: baseViewController,
                                                             containerViewModel: containerViewModel,
                                                             chatRoom: chatRoom,
                                                             call: call)
        floatingPanelRouter.start()
        self.floatingPanelRouter = floatingPanelRouter
    }
}
