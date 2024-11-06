import ChatRepo
import Combine
import MEGAAnalyticsiOS
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGAPresentation
import MEGASDKRepo

@MainActor
protocol MeetingContainerRouting: AnyObject, Routing {
    func showMeetingUI(containerViewModel: MeetingContainerViewModel)
    func dismiss(animated: Bool, completion: (() -> Void)?)
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel)
    func showOptionsMenu(presenter: UIViewController, sender: UIBarButtonItem, isMyselfModerator: Bool, containerViewModel: MeetingContainerViewModel)
    func showShareChatLinkActivity(presenter: UIViewController?, sender: AnyObject, link: String, metadataItemSource: ChatLinkPresentationItemSource, isGuestAccount: Bool, completion: UIActivityViewController.CompletionWithItemsHandler?)
    func renameChat()
    func showShareMeetingError()
    func displayParticipantInMainView(_ participant: CallParticipantEntity)
    func didDisplayParticipantInMainView(_ participant: CallParticipantEntity)
    func didSwitchToGridView()
    func showEndCallDialog(endCallCompletion: @escaping () -> Void, stayOnCallCompletion: (() -> Void)?)
    func removeEndCallDialog(finishCountDown: Bool, completion: (() -> Void)?)
    func showJoinMegaScreen()
    func selectWaitingRoomList(containerViewModel: MeetingContainerViewModel)
    func showScreenShareWarning()
    func showMutedMessage(by name: String)
    func showProtocolErrorAlert()
    func showUsersLimitErrorAlert()
    func showCallWillEndAlert(timeToEndCall: Double, completion: ((Double) -> Void)?)
    func showUpgradeToProDialog(_ account: AccountDetailsEntity)
    func transitionToLongForm()
    func showFloatingPanelIfNeeded(
        containerViewModel: MeetingContainerViewModel,
        completion: @escaping () -> Void
    )
    func hideSnackBar()
    var floatingPanelShown: Bool { get }
    func notifyFloatingPanelInviteParticipants()
    func showShareLinkOptionsAlert(_ shareLinkOptions: ShareLinkOptions)
    func sendLinkToChat(_ link: String)
    func showLinkCopied()
}

final class MeetingContainerRouter: MeetingContainerRouting {
    
    private weak var presenter: UIViewController?
    private let chatRoom: ChatRoomEntity
    private let call: CallEntity
    private var selectWaitingRoomList: Bool
    private weak var baseViewController: UINavigationController?
    private weak var floatingPanelRouter: (any MeetingFloatingPanelRouting)?
    private var meetingParticipantsRouter: (any MeetingParticipantsLayoutRouting)?
    private var appDidBecomeActiveSubscription: AnyCancellable?
    private weak var containerViewModel: MeetingContainerViewModel?
    private var endCallDialog: EndCallDialog?
    private lazy var chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
    private let layoutUpdateChannel = ParticipantLayoutUpdateChannel()
    private var createCallUseCase: CallUseCase<CallRepository> {
        let callRepository = CallRepository.newRepo
        return CallUseCase(repository: callRepository)
    }
    private let tracker: any AnalyticsTracking
    static var isAlreadyPresented: Bool {
        MeetingContainerViewController.isAlreadyPresented
    }
    
    private var sendToChatWrapper: SendToChatWrapper?
    
    @PreferenceWrapper(key: .isCallUIVisible, defaultValue: false, useCase: PreferenceUseCase.default)
    var isCallUIVisible: Bool
    
    init(
        presenter: UIViewController,
        chatRoom: ChatRoomEntity,
        call: CallEntity,
        selectWaitingRoomList: Bool = false,
        tracker: some AnalyticsTracking = DIContainer.tracker
    ) {
        self.presenter = presenter
        self.chatRoom = chatRoom
        self.call = call
        self.selectWaitingRoomList = selectWaitingRoomList
        self.tracker = tracker
        if let callId = MEGASdk.base64Handle(forUserHandle: call.callId) {
            MEGALogDebug("Adding notifications for the call \(callId)")
        }
        
        subscribeToAppDidBecomeActiveSubscription(withChatRoom: chatRoom)
    }
    
    func build() -> UIViewController {
        let meetingNoUserJoinedUseCase = MeetingNoUserJoinedUseCase(repository: MeetingNoUserJoinedRepository.sharedRepo)
        let analyticsEventUseCase = AnalyticsEventUseCase(repository: AnalyticsRepository(sdk: .shared))
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        let viewModel = MeetingContainerViewModel(
            router: self,
            chatRoom: chatRoom,
            callUseCase: createCallUseCase,
            chatRoomUseCase: chatRoomUseCase,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            authUseCase: DIContainer.authUseCase,
            noUserJoinedUseCase: meetingNoUserJoinedUseCase,
            analyticsEventUseCase: analyticsEventUseCase,
            megaHandleUseCase: megaHandleUseCase,
            callManager: CallKitCallManager.shared
        )
        let vc = MeetingContainerViewController(viewModel: viewModel)
        baseViewController = vc
        containerViewModel = viewModel
        return vc
    }
    
    func start() {
        guard Self.isAlreadyPresented == false else {
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
        showCallViewRouter(
            containerViewModel: containerViewModel
        )
        showFloatingPanel(
            containerViewModel: containerViewModel,
            completion: {}
        )
        isCallUIVisible = true
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        if let callId = MEGASdk.base64Handle(forUserHandle: call.callId) {
            MEGALogDebug("Meeting ended for call \(callId) - dismiss called will animated \(animated)")
        }
        
        dismissWaitingRoomAlertPresentedIfNeeded { [weak self] in
            guard let self else { return }
            dismissCallUI(animated: animated, completion: completion)
        }
    }
    
    func showShareMeetingError() {
        DispatchQueue.main.async { [weak self] in
            guard let self, CustomModalAlertViewController.isAlreadyPresented == false else { return }
            
            let customModalAlertViewController = CustomModalAlertViewController()
            customModalAlertViewController.image = UIImage(resource: .chatLinkCreation)
            customModalAlertViewController.viewTitle = chatRoom.title
            customModalAlertViewController.firstButtonTitle = Strings.Localizable.close
            customModalAlertViewController.link = chatRoom.chatType == .meeting ? Strings.Localizable.Meetings.Sharelink.error : Strings.Localizable.noChatLinkAvailable
            customModalAlertViewController.firstCompletion = { [weak customModalAlertViewController] in
                customModalAlertViewController?.dismiss(animated: true, completion: nil)
            }
            customModalAlertViewController.overrideUserInterfaceStyle = .dark
            UIApplication.mnz_presentingViewController().present(customModalAlertViewController, animated: true)
        }
    }
    
    func toggleFloatingPanel(containerViewModel: MeetingContainerViewModel) {
        if let floatingPanelRouter = floatingPanelRouter {
            floatingPanelRouter.dismiss()
            self.floatingPanelRouter = nil
        } else {
            showFloatingPanel(
                containerViewModel: containerViewModel,
                completion: {}
            )
        }
    }
    
    func showFloatingPanelIfNeeded(
        containerViewModel: MeetingContainerViewModel,
        completion: @escaping () -> Void
    ) {
        if floatingPanelRouter == nil {
            showFloatingPanel(containerViewModel: containerViewModel, completion: completion)
        } else {
            completion()
        }
    }
    
    func selectWaitingRoomList(containerViewModel: MeetingContainerViewModel) {
        guard floatingPanelRouter != nil else {
            selectWaitingRoomList = true
            showFloatingPanel(containerViewModel: containerViewModel, completion: {})
            meetingParticipantsRouter?.showNavigation()
            return
        }
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
    
    func showShareChatLinkActivity(presenter: UIViewController?, sender: AnyObject, link: String, metadataItemSource: ChatLinkPresentationItemSource, isGuestAccount: Bool, completion: UIActivityViewController.CompletionWithItemsHandler?) {
        DispatchQueue.main.async { [weak self] in
            guard UIActivityViewController.isAlreadyPresented == false else {
                MEGALogDebug("Meeting link Share controller is already presented.")
                return
            }
            
            let activityViewController = UIActivityViewController(activityItems: [metadataItemSource], applicationActivities: isGuestAccount ? nil : [SendToChatActivity(text: link)])
            
            if let buttonSender = sender as? UIButton {
                activityViewController.popoverPresentationController?.sourceView = buttonSender
                activityViewController.popoverPresentationController?.sourceRect = buttonSender.frame
            } else {
                activityViewController.popoverPresentationController?.sourceView = self?.sourceViewForiPad()
            }
            
            activityViewController.overrideUserInterfaceStyle = .dark
            activityViewController.completionWithItemsHandler = completion
            
            if let presenter = presenter {
                presenter.present(activityViewController, animated: true)
            } else {
                UIApplication.mnz_presentingViewController()
                    .present(activityViewController, animated: true)
            }
        }
    }
    
    func renameChat() {
        meetingParticipantsRouter?.showRenameChatAlert()
    }
    
    func displayParticipantInMainView(_ participant: CallParticipantEntity) {
        meetingParticipantsRouter?.pinParticipantAsSpeaker(participant)
    }
    
    func didDisplayParticipantInMainView(_ participant: CallParticipantEntity) {
        floatingPanelRouter?.didDisplayParticipantInMainView(participant)
    }
    
    func didSwitchToGridView() {
        floatingPanelRouter?.didSwitchToGridView()
    }
    
    func showEndCallDialog(endCallCompletion: @escaping () -> Void, stayOnCallCompletion: (() -> Void)? = nil) {
        guard self.endCallDialog == nil else { return }
        
        let endCallDialog = EndCallDialog(forceDarkMode: true) { [weak self] in
            self?.endCallDialog = nil
            self?.meetingParticipantsRouter?.endCallEndCountDownTimer()
            stayOnCallCompletion?()
        } endCallAction: { [weak self] in
            self?.endCallDialog = nil
            endCallCompletion()
        }
        
        meetingParticipantsRouter?.startCallEndCountDownTimer()
        endCallDialog.show()
        self.endCallDialog = endCallDialog
    }
    
    func removeEndCallDialog(finishCountDown: Bool = true, completion: (() -> Void)?) {
        guard endCallDialog != nil else {
            meetingParticipantsRouter?.endCallEndCountDownTimer()
            completion?()
            return
        }
        
        if finishCountDown {
            meetingParticipantsRouter?.endCallEndCountDownTimer()
        }
        endCallDialog?.dismiss(animated: true) { [weak self] in
            self?.endCallDialog = nil
            completion?()
        }
    }
    
    func showJoinMegaScreen() {
        EncourageGuestUserToJoinMegaRouter(presenter: UIApplication.mnz_presentingViewController()).start()
    }
    
    func showScreenShareWarning() {
        SVProgressHUD.showError(withStatus: Strings.Localizable.Calls.ScreenShare.Waring.title)
    }
    
    func showMutedMessage(by name: String) {
        SVProgressHUD.showSuccess(withStatus: Strings.Localizable.Calls.ParticipantsInCall.mutedBy(name))
    }
    
    func showProtocolErrorAlert() {
        guard let presenter else { return }
        let alert = UIAlertController(
            title: Strings.Localizable.Calls.SfuOutdated.UpdateAppAlert.title,
            message: Strings.Localizable.Calls.SfuOutdated.UpdateAppAlert.message,
            preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: Strings.Localizable.Calls.SfuOutdated.UpdateAppAlert.Button.skip, style: .default)
        )
        let preferredAction = UIAlertAction(
            title: Strings.Localizable.Calls.SfuOutdated.UpdateAppAlert.Button.update, style: .default) { _ in
                if let url = URL(string: "itms-apps://itunes.apple.com/app/id706857885") {
                    UIApplication.shared.open(url)
                }
            }
        alert.addAction(preferredAction)
        alert.preferredAction = preferredAction
        presenter.dismiss(animated: true) {
            presenter.present(alert, animated: true)
        }
    }
    
    func showUsersLimitErrorAlert() {
        guard let presenter else { return }
        let alert = UIAlertController(
            title: Strings.Localizable.Calls.FreePlanLimitWarning.UsersLimitAlert.title,
            message: Strings.Localizable.Calls.FreePlanLimitWarning.UsersLimitAlert.message,
            preferredStyle: .alert)
        let defaultAction =  UIAlertAction(
            title: Strings.Localizable.Calls.FreePlanLimitWarning.UsersLimitAlert.button,
            style: .default
        )
        alert.addAction(defaultAction)
        alert.preferredAction = defaultAction
        presenter.dismiss(animated: true) {
            presenter.present(alert, animated: true)
        }
    }
    
    func showUpgradeToProDialog(_ account: AccountDetailsEntity) {
        guard let presenter else { return }
        let tracker = tracker // get strong instance
        let dialogConfig = SimpleDialogConfigFactory.upgradePlanDialog {
            tracker.trackAnalyticsEvent(with: MaxCallDurationReachedModalEvent())
            presenter.dismiss(animated: true) {
                UpgradeAccountPlanRouter(presenter: presenter, accountDetails: account).start()
            }
        }
        
        presenter.dismiss(animated: true) {
            BottomSheetRouter(
                presenter: presenter,
                content: SimpleDialogView(dialogConfig: dialogConfig)
            ).start()
        }
    }
    
    func showCallWillEndAlert(timeToEndCall: Double, completion: ((Double) -> Void)?) {
        guard let presenter = presenter else { return }
        CallWillEndAlertRouter(baseViewController: presenter, timeToEndCall: timeToEndCall, isCallUIVisible: isCallUIVisible, dismissCompletion: completion).start()
    }
    
    func showShareLinkOptionsAlert(_ shareLinkOptions: ShareLinkOptions) {
        guard let presenter = presenter?.presenterViewController() else { return }
        let alert = UIAlertController(
            title: Strings.Localizable.Call.ShareOptions.title,
            message: nil,
            preferredStyle: .actionSheet)
        let sendToChatAction =  UIAlertAction(
            title: Strings.Localizable.Call.ShareOptions.sendToChat,
            style: .default
        ) { _ in
            shareLinkOptions.sendLinkToChatAction()
        }
        alert.addAction(sendToChatAction)
        
        let copyAction =  UIAlertAction(
            title: Strings.Localizable.Call.ShareOptions.copy,
            style: .default
        ) { _ in
            shareLinkOptions.copyLinkAction()
        }
        alert.addAction(copyAction)
        
        let shareAction =  UIAlertAction(
            title: Strings.Localizable.Call.ShareOptions.share,
            style: .default
        ) { _ in
            shareLinkOptions.shareLinkAction(presenter)
        }
        alert.addAction(shareAction)
        
        let cancelAction = UIAlertAction(
            title: Strings.Localizable.cancel,
            style: .cancel,
            handler: nil
        )
        alert.addAction(cancelAction)
        
        if let popOverController = alert.popoverPresentationController {
            popOverController.sourceView = sourceViewForiPad()
        }
        
        presenter.present(alert, animated: true)
    }
    
    func notifyFloatingPanelInviteParticipants() {
        /// Floating panel is needed to present the 'invite participants' view.
        /// If it is not visible, it must be shown prior triggering action.
        if let floatingPanelRouter {
            floatingPanelRouter.triggerInviteParticipantsFromContainer()
        } else if let containerViewModel {
            showFloatingPanel(
                containerViewModel: containerViewModel,
                completion: { [weak self] in
                    self?.meetingParticipantsRouter?.showNavigation()
                    self?.floatingPanelRouter?.triggerInviteParticipantsFromContainer()
                }
            )
        }
    }
    
    func sendLinkToChat(_ link: String) {
        Task { @MainActor in
            guard let presenter = presenter?.presenterViewController() else {
                return
            }
            let sendToChatWrapper = SendToChatWrapper(link: link, interfaceStyle: .dark)
            self.sendToChatWrapper = sendToChatWrapper
            sendToChatWrapper.showSendToChat(presenter: presenter)
        }
    }
    
    func showLinkCopied() {
        SVProgressHUD.show(UIImage(resource: .hudSuccess), status: Strings.Localizable.Meetings.Info.ShareOptions.ShareLink.linkCopied)
    }
    
    // MARK: - Private
    
    private func sourceViewForiPad() -> UIView? {
        guard let presenter = presenter?.presenterViewController() else { return nil }
        
        if let lastSubview = presenter.view.subviews.last, lastSubview is UIToolbar {
            return lastSubview
        } else {
            return presenter.view
        }
    }
    
    private func showCallViewRouter(
        containerViewModel: MeetingContainerViewModel
    ) {
        guard let baseViewController = baseViewController else { return }
        let callViewRouter = MeetingParticipantsLayoutRouter(
            presenter: baseViewController,
            containerViewModel: containerViewModel,
            chatRoom: chatRoom,
            call: call,
            layoutUpdateChannel: layoutUpdateChannel
        )
        callViewRouter.start()
        self.meetingParticipantsRouter = callViewRouter
    }
    
    private func showFloatingPanel(
        containerViewModel: MeetingContainerViewModel,
        completion: @escaping () -> Void
    ) {
        // When toggling the chatroom instance might be outdated. So fetching it again.
        guard let baseViewController = baseViewController,
              let chatRoom = chatRoomUseCase.chatRoom(forChatId: chatRoom.chatId) else {
            return
        }
        let floatingPanelRouter = MeetingFloatingPanelRouter(
            presenter: baseViewController,
            containerViewModel: containerViewModel,
            chatRoom: chatRoom,
            permissionHandler: DevicePermissionsHandler.makeHandler(),
            layoutUpdateChannel: layoutUpdateChannel,
            selectWaitingRoomList: selectWaitingRoomList,
            actionsViewController: {
                ActionSheetViewController(
                    actions: $0.actions,
                    forceDarkMode: true,
                    headerTitle: nil,
                    dismissCompletion: $0.dismissHandler,
                    sender: nil
                )
            }
        )
        selectWaitingRoomList = false
        floatingPanelRouter.start(completion: completion)
        self.floatingPanelRouter = floatingPanelRouter
    }
    
    private func subscribeToAppDidBecomeActiveSubscription(withChatRoom chatRoom: ChatRoomEntity) {
        self.appDidBecomeActiveSubscription = NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                
                if self.createCallUseCase.call(for: chatRoom.chatId) == nil {
                    self.containerViewModel?.dispatch(.dismissCall(completion: nil))
                } else if let baseViewController = self.baseViewController,
                          !baseViewController.navigationBar.isHidden,
                          baseViewController.presentedViewController == nil,
                          let containerViewModel = self.containerViewModel {
                    self.showFloatingPanel(containerViewModel: containerViewModel, completion: {})
                }
            }
    }
    
    private func dismissCallUI(animated: Bool, completion: (() -> Void)?) {
        let shouldAnimateDismissal = UIApplication.shared.isBackgroundState ? false : animated
        floatingPanelRouter?.dismiss(animated: shouldAnimateDismissal)
        baseViewController?.dismiss(animated: shouldAnimateDismissal, completion: completion)
        
        UIApplication.shared.isIdleTimerDisabled = false
        isCallUIVisible = false
    }
    
    private func dismissWaitingRoomAlertPresentedIfNeeded(completion: @escaping () -> Void) {
        guard let presentedViewController = presenter?.presenterViewController()?.presentedViewController, presentedViewController.isKind(of: UIAlertController.self) else {
            completion()
            return
        }
        
        presentedViewController.dismiss(animated: false) {
            completion()
        }
    }
    
    func transitionToLongForm() {
        floatingPanelRouter?.transitionToLongForm()
    }
    
    func hideSnackBar() {
        baseViewController?.topViewController?.dismissSnackBar()
    }
    
    var floatingPanelShown: Bool {
        floatingPanelRouter?.panelIsLongForm ?? false
    }
}
