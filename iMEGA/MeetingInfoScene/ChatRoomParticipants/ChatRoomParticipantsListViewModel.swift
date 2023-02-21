import MEGADomain
import Combine

final class ChatRoomParticipantsListViewModel: ObservableObject {
    
    private let initialParticipantsLoad: Int = 4
    
    private var chatRoomUseCase: ChatRoomUseCaseProtocol
    private var chatUseCase: ChatUseCaseProtocol
    private let router: MeetingInfoRouting
    private var chatRoom: ChatRoomEntity
    private var subscriptions = Set<AnyCancellable>()

    @Published var myUserParticipant: ChatRoomParticipantViewModel
    @Published var chatRoomParticipants = [ChatRoomParticipantViewModel]()
    @Published var shouldShowAddParticipants = false
    @Published var totalParcitipantsCount = 0
    @Published var showExpandCollapseButton = true
    @Published var listExpanded = false

    init(router: MeetingInfoRouting,
         chatRoomUseCase: ChatRoomUseCaseProtocol,
         chatUseCase: ChatUseCaseProtocol,
         chatRoom: ChatRoomEntity)
    {
        self.router = router
        self.chatRoomUseCase = chatRoomUseCase
        self.chatUseCase = chatUseCase
        self.chatRoom = chatRoom
        
        self.myUserParticipant = ChatRoomParticipantViewModel(
            router: router,
            chatRoomUseCase: chatRoomUseCase,
            chatUseCase: chatUseCase,
            chatParticipantId: chatUseCase.myUserHandle(),
            chatRoom: chatRoom)
        self.updateShouldShowAddParticipants()
        self.fetchParticipants()
        self.listenToInviteChanges()
        self.listenToParticipantsUpdate()
    }
    
    func fetchParticipants() {
        totalParcitipantsCount = chatRoom.peers.count + 1
        if chatRoom.peers.count <= initialParticipantsLoad {
            showExpandCollapseButton = false
            loadAllParticipants()
        } else {
            loadInitialParticipants()
        }
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
                ChatRoomParticipantViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, chatParticipantId: $0.handle, chatRoom: chatRoom)
            }
    }
    
    private func loadInitialParticipants() {
        chatRoomParticipants =  chatRoom.peers[0..<(initialParticipantsLoad - 1)]
            .map {
                ChatRoomParticipantViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, chatParticipantId: $0.handle, chatRoom: chatRoom)
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
            chatId: chatRoom.chatId
        )
    }
    
    private func updateShouldShowAddParticipants() {
        shouldShowAddParticipants = chatRoom.ownPrivilege == .moderator || (chatRoom.isOpenInviteEnabled && !chatUseCase.isGuestAccount() && chatRoom.ownPrivilege.isUserInChat)
    }
    
    private func listenToInviteChanges() {
        chatRoomUseCase.ownPrivilegeChanged(forChatId: chatRoom.chatId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogDebug("error fetching the changed privilege \(error)")
            }, receiveValue: { [weak self] handle in
                guard  let self,
                       let chatRoom = self.chatRoomUseCase.chatRoom(forChatId: self.chatRoom.chatId)else {
                    return
                }
                self.chatRoom = chatRoom
                self.updateShouldShowAddParticipants()
            })
            .store(in: &subscriptions)
        
        chatRoomUseCase.allowNonHostToAddParticipantsValueChanged(forChatId: chatRoom.chatId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { error in
                MEGALogError("error fetching allow host to add participants with error \(error)")
            }, receiveValue: { [weak self] handle in
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
        chatRoomUseCase.participantsUpdated(forChatId: chatRoom.chatId)
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
        totalParcitipantsCount = chatRoom.peers.count + 1
        showExpandCollapseButton = initialParticipantsLoad <= totalParcitipantsCount
        
        if showExpandCollapseButton {
            loadAllParticipants()
        } else {
            if chatRoomParticipants.count > chatRoom.peers.count {
                loadInitialParticipants()
            }
        }
    }
}
