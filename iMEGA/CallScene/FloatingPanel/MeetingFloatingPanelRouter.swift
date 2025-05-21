import Chat
import ChatRepo
import MEGAAppPresentation
import MEGAAppSDKRepo
import MEGAAssets
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGARepo
import PanModal
import SwiftUI

@MainActor
protocol MeetingFloatingPanelRouting: AnyObject {
    func dismiss(animated: Bool)
    func inviteParticipants(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        contactPickerConfig: ContactPickerConfig,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    )
    func showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory)
    func showNoAvailableContactsAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory)
    func showContextMenu(
        presenter: UIViewController, 
        sender: UIButton,
        participant: CallParticipantEntity,
        isMyselfModerator: Bool,
        meetingFloatingPanelModel: MeetingFloatingPanelViewModel
    )
    func showVideoPermissionError()
    func showAudioPermissionError()
    func didDisplayParticipantInMainView(_ participant: CallParticipantEntity)
    func didSwitchToGridView()
    func showConfirmDenyAction(
        for username: String,
        isCallUIVisible: Bool,
        confirmDenyAction: @escaping () -> Void,
        cancelDenyAction: @escaping () -> Void
    )
    func showWaitingRoomParticipantsList(for call: CallEntity)
    func showMuteSuccess(for participant: CallParticipantEntity?)
    func showMuteError(for participant: CallParticipantEntity?)
    func showUpgradeFlow(_ accountDetails: AccountDetailsEntity)
    func showHangOrEndCallDialog(containerViewModel: MeetingContainerViewModel)
    func transitionToLongForm()
    var panelIsLongForm: Bool { get }
    func triggerInviteParticipantsFromContainer()
}

extension MeetingFloatingPanelRouting {
    func dismiss(animated: Bool = true) {
        dismiss(animated: animated)
    }
}

final class MeetingFloatingPanelRouter: MeetingFloatingPanelRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UINavigationController?
    private weak var containerViewModel: MeetingContainerViewModel?
    private let chatRoom: ChatRoomEntity
    private var selectWaitingRoomList: Bool
    private(set) weak var viewModel: MeetingFloatingPanelViewModel?
    private var inviteToMegaNavigationController: MEGANavigationController?
    private let permissionHandler: any DevicePermissionsHandling
    private lazy var callWaitingRoomDialog = CallWaitingRoomUsersDialog()
    private let actionsViewController: (ActionSheetModel) -> UIViewController
    private let layoutUpdateChannel: ParticipantLayoutUpdateChannel
    init(
        presenter: UINavigationController,
        containerViewModel: MeetingContainerViewModel,
        chatRoom: ChatRoomEntity,
        permissionHandler: some DevicePermissionsHandling,
        layoutUpdateChannel: ParticipantLayoutUpdateChannel,
        selectWaitingRoomList: Bool,
        actionsViewController: @escaping (ActionSheetModel) -> UIViewController
    ) {
        self.presenter = presenter
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.permissionHandler = permissionHandler
        self.selectWaitingRoomList = selectWaitingRoomList
        self.layoutUpdateChannel = layoutUpdateChannel
        self.actionsViewController = actionsViewController
    }
    
    func build() -> UIViewController {
        guard let containerViewModel = containerViewModel else { return UIViewController() }
        let audioSessionRepository = AudioSessionRepository(audioSession: AVAudioSession.sharedInstance())
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
        let chatRoomUserUseCase = ChatRoomUserUseCase(chatRoomRepo: ChatRoomUserRepository.newRepo,
                                                      userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()))
        let megaHandleUseCase = MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
        
        let callControlsViewModel = CallControlsViewModel(
            router: self,
            menuPresenter: presentMenu,
            chatRoom: chatRoom,
            callUseCase: CallUseCase(repository: CallRepository.newRepo),
            callUpdateUseCase: CallUpdateUseCase(repository: CallUpdateRepository.newRepo),
            localVideoUseCase: CallLocalVideoUseCase(repository: CallLocalVideoRepository(chatSdk: .shared)),
            containerViewModel: containerViewModel, 
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: audioSessionRepository),
            permissionHandler: DevicePermissionsHandler.makeHandler(),
            callController: CallControllerProvider().provideCallController(),
            notificationCenter: NotificationCenter.default,
            audioRouteChangeNotificationName: AVAudioSession.routeChangeNotification,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            layoutUpdateChannel: layoutUpdateChannel,
            cameraSwitcher: CameraSwitcher(
                captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
                localVideoUseCase: CallLocalVideoUseCase(repository: CallLocalVideoRepository(chatSdk: .shared))
            ),
            raiseHandBadgeStoring: RaiseHandBadgeStore(userAttributeUseCase: UserAttributeUseCase(repo: UserAttributeRepository.newRepo)),
            tracker: DIContainer.tracker
        )
        
        let callControlsViewHost = UIHostingController(rootView: CallControlsView(viewModel: callControlsViewModel))
        callControlsViewHost.view.backgroundColor = .clear
        
        let viewModel = MeetingFloatingPanelViewModel(
            router: self,
            containerViewModel: containerViewModel,
            chatRoom: chatRoom,
            callUseCase: CallUseCase(repository: CallRepository.newRepo),
            callUpdateUseCase: CallUpdateUseCase(repository: CallUpdateRepository.newRepo),
            sessionUpdateUseCase: SessionUpdateUseCase(repository: SessionUpdateRepository.newRepo),
            chatRoomUpdateUseCase: ChatRoomUpdateUseCase(repository: ChatRoomUpdateRepository(chatRoomUpdateProvider: ChatRoomUpdateProvider(sdk: .sharedChatSdk, chatId: chatRoom.chatId))),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            chatRoomUseCase: chatRoomUseCase,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            selectWaitingRoomList: selectWaitingRoomList,
            headerConfigFactory: MeetingFloatingPanelHeaderConfigFactory(infoBannerFactory: MeetingFloatingPanelBannerFactory()),
            featureFlags: DIContainer.featureFlagProvider,
            notificationCenter: NotificationCenter.default,
            presentUpgradeFlow: showUpgradeFlow,
            tracker: DIContainer.tracker
        )
        
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository.newRepo,
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.sharedRepo
        )
        
        let vc = MeetingFloatingPanelViewController(
            viewModel: viewModel,
            userImageUseCase: userImageUseCase,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            megaHandleUseCase: megaHandleUseCase,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            callControlsViewHost: callControlsViewHost
        )
        baseViewController = vc
        self.viewModel = viewModel
        
        return vc
    }
    
    func start(completion: @escaping () -> Void) {
        guard let viewController = build() as? any PanModalPresentable & UIViewController else { return }
        viewController.modalPresentationStyle = .custom
        viewController.modalPresentationCapturesStatusBarAppearance = true
        viewController.transitioningDelegate = PanModalPresentationDelegate.default
        presenter?.present(viewController, animated: true, completion: completion)
    }
    
    func dismiss(animated: Bool) {
        baseViewController?.dismiss(animated: animated)
    }
    
    func inviteParticipants(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        contactPickerConfig: ContactPickerConfig,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    ) {
        guard let contactsNavigationController = participantsAddingViewFactory.addContactsViewController(
            contactPickerConfig: contactPickerConfig,
            selectedUsersHandler: selectedUsersHandler
        ) else { return }
        
        contactsNavigationController.overrideUserInterfaceStyle = .dark
        baseViewController?.present(contactsNavigationController, animated: true)
    }
    
    func presentMenu(_ actions: [ActionSheetAction]) {
        // when bottom menu is shown, we hide drawer, then when it's dismissed (via action or otherwise)
        // we show it again
        let toggleMenuVisibility: () -> Void = { [weak self] in
            self?.containerViewModel?.dispatch(.changeMenuVisibility)
        }
        
        toggleMenuVisibility()
        let actionSheetModel = ActionSheetModel(
            actions: actions.map { action in
                action.attachingAction(toggleMenuVisibility)
            },
            dismissHandler: toggleMenuVisibility
        )
        presenter?.present(actionsViewController(actionSheetModel), animated: true)
    }
    
    func showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory) {
        showContactsAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory,
                          action: participantsAddingViewFactory.allContactsAlreadyAddedAlert)
        
    }
    
    func showNoAvailableContactsAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory) {
        showContactsAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory,
                          action: participantsAddingViewFactory.noAvailableContactsAlert)
    }
    
    private func showContactsAlert(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        action: (@escaping () -> Void) -> UIAlertController
    ) {
        let contactsAlert = action {
            guard let inviteContactController = participantsAddingViewFactory.inviteContactController() else { return }
            self.showInviteToMega(inviteContactController)
        }
        
        contactsAlert.overrideUserInterfaceStyle = .dark
        baseViewController?.present(contactsAlert, animated: true)
    }
    
    func showContextMenu(presenter: UIViewController,
                         sender: UIButton,
                         participant: CallParticipantEntity,
                         isMyselfModerator: Bool,
                         meetingFloatingPanelModel: MeetingFloatingPanelViewModel) {
        let participantInfoRouter = MeetingParticipantInfoViewRouter(
            presenter: presenter,
            sender: sender,
            participant: participant,
            isMyselfModerator: isMyselfModerator,
            meetingFloatingPanelModel: meetingFloatingPanelModel)
        
        participantInfoRouter.start()
    }
    
    func didDisplayParticipantInMainView(_ participant: CallParticipantEntity) {
        viewModel?.dispatch(.didDisplayParticipantInMainView(participant))
    }
    
    func didSwitchToGridView() {
        viewModel?.dispatch(.didSwitchToGridView)
    }
    
    var permissionRouter: PermissionAlertRouter {
        .makeRouter(deviceHandler: permissionHandler)
    }
    
    func showVideoPermissionError() {
        permissionRouter.alertVideoPermission()
    }
    
    func showAudioPermissionError() {
        permissionRouter.alertAudioPermission(incomingCall: false)
    }
    
    func triggerInviteParticipantsFromContainer() {
        viewModel?.dispatch(.presentInviteParticipantsScreen)
    }
    
    func showWaitingRoomParticipantsList(
        for call: CallEntity
    ) {
        guard let baseViewController else { return }
        WaitingRoomParticipantsListRouter(
            presenter: baseViewController,
            call: call
        ).start()
    }
    
    // MARK: - Private methods.
    
    private func showInviteToMega(_ inviteContactsViewController: InviteContactViewController) {
        let navigationController = MEGANavigationController(rootViewController: inviteContactsViewController)
        
        let backBarButton = UIBarButtonItem(
            image: MEGAAssets.UIImage.backArrow,
            style: .plain,
            target: self,
            action: #selector(self.dismissInviteContactsScreen)
        )
        
        navigationController.addLeftDismissBarButton(backBarButton)
        navigationController.overrideUserInterfaceStyle = .dark
        self.inviteToMegaNavigationController = navigationController
        baseViewController?.present(navigationController, animated: true)
    }
    
    @objc private func dismissInviteContactsScreen() {
        self.inviteToMegaNavigationController?.dismiss(animated: true)
        self.inviteToMegaNavigationController = nil
    }
    
    func showConfirmDenyAction(for username: String, isCallUIVisible: Bool, confirmDenyAction: @escaping () -> Void, cancelDenyAction: @escaping () -> Void) {
        guard let presenter = baseViewController?.presenterViewController() else { return }

        callWaitingRoomDialog.showAlertForConfirmDeny(isCallUIVisible: isCallUIVisible, named: username, presenterViewController: presenter, confirmAction: confirmDenyAction, cancelAction: cancelDenyAction)
    }
    
    func showMuteSuccess(for participant: CallParticipantEntity?) {
        if let participant {
            SVProgressHUD.showSuccess(withStatus: Strings.Localizable.Calls.ParticipantsInCall.MuteParticipant.success(participant.name ?? ""))
        } else {
            SVProgressHUD.showSuccess(withStatus: Strings.Localizable.Calls.ParticipantsInCall.MuteAll.success)
        }
    }
    
    func showMuteError(for participant: CallParticipantEntity?) {
        if let participant {
            SVProgressHUD.showError(withStatus: Strings.Localizable.Calls.ParticipantsInCall.MuteParticipant.error(participant.name ?? ""))
        } else {
            SVProgressHUD.showError(withStatus: Strings.Localizable.Calls.ParticipantsInCall.MuteAll.error)
        }
    }
    
    func showUpgradeFlow(_ accountDetails: AccountDetailsEntity) {
        guard let baseViewController else { return }
        UpgradeAccountPlanRouter(
            presenter: baseViewController,
            accountDetails: accountDetails
        ).start()
    }
    
    func showHangOrEndCallDialog(containerViewModel: MeetingContainerViewModel) {
        let hangOrEndCallRouter = HangOrEndCallRouter(
            presenter: UIApplication.mnz_presentingViewController(),
            completion: {[weak containerViewModel] action in
                switch action {
                case .endCallForAll:
                    containerViewModel?.dispatch(.endCallForAll)
                case .leaveCall:
                    containerViewModel?.dispatch(.hangCall(presenter: nil, sender: nil))
                }
            }
        )
        hangOrEndCallRouter.start()
    }
    
    func transitionToLongForm() {
        viewModel?.dispatch(.transitionToLongForm)
    }
    
    var panelIsLongForm: Bool {
        viewModel?.panelIsLongForm ?? false
    }
}
