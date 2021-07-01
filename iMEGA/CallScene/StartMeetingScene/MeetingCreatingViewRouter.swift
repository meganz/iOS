import Foundation

protocol MeetingCreatingViewRouting: Routing {
    func dismiss()
    func goToMeetingRoom(chatRoom: ChatRoomEntity, call: CallEntity, isVideoEnabled: Bool)
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
        let audioSessionRepository = AudioSessionRepository(audioSession: AVAudioSession.sharedInstance())

        let vm = MeetingCreatingViewModel(
            router: self,
            type: type,
            meetingUseCase: MeetingCreatingUseCase(repository: MeetingCreatingRepository()),
            audioSessionUseCase: AudioSessionUseCase(audioSessionRepository:audioSessionRepository),
            callsUseCase: CallsUseCase(repository: CallsRepository()),
            localVideoUseCase: CallsLocalVideoUseCase(repository: CallsLocalVideoRepository()),
            captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
            devicePermissionUseCase: DevicePermissionCheckingProtocol.live,
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository(sdk: MEGASdkManager.sharedMEGAChatSdk()), userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance())),
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
        if #available(iOS 13.0, *) {
            nav.overrideUserInterfaceStyle = .dark
        }
        nav.modalPresentationStyle = .fullScreen
        viewControllerToPresent.present(nav, animated: true, completion: nil)
    }
    
    // MARK: - UI Actions
    func dismiss() {
        baseViewController?.dismiss(animated: false, completion: nil)
    }
    
    func openChatRoom(withChatId chatId: UInt64) {
        viewControllerToPresent?.present(MEGANavigationController(rootViewController: ChatViewController(chatId: chatId)),
                           animated: true)
    }

    func goToMeetingRoom(chatRoom: ChatRoomEntity, call: CallEntity, isVideoEnabled: Bool) {
     guard let viewControllerToPresent = viewControllerToPresent else {
            return
        }
        MeetingContainerRouter(presenter: viewControllerToPresent, chatRoom: chatRoom, call: call, isVideoEnabled: isVideoEnabled).start()
    }
    
    func showVideoPermissionError() {
        DevicePermissionsHelper.alertVideoPermission(completionHandler: nil)
    }
    
    func showAudioPermissionError() {
        DevicePermissionsHelper.alertAudioPermission(forIncomingCall: false)
    }
}
