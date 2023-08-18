import ChatRepo
import MEGADomain
import MEGAPermissions
import MEGARepo
import MEGASDKRepo

final class WaitingRoomViewRouter: NSObject, WaitingRoomViewRouting {
    private(set) var presenter: UIViewController?
    private let scheduledMeeting: ScheduledMeetingEntity
    private weak var baseViewController: UIViewController?

    init(presenter: UIViewController?, scheduledMeeting: ScheduledMeetingEntity) {
        self.presenter = presenter
        self.scheduledMeeting = scheduledMeeting
    }
    
    func build() -> UIViewController {
        let audioSessionRepository = AudioSessionRepository(audioSession: AVAudioSession.sharedInstance(), callActionManager: CallActionManager.shared)
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdk.shared),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        let viewModel = WaitingRoomViewModel(
            scheduledMeeting: scheduledMeeting,
            router: self,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            userImageUseCase: userImageUseCase,
            localVideoUseCase: CallLocalVideoUseCase(repository: CallLocalVideoRepository(chatSdk: MEGAChatSdk.shared)),
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: audioSessionRepository),
            permissionHandler: DevicePermissionsHandler.makeHandler()
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
    
    func dismiss() {
        baseViewController?.dismiss(animated: true)
    }
    
    func showLeaveAlert(leaveAction: @escaping () -> Void) {
        guard let baseViewController = baseViewController else { return }
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
}
