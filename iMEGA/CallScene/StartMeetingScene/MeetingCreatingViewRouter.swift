import ChatRepo
import Foundation
import MEGADomain
import MEGAPermissions
import MEGAPresentation
import MEGARepo
import MEGASDKRepo

protocol MeetingCreatingViewRouting: Routing {
    func dismiss(completion: (() -> Void)?)
    func goToMeetingRoom(chatRoom: ChatRoomEntity, call: CallEntity, isSpeakerEnabled: Bool)
    func showVideoPermissionError()
    func showAudioPermissionError()
}

class MeetingCreatingViewRouter: NSObject, MeetingCreatingViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var viewControllerToPresent: UIViewController?
    private let type: MeetingConfigurationType
    private let link: String?
    private let userHandle: UInt64
    private let tracker: some AnalyticsTracking = DIContainer.tracker
    
    @objc init(
        viewControllerToPresent: UIViewController,
        type: MeetingConfigurationType,
        link: String?,
        userhandle: UInt64
    ) {
        self.viewControllerToPresent = viewControllerToPresent
        self.type = type
        self.link = link
        self.userHandle = userhandle
    }
    
    @objc func build() -> UIViewController {
        let audioSessionRepository = AudioSessionRepository(audioSession: AVAudioSession.sharedInstance())
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: .shared),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        let vm = MeetingCreatingViewModel(
            router: self,
            type: type,
            meetingUseCase: MeetingCreatingUseCase(
                meetingCreatingRepo: MeetingCreatingRepository.newRepo,
                userStoreRepo: UserStoreRepository.newRepo
            ),
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository: audioSessionRepository),
            localVideoUseCase: CallLocalVideoUseCase(repository: CallLocalVideoRepository(chatSdk: .shared)),
            captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
            permissionHandler: DevicePermissionsHandler.makeHandler(),
            userImageUseCase: userImageUseCase,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo),
            callUseCase: CallUseCase(repository: CallRepository.newRepo),
            callManager: CallKitCallManager.shared,
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            featureFlagProvider: DIContainer.featureFlagProvider,
            link: link,
            userHandle: userHandle)
        let vc = MeetingCreatingViewController(viewModel: vm)
        baseViewController = vc
        return vc
    }
    
    @objc func start() {
        guard let viewControllerToPresent = viewControllerToPresent else {
            return
        }
        let nav = UINavigationController(rootViewController: build())
        nav.overrideUserInterfaceStyle = .dark
        nav.modalPresentationStyle = .fullScreen
        viewControllerToPresent.present(nav, animated: true, completion: nil)
    }
    
    // MARK: - UI Actions
    func dismiss(completion: (() -> Void)?) {
        baseViewController?.dismiss(animated: true, completion: completion)
    }
    
    func goToMeetingRoom(chatRoom: ChatRoomEntity, call: CallEntity, isSpeakerEnabled: Bool) {
        guard let viewControllerToPresent = viewControllerToPresent else {
            return
        }
        MeetingContainerRouter(
            presenter: viewControllerToPresent,
            chatRoom: chatRoom,
            call: call,
            isSpeakerEnabled: isSpeakerEnabled,
            tracker: tracker
        ).start()
    }
    
    var permissionRouter: PermissionAlertRouter {
        .makeRouter(deviceHandler: DevicePermissionsHandler.makeHandler())
    }
    
    func showVideoPermissionError() {
        permissionRouter.alertVideoPermission()
    }
    
    func showAudioPermissionError() {
        permissionRouter.alertAudioPermission(incomingCall: false)
    }
}
