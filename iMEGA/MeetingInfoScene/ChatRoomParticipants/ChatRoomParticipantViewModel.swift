import MEGADomain
import Combine

final class ChatRoomParticipantViewModel: ObservableObject, Identifiable {
    private var chatRoomUseCase: ChatRoomUseCaseProtocol
    private var chatRoomUserUseCase: ChatRoomUserUseCaseProtocol
    private let router: MeetingInfoRouting
    
    private var chatParticipantId: HandleEntity
    private var chatRoom: ChatRoomEntity
    private let chatUseCase: ChatUseCaseProtocol
    private var subscriptions = Set<AnyCancellable>()

    @Published var name: String = ""
    @Published var chatStatus: ChatStatus = .invalid
    @Published var participantPrivilege: ChatRoomParticipantPrivilege = .unknown
    @Published var showPrivilegeOptions = false

    var isMyUser: Bool
    
    let userAvatarViewModel: UserAvatarViewModel

    init(router: MeetingInfoRouting,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: ChatRoomUserUseCaseProtocol,
         chatUseCase: ChatUseCaseProtocol,
         chatParticipantId: MEGAHandle,
         chatRoom: ChatRoomEntity)
    {
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
                fileSystemRepo: FileSystemRepository.newRepo),
            chatUseCase: chatUseCase,
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo)
        )
        self.updateParticipantPrivilege()
        if isMyUser {
            self.requestOwnPrivilegeChange(forChat: chatRoom)
        } else {
            self.requestPrivilegeChange(forChat: chatRoom)
        }
        
        self.chatStatus = chatRoomUseCase.userStatus(forUserHandle: chatParticipantId).toChatStatus()
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
                self.chatStatus = statusForUser.1.toChatStatus()
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
            participantPrivilege = chatRoomUseCase.peerPrivilege(forUserHandle: chatParticipantId, chatRoom: chatRoom)?.toChatRoomParticipantPrivilege() ?? .unknown
        }
    }
    
    func chatParticipantTapped() {
        guard let participantEmail = chatRoomUserUseCase.contactEmail(forUserHandle: chatParticipantId) else {
            return
        }
        router.showParticipantDetails(email: participantEmail, userHandle: chatParticipantId, chatRoom: chatRoom)
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
            chatRoomUseCase.updateChatPrivilege(chatRoom: chatRoom, userHandle: chatParticipantId, privilege: privilege.toChatRoomPrivilegeEntity())
        }
    }
    
    func removeParticipantTapped() {
        chatRoomUseCase.remove(fromChat: chatRoom, userId: chatParticipantId)
    }
}

extension ChatRoomParticipantViewModel: Equatable {
    static func == (lhs: ChatRoomParticipantViewModel, rhs: ChatRoomParticipantViewModel) -> Bool {
        lhs.chatRoom == rhs.chatRoom
    }
}

