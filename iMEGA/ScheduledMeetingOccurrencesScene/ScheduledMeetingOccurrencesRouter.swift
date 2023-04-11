import MEGADomain
import MEGAData

final class ScheduledMeetingOccurrencesRouter: NSObject {
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
            scheduledMeeting: scheduledMeeting,
            scheduledMeetingUseCase: ScheduledMeetingUseCase(repository: ScheduledMeetingRepository(chatSDK: MEGASdkManager.sharedMEGAChatSdk())),
            chatRoomAvatarViewModel: chatRoomAvatarViewModel
        )
        
        let viewController = ScheduledMeetingOccurrencesViewController(viewModel: viewModel)

        return viewController
    }
    
    func start() {
        presenter.pushViewController(build(), animated: true)
    }
}
