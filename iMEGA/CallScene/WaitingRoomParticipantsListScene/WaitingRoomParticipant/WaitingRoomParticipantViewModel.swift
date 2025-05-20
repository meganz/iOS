import MEGAAppSDKRepo
import MEGADomain
import MEGARepo

final class WaitingRoomParticipantViewModel: ObservableObject, Identifiable {
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    private var chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private let chatUseCase: any ChatUseCaseProtocol
    private let callUseCase: any CallUseCaseProtocol
    private var waitingRoomParticipantId: HandleEntity
    private var chatRoom: ChatRoomEntity
    private var call: CallEntity
    let userAvatarViewModel: UserAvatarViewModel
    
    @Published var name: String = ""
    @Published var showConfirmDenyAlert = false
    @Published var admitButtonDisabled: Bool

    init(
        chatRoomUseCase: any ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol,
        chatUseCase: any ChatUseCaseProtocol,
        callUseCase: some CallUseCaseProtocol,
        waitingRoomParticipantId: MEGAHandle,
        chatRoom: ChatRoomEntity,
        call: CallEntity,
        admitButtonDisabled: Bool
    ) {
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.chatUseCase = chatUseCase
        self.callUseCase = callUseCase
        self.waitingRoomParticipantId = waitingRoomParticipantId
        self.chatRoom = chatRoom
        self.call = call
        self.admitButtonDisabled = admitButtonDisabled
        
        self.userAvatarViewModel =  UserAvatarViewModel(
            userId: waitingRoomParticipantId,
            chatId: chatRoom.chatId,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            userImageUseCase: UserImageUseCase(
                userImageRepo: UserImageRepository.newRepo,
                userStoreRepo: UserStoreRepository.newRepo,
                thumbnailRepo: ThumbnailRepository.newRepo,
                fileSystemRepo: FileSystemRepository.sharedRepo),
            chatUseCase: chatUseCase,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
        )
        
        loadName()
    }
    
    private func loadName() {
        Task { @MainActor in
            guard let name = try? await chatRoomUserUseCase.userDisplayName(forPeerId: self.waitingRoomParticipantId, in: self.chatRoom) else {
                return
            }
            self.name = name
        }
    }
    
    func admitTapped() {
        callUseCase.allowUsersJoinCall(call, users: [waitingRoomParticipantId])
    }
    
    func denyTapped() {
        showConfirmDenyAlert = true
    }
    
    func confirmDenyTapped() {
        callUseCase.kickUsersFromCall(call, users: [waitingRoomParticipantId])
    }
}
