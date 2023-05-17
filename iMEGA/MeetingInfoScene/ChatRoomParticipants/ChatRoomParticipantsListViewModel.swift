import MEGADomain
import Combine

final class ChatRoomParticipantsListViewModel: ObservableObject {
    
    private let initialParticipantsLoad: Int = 4
    
    private var chatRoomUseCase: ChatRoomUseCaseProtocol
    private let chatRoomUserUseCase: ChatRoomUserUseCaseProtocol
    private var chatUseCase: ChatUseCaseProtocol
    private let accountUseCase: AccountUseCaseProtocol
    private let router: MeetingInfoRouting
    private var chatRoom: ChatRoomEntity
    private var subscriptions = Set<AnyCancellable>()

    @Published var myUserParticipant: ChatRoomParticipantViewModel
    @Published var chatRoomParticipants = [ChatRoomParticipantViewModel]()
    @Published var shouldShowAddParticipants = false
    @Published var totalParticipantsCount = 0
    @Published var showExpandCollapseButton = true
    @Published var listExpanded = false

    init(router: MeetingInfoRouting,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         chatRoomUserUseCase: ChatRoomUserUseCaseProtocol,
         chatUseCase: ChatUseCaseProtocol,
         accountUseCase: AccountUseCaseProtocol,
         chatRoom: ChatRoomEntity)
    {
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatRoomUserUseCase = chatRoomUserUseCase
        self.chatUseCase = chatUseCase
        self.accountUseCase = accountUseCase
        self.chatRoom = chatRoom
        
        self.myUserParticipant = ChatRoomParticipantViewModel(
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatRoomUserUseCase: chatRoomUserUseCase,
            chatUseCase: chatUseCase,
            chatParticipantId: chatUseCase.myUserHandle(),
            chatRoom: chatRoom)
        self.updateShouldShowAddParticipants()
        self.updateParticipants()
        self.listenToInviteChanges()
        self.listenToParticipantsUpdate()
    }
    
    func addParticipantTapped() {
        inviteParticipants()
    }
    
    func seeMoreParticipantsTapped() {
        if listExpanded {
            loadInitialParticipants()
        } else {
            loadAllParticipants()
        }
        listExpanded.toggle()
    }
    
    //MARK:- Private methods
    
    private func loadAllParticipants() {
        chatRoomParticipants = chatRoom.peers
            .map {
                ChatRoomParticipantViewModel(router: router,
                                             chatRoomUseCase: chatRoomUseCase,
                                             chatRoomUserUseCase: chatRoomUserUseCase,
                                             chatUseCase: chatUseCase,
                                             chatParticipantId: $0.handle,
                                             chatRoom: chatRoom)
            }
    }
    
    private func loadInitialParticipants() {
        let peerCount = Int(chatRoom.peerCount)
        guard peerCount > 0 else {
            chatRoomParticipants = []
            return
        }
        let endIndex = (initialParticipantsLoad - 1) < peerCount ? (initialParticipantsLoad - 1) : peerCount
        chatRoomParticipants =  chatRoom.peers[0..<endIndex]
            .map {
                ChatRoomParticipantViewModel(router: router,
                                             chatRoomUseCase: chatRoomUseCase,
                                             chatRoomUserUseCase: chatRoomUserUseCase,
                                             chatUseCase: chatUseCase,
                                             chatParticipantId: $0.handle,
                                             chatRoom: chatRoom)
            }
    }
    
    private func inviteParticipants() {
        let participantsAddingViewFactory = createParticipantsAddingViewFactory()
        
        guard participantsAddingViewFactory.hasVisibleContacts else {
            router.showNoAvailableContactsAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory)
            return
        }
                        
        guard participantsAddingViewFactory.hasNonAddedVisibleContacts(withExcludedHandles: []) else {
            router.showAllContactsAlreadyAddedAlert(withParticipantsAddingViewFactory: participantsAddingViewFactory)
            return
        }
        
        router.inviteParticipants(
            withParticipantsAddingViewFactory: participantsAddingViewFactory,
            excludeParticpantsId: []
        ) { [weak self] userHandles in
            guard let self else { return }
            userHandles.forEach { self.chatRoomUseCase.invite(toChat: self.chatRoom, userId: $0) }
        }
    }
    
    private func createParticipantsAddingViewFactory() -> ParticipantsAddingViewFactory {
        ParticipantsAddingViewFactory(
            accountUseCase: AccountUseCase(repository: AccountRepository.newRepo),
            chatRoomUseCase: chatRoomUseCase,
            chatRoom: chatRoom
        )
    }
    
    private func updateShouldShowAddParticipants() {
        shouldShowAddParticipants = chatRoom.ownPrivilege == .moderator
        || (chatRoom.isOpenInviteEnabled && !accountUseCase.isGuest && chatRoom.ownPrivilege.isUserInChat)
    }
    
    private func listenToInviteChanges() {
        chatRoomUseCase.ownPrivilegeChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed privilege \(error)")
            }, receiveValue: { [weak self] _ in
                guard  let self,
                       let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatRoom.chatId)else {
                    return
                }
                self.chatRoom = chatRoom
                self.updateShouldShowAddParticipants()
            })
            .store(in: &subscriptions)
        
        chatRoomUseCase.allowNonHostToAddParticipantsValueChanged(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching allow host to add participants with error \(error)")
            }, receiveValue: { [weak self] _ in
                guard let self,
                      let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatRoom.chatId) else {
                    return
                }
                self.chatRoom = chatRoom
                self.updateShouldShowAddParticipants()
            })
            .store(in: &subscriptions)
    }
    
    private func listenToParticipantsUpdate() {
        chatRoomUseCase.participantsUpdated(forChatRoom: chatRoom)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed privilege \(error)")
            }, receiveValue: { [weak self] handles in
                guard  let self, handles.count != self.chatRoom.peers.count, let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatRoom.chatId) else {
                    return
                }
                self.chatRoom = chatRoom
                self.updateParticipants()
            })
            .store(in: &subscriptions)
    }
    
    private func updateParticipants() {
        totalParticipantsCount = chatRoom.peers.count + 1
        showExpandCollapseButton = initialParticipantsLoad < totalParticipantsCount
        
        if showExpandCollapseButton {
            if listExpanded {
                loadAllParticipants()
            } else {
                loadInitialParticipants()
            }
        } else {
            loadAllParticipants()
        }
    }
}
