import PanModal
import MEGADomain

protocol MeetingFloatingPanelRouting: AnyObject, Routing {
    func dismiss(animated: Bool)
    func inviteParticipants(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        excludeParticpantsId: Set<HandleEntity>,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    )
    func showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory)
    func showNoAvailableContactsAlert(withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory)
    func showContextMenu(presenter: UIViewController,
                         sender: UIButton,
                         participant: CallParticipantEntity,
                         isMyselfModerator: Bool,
                         meetingFloatingPanelModel: MeetingFloatingPanelViewModel)
    func showVideoPermissionError()
    func showAudioPermissionError() 
    func didDisplayParticipantInMainView(_ participant: CallParticipantEntity)
    func didSwitchToGridView()
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
    private let isSpeakerEnabled: Bool
    private(set) weak var viewModel: MeetingFloatingPanelViewModel?
    private var inviteToMegaNavigationController: MEGANavigationController?
    
    init(presenter: UINavigationController, containerViewModel: MeetingContainerViewModel, chatRoom: ChatRoomEntity, isSpeakerEnabled: Bool) {
        self.presenter = presenter
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.isSpeakerEnabled = isSpeakerEnabled
    }
    
    func build() -> UIViewController {
        guard let containerViewModel = containerViewModel else { return UIViewController() }
        let audioSessionRepository = AudioSessionRepository(audioSession: AVAudioSession.sharedInstance(), callActionManager: CallActionManager.shared)
        let chatRoomRepository = ChatRoomRepository(sdk: MEGASdkManager.sharedMEGAChatSdk())
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: chatRoomRepository,
                                               userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()))
        let viewModel = MeetingFloatingPanelViewModel(router: self,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      isSpeakerEnabled: isSpeakerEnabled,
                                                      callCoordinatorUseCase: CallCoordinatorUseCase(),
                                                      callUseCase: CallUseCase(repository: CallRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk(), callActionManager: CallActionManager.shared)),
                                                      audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: audioSessionRepository),
                                                      devicePermissionUseCase: DevicePermissionCheckingProtocol.live,
                                                      captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
                                                      localVideoUseCase: CallLocalVideoUseCase(repository: CallLocalVideoRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk())),
                                                      userUseCase: UserUseCase(repo: .live),
                                                      chatRoomUseCase: chatRoomUseCase)
        
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdkManager.sharedMEGASdk()),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )

        let vc = MeetingFloatingPanelViewController(viewModel: viewModel,
                                                    userImageUseCase: userImageUseCase,
                                                    userUseCase: UserUseCase(repo: .live),
                                                    chatRoomUseCase: chatRoomUseCase)
        baseViewController = vc
        self.viewModel = viewModel
        return vc
    }
    
    func start() {
        guard let viewController = build() as? PanModalPresentable & UIViewController else { return }
        viewController.modalPresentationStyle = .custom
        viewController.modalPresentationCapturesStatusBarAppearance = true
        viewController.transitioningDelegate = PanModalPresentationDelegate.default
        presenter?.present(viewController, animated: true)
    }
    
    func dismiss(animated: Bool) {
        baseViewController?.dismiss(animated: animated)
    }
    
    func inviteParticipants(
        withParticipantsAddingViewFactory participantsAddingViewFactory: ParticipantsAddingViewFactory,
        excludeParticpantsId: Set<HandleEntity>,
        selectedUsersHandler: @escaping (([HandleEntity]) -> Void)
    ) {
        guard let contactsNavigationController = participantsAddingViewFactory.addContactsViewController(
            withContactsMode: .inviteParticipants,
            additionallyExcludedParticipantsId: excludeParticpantsId,
            selectedUsersHandler: selectedUsersHandler
        ) else { return }
        
        contactsNavigationController.overrideUserInterfaceStyle = .dark        
        baseViewController?.present(contactsNavigationController, animated: true)
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
        let participantInfoRouter = MeetingParticpiantInfoViewRouter(
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
    
    func showVideoPermissionError() {
        DevicePermissionsHelper.alertVideoPermission(completionHandler: nil)
    }
    
    func showAudioPermissionError() {
        DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
    }
    
    // MARK: - Private methods.
    
    private func showInviteToMega(_ inviteContactsViewController: InviteContactViewController) {
        let navigationController = MEGANavigationController(rootViewController: inviteContactsViewController)
        
        let backBarButton = UIBarButtonItem(
            image: Asset.Images.Chat.backArrow.image,
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
}
