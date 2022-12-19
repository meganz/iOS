import MEGADomain
import Combine

final class ChatRoomParticipantsListViewModel: ObservableObject {
    
    private let initialParticipantsLoadCount: Int = 2
    
    private var chatRoomUseCase: ChatRoomUseCaseProtocol
    private var chatUseCase: ChatUseCaseProtocol
    private let router: MeetingInfoRouting
    private var chatRoom: ChatRoomEntity
    private var subscriptions = Set<AnyCancellable>()

    @Published var myUserParticipant: ChatRoomParticipantViewModel
    @Published var chatRoomParticipants = [ChatRoomParticipantViewModel]()
    @Published var shouldShowAddParticipants = false
    @Published var totalParcitipantsCount = 0
    @Published var allParticipantsLoaded = false

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
        
        if  chatRoom.peers.count <= initialParticipantsLoadCount {
            loadAllParticipants()
        } else {
            loadInitialParticipants()
        }
    }
    
    func addParticipantTapped() {
        inviteParticipants()
    }
    
    func seeMoreParticipantsTapped() {
        loadAllParticipants()
    }
    
    //MARK:- Private methods
    
    private func loadAllParticipants() {
        chatRoomParticipants = chatRoom.peers
            .map {
                ChatRoomParticipantViewModel(router: router, chatRoomUseCase: chatRoomUseCase, chatUseCase: chatUseCase, chatParticipantId: $0.handle, chatRoom: chatRoom)
            }
        allParticipantsLoaded = true
    }
    
    private func loadInitialParticipants() {
        chatRoomParticipants =  chatRoom.peers[0...initialParticipantsLoadCount]
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
            userUseCase: UserUseCase(repo: .live),
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
                self.totalParcitipantsCount = chatRoom.peers.count + 1
                self.updateParticipants()
            })
            .store(in: &subscriptions)
    }
    
    private func updateParticipants() {
        if allParticipantsLoaded {
            loadAllParticipants()
        } else {
            if chatRoomParticipants.count > chatRoom.peers.count {
                loadInitialParticipants()
            }
        }
    }
}
