import PanModal

protocol MeetingFloatingPanelRouting: AnyObject, Routing {
    func dismiss(animated: Bool)
    func inviteParticipants(
        presenter: UIViewController,
        excludeParticpants: [UInt64]?,
        selectedUsersHandler: @escaping (([UInt64]) -> Void)
    )
    func showContextMenu(presenter: UIViewController,
                         sender: UIButton,
                         participant: CallParticipantEntity,
                         isMyselfModerator: Bool,
                         meetingFloatingPanelModel: MeetingFloatingPanelViewModel)
    func showVideoPermissionError()
    func showAudioPermissionError()
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
    private let enableVideo: Bool
    private(set) weak var viewModel: MeetingFloatingPanelViewModel?
    
    init(presenter: UINavigationController, containerViewModel: MeetingContainerViewModel, chatRoom: ChatRoomEntity, isSpeakerEnabled: Bool, enableVideo: Bool) {
        self.presenter = presenter
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.isSpeakerEnabled = isSpeakerEnabled
        self.enableVideo = enableVideo
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
                                                      enableVideo: enableVideo,
                                                      callManagerUseCase: CallManagerUseCase(),
                                                      callUseCase: CallUseCase(repository: CallRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk(), callActionManager: CallActionManager.shared)),
                                                      audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: audioSessionRepository),
                                                      devicePermissionUseCase: DevicePermissionCheckingProtocol.live,
                                                      captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
                                                      localVideoUseCase: CallLocalVideoUseCase(repository: CallLocalVideoRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk())),
                                                      userUseCase: UserUseCase(repo: .live))
        
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdkManager.sharedMEGASdk()),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            appGroupFilePathUseCase: MEGAAppGroupFilePathUseCase(fileManager: FileManager.default)
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
        presenter: UIViewController,
        excludeParticpants: [UInt64]?,
        selectedUsersHandler: @escaping (([UInt64]) -> Void)
    ) {
        let storyboard = UIStoryboard(name: "Contacts", bundle: nil)
        guard let contactsNavigationController = storyboard.instantiateViewController(withIdentifier: "ContactsNavigationControllerID") as? UINavigationController else { fatalError("no contacts navigation view controller found") }
        if #available(iOS 13.0, *) {
            contactsNavigationController.overrideUserInterfaceStyle = .dark
        }
        guard let contactController = contactsNavigationController.viewControllers.first as? ContactsViewController else { fatalError("no contact view controller found") }
        contactController.contactsMode = .inviteParticipants

        let excludeParticpantsDict = excludeParticpants?.reduce(into: [:]) { result, element in
            result[NSNumber(value: element)] = NSNumber(value: element)
        }
        
        if let dict = excludeParticpantsDict {
            contactController.participantsMutableDictionary = NSMutableDictionary(dictionary: dict)
        }
        
        contactController.userSelected = { selectedUsers in
            guard let users = selectedUsers else { return }
            selectedUsersHandler(users.map({ $0.handle }))
        }
        
        presenter.present(contactsNavigationController, animated: true)
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
    
    func showVideoPermissionError() {
        DevicePermissionsHelper.alertVideoPermission(completionHandler: nil)
    }
    
    func showAudioPermissionError() {
        DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
    }
}
