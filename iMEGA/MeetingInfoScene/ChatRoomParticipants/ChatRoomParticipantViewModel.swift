import Combine
import MEGAAppSDKRepo
import MEGADomain
import MEGAL10n
import MEGARepo

final class ChatRoomParticipantViewModel: ObservableObject, Identifiable {
    private var chatRoomUseCase: any ChatRoomUseCaseProtocol
    private var chatRoomUserUseCase: any ChatRoomUserUseCaseProtocol
    private let router: any MeetingInfoRouting
    
    private var chatParticipantId: HandleEntity
    private var chatRoom: ChatRoomEntity
    private let chatUseCase: any ChatUseCaseProtocol
    private var subscriptions = Set<AnyCancellable>()

    @Published var name: String = ""
    @Published var chatStatus: ChatStatusEntity = .invalid
    @Published var participantPrivilege: ChatRoomParticipantPrivilege = .unknown
    @Published var showPrivilegeOptions = false

    var isMyUser: Bool
    
    let userAvatarViewModel: UserAvatarViewModel

    init(
        router: some MeetingInfoRouting,
        chatRoomUseCase: some ChatRoomUseCaseProtocol,
        chatRoomUserUseCase: some ChatRoomUserUseCaseProtocol,
        chatUseCase: some ChatUseCaseProtocol,
        chatParticipantId: MEGAHandle,
        chatRoom: ChatRoomEntity
    ) {
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.chatUseCase = chatUseCase
        self.chatParticipantId = chatParticipantId
        self.chatRoom = chatRoom
        self.isMyUser = chatParticipantId == chatUseCase.myUserHandle()
        
        self.userAvatarViewModel =  UserAvatarViewModel(
            userId: chatParticipantId,
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
        self.updateParticipantPrivilege()
        if isMyUser {
            self.requestOwnPrivilegeChange(forChat: chatRoom)
        } else {
            self.requestPrivilegeChange(forChat: chatRoom)
        }
        
        self.chatStatus = chatRoomUseCase.userStatus(forUserHandle: chatParticipantId)
        self.listeningForChatStatusUpdate()
        
        loadName()
    }
    
    private func loadName() {
        Task { @MainActor in
            guard let name = try? await chatRoomUserUseCase.userDisplayName(forPeerId: self.chatParticipantId, in: self.chatRoom) else {
                return
            }
            
            if self.isMyUser {
                self.name = String(format: "%@ (%@)", name, Strings.Localizable.me)
            } else {
                self.name = name
            }
        }
    }
    
    private func listeningForChatStatusUpdate() {
        chatUseCase
            .monitorChatStatusChange()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed status \(error)")
            }, receiveValue: { [weak self] statusForUser in
                guard let self, statusForUser.0 == self.chatParticipantId else { return }
                chatStatus = statusForUser.1
            })
            .store(in: &subscriptions)
    }
    
    private func requestOwnPrivilegeChange(forChat chatRoom: ChatRoomEntity) {
        chatRoomUseCase.ownPrivilegeChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed privilege \(error)")
            }, receiveValue: { [weak self] _ in
                guard  let self,
                       let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: chatRoom.chatId) else {
                    return
                }
                self.chatRoom = chatRoom
                self.updateParticipantPrivilege()
            })
            .store(in: &subscriptions)
    }
    
    private func requestPrivilegeChange(forChat chatRoom: ChatRoomEntity) {
        chatRoomUseCase.userPrivilegeChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed privilege \(error)")
            }, receiveValue: { [weak self] handle in
                guard self?.chatParticipantId == handle else {
                    return
                }
                self?.updateParticipantPrivilege()
            })
            .store(in: &subscriptions)
    }
    
    private func updateParticipantPrivilege() {
        if isMyUser {
            participantPrivilege = chatRoom.ownPrivilege.toChatRoomParticipantPrivilege()
        } else {
            participantPrivilege = chatRoomUseCase.peerPrivilege(forUserHandle: chatParticipantId, chatRoom: chatRoom).toChatRoomParticipantPrivilege()
        }
    }
    
    func chatParticipantTapped() {
        guard !isMyUser else { return }
        
        Task { @MainActor in
            do {
                let participantEmail = try await chatRoomUserUseCase.userEmail(forUserHandle: chatParticipantId)
                router.showParticipantDetails(email: participantEmail, userHandle: chatParticipantId, chatRoom: chatRoom) { [weak self] peerPrivilege in
                    guard let self else { return }
                    participantPrivilege = peerPrivilege
                }
            } catch {
                MEGALogError("Email for participant handle: \(chatParticipantId) not found")
            }
        }
    }
    
    func privilegeTapped() {
        guard chatRoom.ownPrivilege == .moderator, !isMyUser else {
            return
        }
        showPrivilegeOptions = true
    }
    
    func privilegeOptions() -> [ChatRoomParticipantPrivilege] {
        [.readOnly, .standard, .moderator]
    }
    
    func privilegeOptionTapped(_ privilege: ChatRoomParticipantPrivilege) {
        guard privilege != participantPrivilege else {
            return
        }
        switch privilege {
        case .unknown, .removed:
            return
        default:
            updatePrivilege(to: privilege.toChatRoomPrivilegeEntity())
        }
    }
    
    func removeParticipantTapped() {
        chatRoomUseCase.remove(fromChat: chatRoom, userId: chatParticipantId)
    }
    
    // MARK: - Private
    
    private func updatePrivilege(to privilege: ChatRoomPrivilegeEntity) {
        Task { @MainActor in
            do {
                let privilegeEntity = try await chatRoomUseCase.updateChatPrivilege(
                    chatRoom: chatRoom,
                    userHandle: chatParticipantId,
                    privilege: privilege)
                participantPrivilege = privilegeEntity.toChatRoomParticipantPrivilege()
            } catch {
                MEGALogError("Update participant privilege failed: \(error.localizedDescription)")
            }
        }
    }
}

extension ChatRoomParticipantViewModel: Equatable {
    static func == (lhs: ChatRoomParticipantViewModel, rhs: ChatRoomParticipantViewModel) -> Bool {
        lhs.chatRoom == rhs.chatRoom
    }
}
