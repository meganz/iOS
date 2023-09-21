import ChatRepo
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGARepo
import MEGASDKRepo

final class WaitingRoomViewRouter: NSObject, WaitingRoomViewRouting {
    private let presenter: UIViewController?
    private let scheduledMeeting: ScheduledMeetingEntity
    private weak var baseViewController: UIViewController?
    private let chatLink: String?
    private let requestUserHandle: HandleEntity

    private var permissionRouter: PermissionAlertRouter {
        .makeRouter(deviceHandler: DevicePermissionsHandler.makeHandler())
    }

    init(presenter: UIViewController?,
         scheduledMeeting: ScheduledMeetingEntity,
         chatLink: String? = nil,
         requestUserHandle: HandleEntity = 0) {
        self.presenter = presenter
        self.scheduledMeeting = scheduledMeeting
        self.chatLink = chatLink
        self.requestUserHandle = requestUserHandle
    }
    
    // MARK: - Public
    
    func build() -> UIViewController {
        let audioSessionRepository = AudioSessionRepository(audioSession: .sharedInstance(), callActionManager: .shared)
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: .shared),
            userStoreRepo: UserStoreRepository(store: .shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        let viewModel = WaitingRoomViewModel(
            scheduledMeeting: scheduledMeeting,
            router: self,
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            callUseCase: CallUseCase(repository: CallRepository.newRepo),
            callCoordinatorUseCase: CallCoordinatorUseCase(),
            meetingUseCase: MeetingCreatingUseCase(repository: MeetingCreatingRepository.newRepo),
            authUseCase: AuthUseCase(repo: AuthRepository.newRepo, credentialRepo: CredentialRepository.newRepo),
            waitingRoomUseCase: WaitingRoomUseCase(waitingRoomRepo: WaitingRoomRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo),
            userImageUseCase: userImageUseCase,
            localVideoUseCase: CallLocalVideoUseCase(repository: CallLocalVideoRepository.newRepo),
            captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: audioSessionRepository),
            permissionHandler: DevicePermissionsHandler.makeHandler(),
            chatLink: chatLink,
            requestUserHandle: requestUserHandle
        )
        let viewController = WaitingRoomViewController(viewModel: viewModel)
        baseViewController = viewController
        return viewController
    }
    
    func start() {
        guard let presenter else { return }
        let nav = UINavigationController(rootViewController: build())
        nav.overrideUserInterfaceStyle = .dark
        nav.modalPresentationStyle = .fullScreen
        presenter.present(nav, animated: true)
    }
    
    func dismiss(completion: (() -> Void)?) {
        baseViewController?.dismiss(animated: true, completion: completion)
    }
    
    func showLeaveAlert(leaveAction: @escaping () -> Void) {
        guard let baseViewController else { return }
        let alertController = UIAlertController(title: Strings.Localizable.Meetings.WaitingRoom.Alert.leaveMeeting, message: nil, preferredStyle: .alert)
        alertController.overrideUserInterfaceStyle = .dark
        let leaveAction = UIAlertAction(title: Strings.Localizable.Meetings.WaitingRoom.leave, style: .default) { _ in
            leaveAction()
        }
        let cancelAction = UIAlertAction(title: Strings.Localizable.Meetings.WaitingRoom.Alert.dontLeave, style: .cancel)
        alertController.addAction(cancelAction)
        alertController.addAction(leaveAction)
        alertController.preferredAction = leaveAction
        baseViewController.present(alertController, animated: true)
    }
    
    func showMeetingInfo() {
        if let url = URL(string: "https://mega.io/chatandmeetings") {
            UIApplication.shared.open(url)
        }
    }
    
    func showVideoPermissionError() {
        permissionRouter.alertVideoPermission()
    }
    
    func showAudioPermissionError() {
        permissionRouter.alertAudioPermission(incomingCall: false)
    }
    
    func showHostDenyAlert(leaveAction: @escaping () -> Void ) {
        guard let baseViewController else { return }
        let alertController = UIAlertController(title: Strings.Localizable.Meetings.WaitingRoom.Alert.hostDidNotLetYouIn, message: Strings.Localizable.Meetings.WaitingRoom.Alert.youWillBeRemovedFromTheWaitingRoom, preferredStyle: .alert)
        alertController.overrideUserInterfaceStyle = .dark
        let leaveAction = UIAlertAction(title: Strings.Localizable.Meetings.WaitingRoom.Alert.okGotIt, style: .default) { _ in
            leaveAction()
        }
        alertController.addAction(leaveAction)
        alertController.preferredAction = leaveAction
        dismissAlertControllerThenPresent(alertController, from: baseViewController)
    }
    
    func showHostDidNotRespondAlert(leaveAction: @escaping () -> Void) {
        guard let baseViewController else { return }
        let alertController = UIAlertController(title: Strings.Localizable.Meetings.WaitingRoom.Alert.hostDidNotRespond, message: Strings.Localizable.Meetings.WaitingRoom.Alert.thereIsNoResponseToYourResquestToJoinTheMeeting, preferredStyle: .alert)
        alertController.overrideUserInterfaceStyle = .dark
        let leaveAction = UIAlertAction(title: Strings.Localizable.Meetings.WaitingRoom.Alert.okGotIt, style: .default) { _ in
            leaveAction()
        }
        alertController.addAction(leaveAction)
        alertController.preferredAction = leaveAction
        dismissAlertControllerThenPresent(alertController, from: baseViewController)
    }
    
    func openCallUI(for call: CallEntity,
                    in chatRoom: ChatRoomEntity,
                    isSpeakerEnabled: Bool) {
        guard let presenter else { return }
        baseViewController?.dismiss(animated: true)
        MeetingContainerRouter(presenter: presenter,
                               chatRoom: chatRoom,
                               call: call,
                               isSpeakerEnabled: isSpeakerEnabled)
        .start()
    }
    
    private func dismissAlertControllerThenPresent(_ alertController: UIAlertController, from baseViewController: UIViewController) {
        if let presentedViewController = presenter?.presenterViewController()?.presentedViewController,
           presentedViewController.isKind(of: UIAlertController.self) {
            presentedViewController.dismiss(animated: true) {
                baseViewController.present(alertController, animated: true)
            }
        } else {
            baseViewController.present(alertController, animated: true)
        }
    }
}
