import ChatRepo
import MEGADomain
import MEGAPresentation
import MEGARepo
import MEGASDKRepo

protocol MeetingParticipantsLayoutRouting: AnyObject, Routing {
    func showRenameChatAlert()
    func startCallEndCountDownTimer()
    func endCallEndCountDownTimer()
    func pinParticipantAsSpeaker(_ participant: CallParticipantEntity)
    func showNavigation()
}

final class MeetingParticipantsLayoutRouter: NSObject, MeetingParticipantsLayoutRouting {
    private weak var baseViewController: UIViewController?
    private weak var presenter: UINavigationController?
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
            userImageRepo: UserImageRepository(sdk: .sharedSdk),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        let analyticsEventUseCase = AnalyticsEventUseCase(repository: AnalyticsRepository(sdk: .sharedSdk))

        let vm = MeetingParticipantsLayoutViewModel(
            containerViewModel: containerViewModel, 
            chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
            callUseCase: CallUseCase(repository: CallRepository(chatSdk: .sharedChatSdk, callActionManager: CallActionManager.shared)),
            callSessionUseCase: CallSessionUseCase(repository: CallSessionRepository.newRepo),
            captureDeviceUseCase: CaptureDeviceUseCase(repo: CaptureDeviceRepository()),
            localVideoUseCase: CallLocalVideoUseCase(repository: CallLocalVideoRepository(chatSdk: .sharedChatSdk)),
            remoteVideoUseCase: CallRemoteVideoUseCase(repository: CallRemoteVideoRepository(chatSdk: .sharedChatSdk)),
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            chatRoomUserUseCase: ChatRoomUserUseCase(
                chatRoomRepo: ChatRoomUserRepository.newRepo,
                userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance())),
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            userImageUseCase: userImageUseCase,
            analyticsEventUseCase: analyticsEventUseCase,
            megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo),
            chatRoom: chatRoom,
            call: call
        )
        
        let vc = MeetingParticipantsLayoutViewController(viewModel: vm)
        baseViewController = vc
        viewModel = vm
        return vc
    }
    
    @objc func start() {
        guard let presenter = presenter else { return }
        presenter.setViewControllers([build()], animated: true)
    }
    
    func showRenameChatAlert() {
        viewModel?.dispatch(.showRenameChatAlert)
    }
    
    func startCallEndCountDownTimer() {
        viewModel?.dispatch(.startCallEndCountDownTimer)
    }
    
    func endCallEndCountDownTimer() {
        viewModel?.dispatch(.endCallEndCountDownTimer)
    }
    
    func pinParticipantAsSpeaker(_ participant: CallParticipantEntity) {
        viewModel?.dispatch(.pinParticipantAsSpeaker(participant))
    }
    
    func showNavigation() {
        viewModel?.dispatch(.showNavigation)
    }
}
