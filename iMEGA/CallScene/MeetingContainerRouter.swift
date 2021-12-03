
protocol MeetingContainerRouting: AnyObject, Routing {
    func showMeetingUI(containerViewModel: MeetingContainerViewModel)
    func dismiss(animated: Bool, completion: (() -> Void)?)
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel)
    func showEndMeetingOptions(presenter: UIViewController,
                               meetingContainerViewModel: MeetingContainerViewModel,
                               sender: UIButton)
    func showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool, containerViewModel: MeetingContainerViewModel)
    func shareLink(presenter: UIViewController?, sender: AnyObject, link: String, isGuestAccount: Bool, completion: UIActivityViewController.CompletionWithItemsHandler?)
    func renameChat()
    func showShareMeetingError()
    func enableSpeaker(_ enable: Bool)
    func didAddFirstParticipant()
}

final class MeetingContainerRouter: MeetingContainerRouting {
    private weak var presenter: UIViewController?
    private let chatRoom: ChatRoomEntity
    private let call: CallEntity
    private var isSpeakerEnabled: Bool
    private weak var baseViewController: UINavigationController?
    private weak var floatingPanelRouter: MeetingFloatingPanelRouting?
    private weak var meetingParticipantsRouter: MeetingParticipantsLayoutRouter?
    private var appBecomeActiveObserver: NSObjectProtocol?
    private weak var containerViewModel: MeetingContainerViewModel?
    private var chatRoomUseCase: ChatRoomUseCase {
        let chatRoomRepository = ChatRoomRepository(sdk: MEGASdkManager.sharedMEGAChatSdk())
        return ChatRoomUseCase(chatRoomRepo: chatRoomRepository,
                               userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()))
    }
    
    init(presenter: UIViewController,
         chatRoom: ChatRoomEntity,
         call: CallEntity,
         isSpeakerEnabled: Bool) {
        self.presenter = presenter
        self.chatRoom = chatRoom
        self.call = call
        self.isSpeakerEnabled = isSpeakerEnabled
        
        if let callId = MEGASdk.base64Handle(forUserHandle: call.callId) {
            MEGALogDebug("Adding notifications for the call \(callId)")
        }
        
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
        let viewModel = MeetingContainerViewModel(router: self,
                                                  chatRoom: chatRoom,
                                                  call: call,
                                                  callUseCase: CallUseCase(repository: CallRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk(), callActionManager: CallActionManager.shared)),
                                                  chatRoomUseCase: chatRoomUseCase,
                                                  callManagerUseCase: CallManagerUseCase(),
                                                  userUseCase: UserUseCase(repo: .live),
                                                  authUseCase: AuthUseCase(repo: AuthRepository(sdk: MEGASdkManager.sharedMEGASdk())))
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
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        if let callId = MEGASdk.base64Handle(forUserHandle: call.callId) {
            MEGALogDebug("Meeting ended for call \(callId) - dismiss called will animated \(animated)")
        }
        floatingPanelRouter?.dismiss(animated: animated)
        baseViewController?.dismiss(animated: animated, completion: completion)
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    func showShareMeetingError() {
        let customModalAlertViewController = CustomModalAlertViewController()
        customModalAlertViewController.image = Asset.Images.Chat.chatLinkCreation.image
        customModalAlertViewController.viewTitle = chatRoom.title
        customModalAlertViewController.firstButtonTitle = NSLocalizedString("close", comment: "")
        customModalAlertViewController.link = NSLocalizedString(chatRoom.chatType == .meeting ? "meetings.sharelink.Error" : "No chat link available.", comment: "")
        customModalAlertViewController.firstCompletion = { [weak customModalAlertViewController] in
            customModalAlertViewController?.dismiss(animated: true, completion: nil)
        }
        customModalAlertViewController.overrideUserInterfaceStyle = .dark
        UIApplication.mnz_presentingViewController().present(customModalAlertViewController, animated: true)
    }
    
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        if let floatingPanelRouter = floatingPanelRouter {
            floatingPanelRouter.dismiss()
            self.floatingPanelRouter = nil
        } else {
            showFloatingPanel(containerViewModel: containerViewModel)
        }
    }
    
    func showEndMeetingOptions(presenter: UIViewController,
                               meetingContainerViewModel: MeetingContainerViewModel,
                               sender: UIButton) {
        EndMeetingOptionsRouter(
            presenter: presenter,
            meetingContainerViewModel: meetingContainerViewModel,
            sender: sender
        ).start()
    }
    
    func showOptionsMenu(presenter: UIViewController,
                         sender: UIBarButtonItem,
                         isMyselfModerator: Bool,
                         containerViewModel: MeetingContainerViewModel) {
                
        let optionsMenuRouter = MeetingOptionsMenuRouter(presenter: presenter,
                                                         sender: sender,
                                                         isMyselfModerator: isMyselfModerator,
                                                         chatRoom: chatRoom,
                                                         containerViewModel: containerViewModel)
        optionsMenuRouter.start()
    }
    
    func shareLink(presenter: UIViewController?, sender: AnyObject, link: String, isGuestAccount: Bool, completion: UIActivityViewController.CompletionWithItemsHandler?) {
        let activityViewController = UIActivityViewController(activityItems: [link], applicationActivities: isGuestAccount ? nil : [SendToChatActivity(text: link)])
        if let barButtonSender = sender as? UIBarButtonItem {
            activityViewController.popoverPresentationController?.barButtonItem = barButtonSender
        } else if let buttonSender = sender as? UIButton {
            activityViewController.popoverPresentationController?.sourceView = buttonSender
            activityViewController.popoverPresentationController?.sourceRect = buttonSender.frame
        } else {
            MEGALogError("Parameter sender has a not allowed type")
            return
        }
        activityViewController.overrideUserInterfaceStyle = .dark
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
    
    func enableSpeaker(_ enable: Bool) {
        isSpeakerEnabled = enable
    }
    
    func didAddFirstParticipant() {
        meetingParticipantsRouter?.didAddFirstParticipant()
    }
    
    //MARK:- Private methods.
    private func showCallViewRouter(containerViewModel: MeetingContainerViewModel) {
        guard let baseViewController = baseViewController else { return }
        let callViewRouter = MeetingParticipantsLayoutRouter(presenter: baseViewController,
                                            containerViewModel: containerViewModel,
                                            chatRoom: chatRoom,
                                            call: call)
        callViewRouter.start()
        self.meetingParticipantsRouter = callViewRouter
    }
    
    private func showFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        // When toggling the chatroom instance might be outdated. So fetching it again.
        guard let baseViewController = baseViewController,
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatRoom.chatId) else {
            return
        }
        let floatingPanelRouter = MeetingFloatingPanelRouter(presenter: baseViewController,
                                                             containerViewModel: containerViewModel,
                                                             chatRoom: chatRoom,
                                                             isSpeakerEnabled: isSpeakerEnabled)
        floatingPanelRouter.start()
        self.floatingPanelRouter = floatingPanelRouter
    }
}
