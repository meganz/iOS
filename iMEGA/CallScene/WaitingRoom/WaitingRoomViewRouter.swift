import ChatRepo
import MEGADomain
import MEGAL10n
import MEGAPermissions
import MEGARepo
import MEGASDKRepo

final class WaitingRoomViewRouter: NSObject, WaitingRoomViewRouting {
    private(set) var presenter: UIViewController?
    private let scheduledMeeting: ScheduledMeetingEntity
    private weak var baseViewController: UIViewController?
    private let chatLink: String?

    private var permissionRouter: PermissionAlertRouter {
        .makeRouter(deviceHandler: DevicePermissionsHandler.makeHandler())
    }

    init(presenter: UIViewController?,
         scheduledMeeting: ScheduledMeetingEntity,
         chatLink: String? = nil) {
        self.presenter = presenter
        self.scheduledMeeting = scheduledMeeting
        self.chatLink = chatLink
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
            callUseCase: CallUseCase(repository: CallRepository.newRepo),
            callCoordinatorUseCase: CallCoordinatorUseCase(),
            meetingUseCase: MeetingCreatingUseCase(repository: MeetingCreatingRepository(chatSdk: .shared, sdk: .shared, callActionManager: .shared)),
            authUseCase: AuthUseCase(repo: AuthRepository.newRepo, credentialRepo: CredentialRepository.newRepo),
            waitingRoomUseCase: WaitingRoomUseCase(waitingRoomRepo: WaitingRoomRepository.newRepo),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo),
            userImageUseCase: userImageUseCase,
            localVideoUseCase: CallLocalVideoUseCase(repository: CallLocalVideoRepository(chatSdk: .shared)),
            captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: audioSessionRepository),
            permissionHandler: DevicePermissionsHandler.makeHandler(),
            chatLink: chatLink
        )
        let viewController = WaitingRoomViewController(viewModel: viewModel)
        baseViewController = viewController
        return viewController
    }
    
    func start() {
        guard let presenter = presenter else { return }
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
        let leaveAction = UIAlertAction(title: Strings.Localizable.Meetings.WaitingRoom.Alert.okGotIt, style: .default) { _ in
            leaveAction()
        }
        alertController.addAction(leaveAction)
        alertController.preferredAction = leaveAction
        baseViewController.present(alertController, animated: true)
    }
    
    func hostAllowToJoin() {
        
    }
}
