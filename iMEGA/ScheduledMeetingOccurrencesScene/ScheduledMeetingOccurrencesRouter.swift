import Combine
import MEGAData
import MEGADomain

final class ScheduledMeetingOccurrencesRouter: ScheduledMeetingOccurrencesRouting {
    private(set) var presenter: UINavigationController
    private let scheduledMeeting: ScheduledMeetingEntity

    init(presenter: UINavigationController,
         scheduledMeeting: ScheduledMeetingEntity) {
        self.presenter = presenter
        self.scheduledMeeting = scheduledMeeting
    }
    
    func build() -> UIViewController {
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo)
        
        let chatRoomUserUseCase = ChatRoomUserUseCase(
            chatRoomRepo: ChatRoomUserRepository.newRepo,
            userStoreRepo: UserStoreRepository(store: .shareInstance())
        )
        
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: MEGASdkManager.sharedMEGASdk()),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        var chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
        if let chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) {
            chatRoomAvatarViewModel = ChatRoomAvatarViewModel(
                title: chatRoom.title ?? "",
                peerHandle: .invalid,
                chatRoomEntity: chatRoom,
                chatRoomUseCase: chatRoomUseCase,
                chatRoomUserUseCase: chatRoomUserUseCase,
                userImageUseCase: userImageUseCase,
                chatUseCase: ChatUseCase(
                    chatRepo: ChatRepository(
                        sdk: MEGASdkManager.sharedMEGASdk(),
                        chatSDK: MEGASdkManager.sharedMEGAChatSdk())
                ),
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo)
            )
        }

        let viewModel = ScheduledMeetingOccurrencesViewModel(
            router: self,
            scheduledMeeting: scheduledMeeting,
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository(chatSDK: MEGASdkManager.sharedMEGAChatSdk())),
            chatRoomUseCase: chatRoomUseCase,
            chatRoomAvatarViewModel: chatRoomAvatarViewModel
        )
        
        let viewController = ScheduledMeetingOccurrencesViewController(viewModel: viewModel)

        return viewController
    }
    
    func start() {
        presenter.pushViewController(build(), animated: true)
    }
    
    func showErrorMessage(_ message: String) {
        SVProgressHUD.showError(withStatus: message)
    }
    
    func showSuccessMessage(_ message: String) {
        SVProgressHUD.showSuccess(withStatus: message)
    }
    
    func showSuccessMessageAndDismiss(_ message: String) {
        DispatchQueue.main.async {
            self.presenter.popViewController(animated: true)
            SVProgressHUD.showSuccess(withStatus: message)
        }
    }
    
    func edit(
        occurrence: ScheduledMeetingOccurrenceEntity
    ) -> AnyPublisher<ScheduledMeetingOccurrenceEntity, Never> {
        let viewConfiguration = ScheduleMeetingUpdateOccurrenceViewConfiguration(
            occurrence: occurrence,
            scheduledMeeting: scheduledMeeting,
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.sharedRepo),
            chatLinkUseCase: ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo),
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository.newRepo)
        )
        
        let router = ScheduleMeetingRouter(
            presenter: presenter,
            viewConfiguration: viewConfiguration
        )
        router.start()
        return router.onOccurrenceUpdate()
    }
}
