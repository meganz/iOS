import MEGADomain
import Combine

final class ChatRoomParticipantViewModel: ObservableObject, Identifiable {
    private var chatRoomUseCase: ChatRoomUseCaseProtocol
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
         chatUseCase: ChatUseCaseProtocol,
         chatParticipantId: MEGAHandle,
         chatRoom: ChatRoomEntity)
    {
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
        self.chatParticipantId = chatParticipantId
        self.chatRoom = chatRoom
        self.isMyUser = chatParticipantId == chatUseCase.myUserHandle()
        
        self.userAvatarViewModel =  UserAvatarViewModel(
            userId: chatParticipantId,
            chatId: chatRoom.chatId,
            chatRoomUseCase: chatRoomUseCase,
            userImageUseCase: UserImageUseCase(
                userImageRepo: UserImageRepository.newRepo,
                userStoreRepo: UserStoreRepository.newRepo,
                thumbnailRepo: ThumbnailRepository.newRepo,
                fileSystemRepo: FileSystemRepository.newRepo),
            chatUseCase: chatUseCase,
            userUseCase: UserUseCase(repo: .live)
        )
        
        chatRoomUseCase.userDisplayName(forPeerId: chatParticipantId, chatId: chatRoom.chatId) { result in
            switch result {
            case .success(let name):
                if self.isMyUser {
                    self.name = String(format: "%@ (%@)", name, Strings.Localizable.me)
                } else {
                    self.name = name
                }
            case .failure:
                MEGALogError("Unable to fetch user name")
            }
        }

        self.updateParticipantPrivilege()
        if isMyUser {
            self.requestOwnPrivilegeChange(forChat: chatRoom)
        } else {
            self.requestPrivilegeChange(forChat: chatRoom)
        }
        
        self.chatStatus = chatRoomUseCase.userStatus(forUserHandle: chatParticipantId).toChatStatus()
        self.listeningForChatStatusUpdate()
    }
    
    private func listeningForChatStatusUpdate() {
        chatUseCase
            .monitorChatStatusChange(forUserHandle: chatParticipantId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed status \(error)")
            }, receiveValue: { [weak self] status in
                guard let self = self else { return }
                self.chatStatus = status.toChatStatus()
            })
            .store(in: &subscriptions)
    }
    
    private func requestOwnPrivilegeChange(forChat chatRoom: ChatRoomEntity) {
        chatRoomUseCase.ownPrivilegeChanged(forChatId: chatRoom.chatId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed privilege \(error)")
            }, receiveValue: { [weak self] handle in
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
        chatRoomUseCase.userPrivilegeChanged(forChatId: chatRoom.chatId)
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
            participantPrivilege = chatRoomUseCase.peerPrivilege(forUserHandle: chatParticipantId, inChatId: chatRoom.chatId)?.toChatRoomParticipantPrivilege() ?? .unknown
        }
    }
    
    func chatParticipantTapped() {
        guard let participantEmail = chatRoomUseCase.contactEmail(forUserHandle: chatParticipantId) else {
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

