import PanModal

protocol MeetingFloatingPanelRouting: AnyObject, Routing {
    var viewModel: MeetingFloatingPanelViewModel? { get }
    func dismiss()
    func shareLink(presenter: UIViewController, sender: UIButton, link: String)
    func inviteParticipants(
        presenter: UIViewController,
        excludeParticpants: [UInt64]?,
        selectedUsersHandler: @escaping (([UInt64]) -> Void)
    )
    func showContextMenu(presenter: UIViewController,
                         sender: UIButton,
                         attendee: CallParticipantEntity,
                         isMyselfModerator: Bool,
                         meetingFloatingPanelModel: MeetingFloatingPanelViewModel)
    func showVideoPermissionError()
    func showAudioPermissionError()
}

final class MeetingFloatingPanelRouter: MeetingFloatingPanelRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UINavigationController?
    private weak var containerViewModel: MeetingContainerViewModel?
    private let chatRoom: ChatRoomEntity
    private let call: CallEntity
    private let isVideoEnabled: Bool
    private(set) weak var viewModel: MeetingFloatingPanelViewModel?
    
    init(presenter: UINavigationController, containerViewModel: MeetingContainerViewModel, chatRoom: ChatRoomEntity, call: CallEntity, isVideoEnabled: Bool) {
        self.presenter = presenter
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.call = call
        self.isVideoEnabled = isVideoEnabled
    }
    
    func build() -> UIViewController {
        guard let containerViewModel = containerViewModel else { return UIViewController() }
        let audioSessionRepository = AudioSessionRepository(audioSession: AVAudioSession.sharedInstance())
        let chatRoomRepository = ChatRoomRepository(sdk: MEGASdkManager.sharedMEGAChatSdk())
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: chatRoomRepository,
                                               userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()))
        let viewModel = MeetingFloatingPanelViewModel(router: self,
                                                      containerViewModel: containerViewModel,
                                                      chatRoom: chatRoom,
                                                      call: call,
                                                      callManagerUseCase: CallManagerUseCase(),
                                                      callsUseCase: CallsUseCase(repository: CallsRepository()),
                                                      audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: audioSessionRepository),
                                                      devicePermissionUseCase: DevicePermissionCheckingProtocol.live,
                                                      captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
                                                      localVideoUseCase: CallsLocalVideoUseCase(repository: CallsLocalVideoRepository()),
                                                      isVideoEnabled: isVideoEnabled)
        
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
    
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func shareLink(presenter: UIViewController, sender: UIButton, link: String) {
        let activityViewController = UIActivityViewController(activityItems: [link], applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = sender
        activityViewController.popoverPresentationController?.sourceRect = sender.frame
        if #available(iOS 13.0, *) {
            activityViewController.overrideUserInterfaceStyle = .dark
        }
        presenter.present(activityViewController, animated: true)
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
                         attendee: CallParticipantEntity,
                         isMyselfModerator: Bool,
                         meetingFloatingPanelModel: MeetingFloatingPanelViewModel) {
        let participantInfoRouter = MeetingParticpiantInfoViewRouter(
            presenter: presenter,
            sender: sender,
            attendee: attendee,
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
