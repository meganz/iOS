import ChatRepo
import Combine
import MEGADomain
import MEGARepo
import MEGASDKRepo

final class ScheduledMeetingOccurrencesRouter: ScheduledMeetingOccurrencesRouting {
    private(set) var presenter: UINavigationController
    private let scheduledMeeting: ScheduledMeetingEntity

    init(
        presenter: UINavigationController,
        scheduledMeeting: ScheduledMeetingEntity
    ) {
        self.presenter = presenter
        self.scheduledMeeting = scheduledMeeting
    }
    
    func build() -> UIViewController {
        let chatRoomUseCase = ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo)
        
        let chatRoomUserUseCase = ChatRoomUserUseCase(
            chatRoomRepo: ChatRoomUserRepository.newRepo,
            userStoreRepo: UserStoreRepository(store: .shareInstance())
        )
        
        let userImageUseCase = UserImageUseCase(
            userImageRepo: UserImageRepository(sdk: .sharedSdk),
            userStoreRepo: UserStoreRepository(store: MEGAStore.shareInstance()),
            thumbnailRepo: ThumbnailRepository.newRepo,
            fileSystemRepo: FileSystemRepository.newRepo
        )
        
        var chatRoomAvatarViewModel: ChatRoomAvatarViewModel?
        if let chatRoom = chatRoomUseCase.chatRoom(forChatId: scheduledMeeting.chatId) {
            chatRoomAvatarViewModel = ChatRoomAvatarViewModel(
                title: chatRoom.title ?? "",
                peerHandle: .invalid,
                chatRoom: chatRoom,
                chatRoomUseCase: chatRoomUseCase,
                chatRoomUserUseCase: chatRoomUserUseCase,
                userImageUseCase: userImageUseCase,
                chatUseCase: ChatUseCase(chatRepo: ChatRepository.newRepo),
                accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
                megaHandleUseCase: MEGAHandleUseCase(repo: MEGAHandleRepository.newRepo),
                chatListItemCacheUseCase: ChatListItemCacheUseCase(repository: ChatListItemCacheRepository.newRepo)
            )
        }

        let viewModel = ScheduledMeetingOccurrencesViewModel(
            router: self,
            scheduledMeeting: scheduledMeeting,
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository(chatSDK: .sharedChatSdk)),
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
        presenter.popViewController(animated: true)
        SVProgressHUD.showSuccess(withStatus: message)
    }
    
    func edit(
        occurrence: ScheduledMeetingOccurrenceEntity
    ) -> AnyPublisher<ScheduledMeetingOccurrenceEntity, Never> {
        let viewConfiguration = ScheduleMeetingUpdateOccurrenceViewConfiguration(
            occurrence: occurrence,
            scheduledMeeting: scheduledMeeting,
            chatRoomUseCase: ChatRoomUseCase(chatRoomRepo: ChatRoomRepository.newRepo),
            chatLinkUseCase: ChatLinkUseCase(chatLinkRepository: ChatLinkRepository.newRepo),
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository.newRepo)
        )
        
        let router = ScheduleMeetingRouter(
            presenter: presenter,
            viewConfiguration: viewConfiguration,
            shareLinkRouter: ShareLinkDialogRouter(
                presenter: presenter
            )
        )
        router.start()
        return router.onOccurrenceUpdate()
    }
}
