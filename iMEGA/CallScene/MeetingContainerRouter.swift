
protocol MeetingContainerRouting: AnyObject, Routing {
    func showMeetingUI(containerViewModel: MeetingContainerViewModel)
    func dismiss(completion: (() -> Void)?)
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel)
    func showEndMeetingOptions(presenter: UIViewController, meetingContainerViewModel: MeetingContainerViewModel)
    func showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool, containerViewModel: MeetingContainerViewModel)
    func shareLink(presenter: UIViewController?, sender: AnyObject, link: String, completion: UIActivityViewController.CompletionWithItemsHandler?)
    func renameChat()
}

extension MeetingContainerRouting {
    func dismiss() {
        dismiss(completion: nil)
    }
}

final class MeetingContainerRouter: MeetingContainerRouting {
    private weak var presenter: UIViewController?
    private let chatRoom: ChatRoomEntity
    private let call: CallEntity
    private let isVideoEnabled: Bool
    private let isAnsweredFromCallKit: Bool
    private weak var baseViewController: UINavigationController?
    private weak var floatingPanelRouter: MeetingFloatingPanelRouting?
    private weak var meetingParticipantsRouter: MeetingParticipantsLayoutRouter?
    private var appBecomeActiveObserver: NSObjectProtocol?
    private weak var containerViewModel: MeetingContainerViewModel?
    
    init(presenter: UIViewController, chatRoom: ChatRoomEntity, call: CallEntity, isVideoEnabled: Bool, isAnsweredFromCallKit: Bool = false) {
        self.presenter = presenter
        self.chatRoom = chatRoom
        self.call = call
        self.isVideoEnabled = isVideoEnabled
        self.isAnsweredFromCallKit = isAnsweredFromCallKit
        
        // While the application becomes active, if the floating panel is not shown to the user. Show it.
        self.appBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            guard let self = self else { return }
            
            if let baseViewController = self.baseViewController,
               !baseViewController.navigationBar.isHidden,
               baseViewController.presentedViewController == nil,
               let containerViewModel = self.containerViewModel {
                self.showFloatingPanel(containerViewModel: containerViewModel)
            }
        }
    }
    
    deinit {
        if let appBecomeActiveObserver = appBecomeActiveObserver {
            NotificationCenter.default.removeObserver(appBecomeActiveObserver)
        }
    }
    
    func build() -> UIViewController {
        
        let chatRoomRepository = ChatRoomRepository(sdk: MEGASdkManager.sharedMEGAChatSdk())
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: chatRoomRepository,
                                               userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()))
        
        let viewModel = MeetingContainerViewModel(router: self,
                                                  chatRoom: chatRoom,
                                                  call: call,
                                                  callsUseCase: CallsUseCase(repository: CallsRepository()),
                                                  chatRoomUseCase: chatRoomUseCase,
                                                  callManagerUseCase: CallManagerUseCase(),
                                                  userUseCase: UserUseCase(repo: .live),
                                                  authUseCase: AuthUseCase(repo: AuthRepository(sdk: MEGASdkManager.sharedMEGASdk())),
                                                  isAnsweredFromCallKit: isAnsweredFromCallKit)
        let vc = MeetingContainerViewController(viewModel: viewModel)
        baseViewController = vc
        containerViewModel = viewModel
        return vc
    }
    
    func start() {
        let presentedViewController = UIApplication.mnz_presentingViewController()
        guard !(presentedViewController is MeetingContainerViewController) else {
            MEGALogDebug("Meeting UI is already presented")
            return
        }
        
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
        floatingPanelRouter?.dismiss(animated: false)
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
    
    func showOptionsMenu(presenter: UIViewController,
                         sender: UIBarButtonItem,
                         isMyselfModerator: Bool,
                         containerViewModel: MeetingContainerViewModel) {
                
        let optionsMenuRouter = MeetingOptionsMenuRouter(presenter: presenter, sender: sender, isMyselfModerator: isMyselfModerator, chatRoom: chatRoom, containerViewModel: containerViewModel)
        
        optionsMenuRouter.start()
    }
    
    func shareLink(presenter: UIViewController?, sender: AnyObject, link: String, completion: UIActivityViewController.CompletionWithItemsHandler?) {
        let activityViewController = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        if let barButtonSender = sender as? UIBarButtonItem {
            activityViewController.popoverPresentationController?.barButtonItem = barButtonSender
        } else if let buttonSender = sender as? UIButton {
            activityViewController.popoverPresentationController?.sourceView = buttonSender
            activityViewController.popoverPresentationController?.sourceRect = buttonSender.frame
        } else {
            MEGALogError("Parameter sender has a not allowed type")
            return
        }
        if #available(iOS 13.0, *) {
            activityViewController.overrideUserInterfaceStyle = .dark
        }
        activityViewController.completionWithItemsHandler = completion
        
        if let presenter = presenter {
            presenter.present(activityViewController, animated: true)
        } else {
            baseViewController?.present(activityViewController, animated: true)
        }
    }
    
    func renameChat() {
        meetingParticipantsRouter?.showRenameChatAlert()
    }
    
    //MARK:- Private methods.
    private func showCallViewRouter(containerViewModel: MeetingContainerViewModel) {
        guard let baseViewController = baseViewController else { return }
        let callViewRouter = MeetingParticipantsLayoutRouter(presenter: baseViewController,
                                            containerViewModel: containerViewModel,
                                            chatRoom: chatRoom,
                                            call: call,
                                            initialVideoCall: isVideoEnabled)
        callViewRouter.start()
        self.meetingParticipantsRouter = callViewRouter
    }
    
    private func showFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        guard let baseViewController = baseViewController else { return }
        let floatingPanelRouter = MeetingFloatingPanelRouter(presenter: baseViewController,
                                                             containerViewModel: containerViewModel,
                                                             chatRoom: chatRoom)
        floatingPanelRouter.start()
        self.floatingPanelRouter = floatingPanelRouter
    }
}
