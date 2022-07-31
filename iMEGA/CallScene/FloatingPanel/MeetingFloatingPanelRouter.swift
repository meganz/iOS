import PanModal

protocol MeetingFloatingPanelRouting: AnyObject, Routing {
    func dismiss(animated: Bool)
    func inviteParticipants(
        excludeParticpantsId: [MEGAHandle],
        selectedUsersHandler: @escaping (([UInt64]) -> Void)
    )
    func showAllContactsAlreadyAddedAlert()
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
            thumbnailRepo: ThumbnailRepository.newRepo
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
    
    func inviteParticipants(excludeParticpantsId: [MEGAHandle], selectedUsersHandler: @escaping (([UInt64]) -> Void)) {
        let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
        guard let contactsNavigationController = storyboard.instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? UINavigationController else { fatalError("no contacts navigation view controller found") }
        contactsNavigationController.overrideUserInterfaceStyle = .dark
        guard let contactController = contactsNavigationController.viewControllers.first as? ContactsViewController else { fatalError("no contact view controller found") }
        contactController.contactsMode = .inviteParticipants
        
        let participantsDict = excludeParticpantsId.reduce(into: [NSNumber: NSNumber]()) {
            $0[NSNumber(value: $1)] = NSNumber(value: $1)
        }
        contactController.participantsMutableDictionary = participantsDict as? NSMutableDictionary
        contactController.userSelected = { selectedUsers in
            guard let users = selectedUsers else { return }
            selectedUsersHandler(users.map({ $0.handle }))
        }
        
        baseViewController?.present(contactsNavigationController, animated: true)
    }
    
    func showAllContactsAlreadyAddedAlert() {
        let title = Strings.Localizable.Meetings.Panel.inviteParticipants
        let message = Strings.Localizable.Meetings.AddContacts.allContactsAlreadyAddedMessage
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.Localizable.cancel, style: .cancel, handler:nil))
        let inviteAction = UIAlertAction(title: Strings.Localizable.invite, style: .default) { [weak self] _ in
            self?.showInviteToMega()
        }
        alertController.addAction(inviteAction)
        alertController.preferredAction = inviteAction
        alertController.overrideUserInterfaceStyle = .dark
        baseViewController?.present(alertController, animated: true)
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
    
    private func showInviteToMega() {
        let storyboard = UIStoryboard(name: "InviteContact", bundle: nil)
        guard let inviteContactsViewController = storyboard.instantiateViewController(identifier: "InviteContactViewControllerID") as? InviteContactViewController else {
            return
        }
        
        let navigationController = MEGANavigationController(rootViewController: inviteContactsViewController)
        
        let backBarButton = UIBarButtonItem(
            image: Asset.Images.Chat.backArrow.image,
            style: .plain,
            target: self,
            action: #selector(self.dismissInviteContactsScreen)
        )
        
        navigationController.addLeftDismissBarButton(backBarButton)
        self.inviteToMegaNavigationController = navigationController
        baseViewController?.present(navigationController, animated: true)
    }
    
    @objc private func dismissInviteContactsScreen() {
        self.inviteToMegaNavigationController?.dismiss(animated: true)
        self.inviteToMegaNavigationController = nil
    }
}
