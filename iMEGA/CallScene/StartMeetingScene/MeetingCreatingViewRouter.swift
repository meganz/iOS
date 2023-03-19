import Foundation
import MEGADomain
import MEGAPresentation

protocol MeetingCreatingViewRouting: Routing {
    func dismiss()
    func goToMeetingRoom(chatRoom: ChatRoomEntity, call: CallEntity, isVideoEnabled: Bool, isSpeakerEnabled: Bool)
    func openChatRoom(withChatId chatId: UInt64)
    func showVideoPermissionError()
    func showAudioPermissionError()
}

class MeetingCreatingViewRouter: NSObject, MeetingCreatingViewRouting {
    private weak var baseViewController: UIViewController?
    private weak var viewControllerToPresent: UIViewController?
    private let type: MeetingConfigurationType
    private let link: String?
    private let userHandle: UInt64
    
    @objc init(viewControllerToPresent: UIViewController, type: MeetingConfigurationType, link: String?, userhandle: UInt64) {
        self.viewControllerToPresent = viewControllerToPresent
        self.type = type
        self.link = link
        self.userHandle = userhandle
    }
    
    @objc func build() -> UIViewController {
        let audioSessionRepository = AudioSessionRepository(audioSession: AVAudioSession.sharedInstance(), callActionManager: CallActionManager.shared)
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdkManager.sharedMEGASdk()),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )

        let vm = MeetingCreatingViewModel(
            router: self,
            type: type,
            meetingUseCase: MeetingCreatingUseCase(repository: MeetingCreatingRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk(), sdk: MEGASdkManager.sharedMEGASdk(), callActionManager: CallActionManager.shared)),
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository:audioSessionRepository),
            localVideoUseCase: CallLocalVideoUseCase(repository: CallLocalVideoRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk())),
            captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
            devicePermissionUseCase: DevicePermissionCheckingProtocol.live,
            userImageUseCase: userImageUseCase,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo),
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
    func dismiss() {
        baseViewController?.dismiss(animated: true, completion: nil)
    }
    
    func openChatRoom(withChatId chatId: UInt64) {
        guard let chatViewController = ChatViewController(chatId: chatId) else { return }
        viewControllerToPresent?.present(
            MEGANavigationController(rootViewController: chatViewController),
            animated: true
        )
    }

    func goToMeetingRoom(chatRoom: ChatRoomEntity, call: CallEntity, isVideoEnabled: Bool, isSpeakerEnabled: Bool) {
     guard let viewControllerToPresent = viewControllerToPresent else {
            return
        }
        MeetingContainerRouter(presenter: viewControllerToPresent,
                               chatRoom: chatRoom,
                               call: call,
                               isSpeakerEnabled: isSpeakerEnabled).start()
    }
    
    func showVideoPermissionError() {
        DevicePermissionsHelper.alertVideoPermission(completionHandler: nil)
    }
    
    func showAudioPermissionError() {
        DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
    }
}
