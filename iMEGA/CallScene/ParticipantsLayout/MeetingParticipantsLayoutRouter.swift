
final class MeetingParticipantsLayoutRouter: NSObject, MeetingParticipantsLayoutRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UINavigationController?
    private weak var navigationController: UINavigationController?
    private weak var containerViewModel: MeetingContainerViewModel?
    private(set) weak var viewModel: MeetingParticipantsLayoutViewModel?
    
    private let chatRoom: ChatRoomEntity
    private let call: CallEntity

    init(presenter: UINavigationController, containerViewModel: MeetingContainerViewModel, chatRoom: ChatRoomEntity, call: CallEntity) {
        self.presenter = presenter
        self.containerViewModel = containerViewModel
        self.chatRoom = chatRoom
        self.call = call
        super.init()
    }
    
    func build() -> UIViewController {
        guard let containerViewModel = containerViewModel else { return UIViewController() }
        
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdkManager.sharedMEGASdk()),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            appGroupFilePathUseCase: MEGAAppGroupFilePathUseCase(fileManager: FileManager.default)
        )
        
        let vm = MeetingParticipantsLayoutViewModel(router: self,
                               containerViewModel: containerViewModel,
                               callsUseCase: CallsUseCase(repository: CallsRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk())),
                               captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
                               localVideoUseCase: CallLocalVideoUseCase(repository: CallLocalVideoRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk())),
                               remoteVideoUseCase: CallsRemoteVideoUseCase(repository: CallsRemoteVideoRepository(chatSdk: MEGASdkManager.sharedMEGAChatSdk())),
                               chatRoomUseCase: ChatRoomUseCase(
                                chatRoomRepo: ChatRoomRepository(sdk: MEGASdkManager.sharedMEGAChatSdk()),
                                userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance())),
                               userUseCase: UserUseCase(repo: .live),
                               userImageUseCase: userImageUseCase,
                               chatRoom: chatRoom,
                               call: call)
        
        let vc = MeetingParticipantsLayoutViewController(viewModel: vm)
        baseViewController = vc
        viewModel = vm
        return vc
    }
    
    @objc func start() {
        guard let presenter = presenter else { return }
        presenter.setViewControllers([build()], animated: true)
    }

    func dismissAndShowPasscodeIfNeeded() {
        navigationController?.dismiss(animated: true, completion: {
            if UserDefaults.standard.bool(forKey: "presentPasscodeLater") && LTHPasscodeViewController.doesPasscodeExist() {
                LTHPasscodeViewController.sharedUser()?.showLockScreenOver(UIApplication.mnz_visibleViewController().view, withAnimation: true, withLogout: false, andLogoutTitle: nil)
                UserDefaults.standard.set(false, forKey: "presentPasscodeLater")
            }
            LTHPasscodeViewController.sharedUser()?.enablePasscodeWhenApplicationEntersBackground()
        })
    }
    
    func showRenameChatAlert() {
        viewModel?.dispatch(.showRenameChatAlert)
    }
    
    func didAddFirstParticipant() {
        viewModel?.dispatch(.didAddFirstParticipant)
    }
}
